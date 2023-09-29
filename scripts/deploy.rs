use std::sync::Arc;
use std::{env, fs};

use dotenv::dotenv;
use eyre::Result;
use starknet::accounts::{Account, Call, ConnectedAccount, ExecutionEncoding, SingleOwnerAccount};
use starknet::contract::ContractFactory;
use starknet::core::types::contract::SierraClass;
use starknet::core::utils::get_selector_from_name;
use starknet::core::types::{BlockId, BlockTag, FieldElement, FunctionCall, StarknetError};
use starknet::providers::jsonrpc::{HttpTransport, JsonRpcClient};
use starknet::providers::{MaybeUnknownErrorCode, Provider, ProviderError, StarknetErrorWithMessage};
use starknet::signers::{LocalWallet, SigningKey};

const BUILD_PATH_PREFIX: &str = "target/dev/yas_";
// TODO: Update to New once account contracts are migrated to v1
const ENCODING: ExecutionEncoding = ExecutionEncoding::Legacy;

/// Create a StarkNet provider.
/// If the `STARKNET_RPC` environment variable is set, it will be used as the RPC URL.
/// Otherwise, the default URL will be used.
fn jsonrpc_client() -> JsonRpcClient<HttpTransport> {
    let rpc_url = env::var("STARKNET_RPC").unwrap_or("https://rpc-goerli-1.starknet.rs/rpc/v0.4".into());
    JsonRpcClient::new(HttpTransport::new(url::Url::parse(&rpc_url).unwrap()))
}

/// Get the contract artifact from the build directory.
/// # Arguments
/// * `path` - The path to the contract artifact.
/// # Returns
/// The contract artifact.
fn contract_artifact(contract_name: &str) -> Result<SierraClass> {
    let artifact_path = format!("{BUILD_PATH_PREFIX}{contract_name}.sierra.json");
    let file = fs::File::open(artifact_path)
        .unwrap_or_else(|_| panic!("Compiled contract {} not found: run `make build`", contract_name));
    serde_json::from_reader(file).map_err(Into::into)
}

/// Fetch the private key from the `PRIVATE_KEY` environment variable or prompt the user for input.
/// # Returns
/// The private key.
fn private_key_from_env_or_input() -> FieldElement {
    if let Ok(pk) = env::var("PRIVATE_KEY") {
        FieldElement::from_hex_be(&pk).expect("Invalid Private Key")
    } else {
        let input_key = rpassword::prompt_password("Enter private key: ").unwrap();
        FieldElement::from_hex_be(&input_key).expect("Invalid Private Key")
    }
}

/// Initialize a StarkNet account.
/// # Arguments
/// * `signer` - The StarkNet signer.
/// * `account_address` - The StarkNet account address.
/// # Returns
/// The StarkNet account.
async fn initialize_starknet_account(
    signer: LocalWallet,
    account_address: FieldElement,
) -> Result<SingleOwnerAccount<JsonRpcClient<HttpTransport>, LocalWallet>> {
    let provider = jsonrpc_client();
    let chain_id = provider.chain_id().await?;
    let mut account = SingleOwnerAccount::new(provider, signer, account_address, chain_id, ENCODING);
    account.set_block_id(BlockId::Tag(BlockTag::Pending));
    Ok(account)
}

/// Check if a contract class is already declared.
/// # Arguments
/// * `provider` - The StarkNet provider.
/// * `class_hash` - The contract class hash.
/// # Returns
/// `true` if the contract class is already declared, `false` otherwise.
async fn is_already_declared<P>(provider: &P, class_hash: &FieldElement) -> Result<bool>
where
    P: Provider,
    P::Error: 'static,
{
    match provider.get_class(BlockId::Tag(BlockTag::Pending), class_hash).await {
        Ok(_) => {
            eprintln!("Not declaring class as it's already declared. Class hash:");
            println!("{}", format!("{:#064x}", class_hash));

            Ok(true)
        }
        Err(ProviderError::StarknetError(StarknetErrorWithMessage {
            code: MaybeUnknownErrorCode::Known(StarknetError::ClassHashNotFound),
            ..
        })) => Ok(false),
        Err(err) => Err(err.into()),
    }
}

/// Declare a contract class. If the contract class is already declared, do nothing.
/// # Arguments
/// * `account` - The StarkNet account.
/// * `contract_name` - The contract name.
/// # Returns
/// The contract class hash.
async fn declare_contract(
    account: &SingleOwnerAccount<JsonRpcClient<HttpTransport>, LocalWallet>,
    contract_name: &str,
) -> Result<FieldElement> {
    // Load the contract artifact.
    let contract_artifact = contract_artifact(contract_name)?;

    // Compute the contract class hash.
    let class_hash = contract_artifact.class_hash()?;

    // Declare the contract class if it is not already declared.
    if !is_already_declared(account.provider(), &class_hash).await? {
        println!("\n==> Declaring Contract: {contract_name}");
        let flattened_class = contract_artifact.flatten()?;
        account.declare(Arc::new(flattened_class), class_hash).send().await?;
        println!("Declared Class Hash: {}", format!("{:#064x}", class_hash));
    };

    Ok(class_hash)
}

#[tokio::main]
async fn main() -> Result<()> {
    dotenv().ok();

    // Create signer from private key.
    let private_key = private_key_from_env_or_input();
    let signer = LocalWallet::from(SigningKey::from_secret_scalar(private_key));

    // Create a StarkNet account.
    let account_address = FieldElement::from_hex_be(&env::var("ACCOUNT_ADDRESS").expect("ACCOUNT_ADDRESS not set"))
        .expect("Invalid Account Address");
    let account = initialize_starknet_account(signer, account_address).await?;

    // Declare the contract classes if they are not already declared.
    let erc20_class_hash = declare_contract(&account, "ERC20").await?;
    let factory_class_hash = declare_contract(&account, "YASFactory").await?;
    let pool_class_hash = declare_contract(&account, "YASPool").await?;
    let router_class_hash = declare_contract(&account, "YASRouter").await?;

    let unique = true;
    let owner_address = FieldElement::from_hex_be(&env::var("OWNER_ADDRESS").expect("OWNER_ADDRESS not set"))
        .expect("Invalid Owner Address");
    
    let (token_0, token_1) = deploy_erc20(owner_address, &account, erc20_class_hash).await?;

    // Instantiate the contract factory.
    let salt = account.get_nonce().await?;
    let yas_factory_contract_factory = ContractFactory::new(factory_class_hash, &account);
    println!("\n==> Deploying Factory Contract");
    let contract_deployment = yas_factory_contract_factory.deploy(vec![owner_address, pool_class_hash], salt, unique);
    let factory_address = contract_deployment.deployed_address();
    println!("Factory Contract Address: {}", format!("{:#064x}", factory_address));

    // Estimate the deployment fee and deploy the contract.
    let estimated_fee = contract_deployment.estimate_fee().await?.overall_fee * 3 / 2; // add buffer
    let tx = contract_deployment.max_fee(estimated_fee.into()).send().await?.transaction_hash;
    println!("Transaction Hash: {}", format!("{:#064x}", tx));

    // Instantiate the contract factory.
    let salt = account.get_nonce().await?;
    let yas_router_contract_factory = ContractFactory::new(router_class_hash, &account);
    println!("\n==> Deploying Router Contract");
    let contract_deployment = yas_router_contract_factory.deploy(vec![], salt, unique);
    let router_address = contract_deployment.deployed_address();
    println!("Router Contract Address: {}", format!("{:#064x}", router_address));

    // Estimate the deployment fee and deploy the contract.
    let estimated_fee = contract_deployment.estimate_fee().await?.overall_fee * 3 / 2; // add buffer
    let tx = contract_deployment.max_fee(estimated_fee.into()).send().await?.transaction_hash;
    println!("Transaction Hash: {}", format!("{:#064x}", tx));

    // println!("\n==> Approve");
    // account
    //     .execute(vec![Call {
    //         to: token_0,
    //         selector: get_selector_from_name("approve").unwrap(),
    //         calldata: vec![
    //             router_address,
    //             owner_address,
    //             FieldElement::ZERO,
    //             FieldElement::from(500_u32),
    //         ],
    //     }])
    //     .send()
    //     .await
    //     .unwrap();

    // jsonrpc_client()
    //     .call(
    //         FunctionCall {
    //             contract_address: token_0,
    //             entry_point_selector: get_selector_from_name("approve").unwrap(),
    //             calldata: vec![
    //                 router_address,
    //                 owner_address,
    //                 FieldElement::from_dec_str("1000000000000000000000").unwrap(),
    //                 FieldElement::ZERO,
    //             ],
    //         },
    //         BlockId::Tag(BlockTag::Latest),
    //     )
    //     .await
    //     .expect("Error calling contract");

    // account
    //     .execute(vec![Call {
    //         to: token_1,
    //         selector: get_selector_from_name("approve").unwrap(),
    //         calldata: vec![
    //             router_address,
    //             owner_address,
    //             FieldElement::from(0_u32),
    //             FieldElement::from(999999_u32),
    //         ],
    //     }])
    //     .send()
    //     .await
    //     .unwrap();
    //
    // jsonrpc_client()
    //     .call(
    //         FunctionCall {
    //             contract_address: token_1,
    //             entry_point_selector: get_selector_from_name("create_pool").unwrap(),
    //             calldata: vec![
    //                 router_address,
    //                 owner_address,
    //                 FieldElement::from(0_u32),
    //                 FieldElement::from(999999_u32),
    //             ],
    //         },
    //         BlockId::Tag(BlockTag::Latest),
    //     )
    //     .await
    //     .expect("Error calling contract");

    println!("\n==> Creating Pool TYAS0 & TYAS1");
    let invoke_result = account
        .execute(vec![Call {
            to: factory_address,
            selector: get_selector_from_name("create_pool").unwrap(),
            calldata: vec![
                token_0,
                token_1,
                FieldElement::from(500_u32),
            ],
        }])
        .send()
        .await
        .unwrap();

    let create_pool_result = jsonrpc_client()
        .call(
            FunctionCall {
                contract_address: factory_address,
                entry_point_selector: get_selector_from_name("create_pool").unwrap(),
                calldata: vec![
                    token_0,
                    token_1,
                    FieldElement::from(500_u32),
                ],
            },
            BlockId::Tag(BlockTag::Latest),
        )
        .await
        .expect("Error calling contract");

    println!("Pool created by Factory: {:#064x}", create_pool_result[0]);
    println!("Transaction Hash: {}", format!("{:#064x}", invoke_result.transaction_hash));

    println!("\n==> Initialize Pool");
    let invoke_result = account
        .execute(vec![Call {
            to: create_pool_result[0],
            selector: get_selector_from_name("initialize").unwrap(),
            calldata: vec![
                FieldElement::from(25054144837504793118641380156_u128), //encode_price_sqrt_1_10
                FieldElement::from(0_u128),
                FieldElement::from(0_u128)
            ],
        }])
        .send()
        .await?;

    jsonrpc_client()
        .call(
            FunctionCall {
                contract_address: create_pool_result[0],
                entry_point_selector: get_selector_from_name("initialize").unwrap(),
                calldata: vec![
                    FieldElement::from(25054144837504793118641380156_u128), //encode_price_sqrt_1_10
                    FieldElement::from(0_u128),
                    FieldElement::from(0_u128)
                ],
            },
            BlockId::Tag(BlockTag::Latest),
        )
        .await
        .expect("Error calling contract");

    println!("Transaction Hash: {}", format!("{:#064x}", invoke_result.transaction_hash));

    println!("\n==> Mint()");
    let mint_result = account
        .execute(vec![Call {
            to: router_address,
            selector: get_selector_from_name("mint").unwrap(),
            calldata: vec![
                create_pool_result[0],
                owner_address,
                FieldElement::from(887220_u64),
                FieldElement::from(1_u64),
                FieldElement::from(887220_u64),
                FieldElement::from(0_u64),
                FieldElement::from(3161_u128),
            ],
        }])
        .send()
        .await?;
    println!("Transaction Hash: {}", format!("{:#064x}", mint_result.transaction_hash));

    let old_balance = jsonrpc_client()
        .call(
            FunctionCall {
                contract_address: token_0,
                entry_point_selector: get_selector_from_name("balanceOf").unwrap(),
                calldata: vec![
                    owner_address
                ],
            },
            BlockId::Tag(BlockTag::Latest),
        )
        .await
        .expect("Error calling contract");

    println!("\n==> Swap()");
    let swap_result = account
        .execute(vec![Call {
            to: router_address,
            selector: get_selector_from_name("swap_exact_0_for_1").unwrap(),
            calldata: vec![
                create_pool_result[0],
                FieldElement::from(1_u64),
                FieldElement::ZERO,
                owner_address,
                FieldElement::from(1000000000000000000_u128), //encode_price_sqrt_1_10
                FieldElement::ZERO,
                FieldElement::ZERO
            ],
        }])
        .send()
        .await?;
    println!("Transaction Hash: {}", format!("{:#064x}", swap_result.transaction_hash));

    println!("\n==> balanceOf()");
    let balance_result = jsonrpc_client()
        .call(
            FunctionCall {
                contract_address: token_0,
                entry_point_selector: get_selector_from_name("balanceOf").unwrap(),
                calldata: vec![
                    owner_address
                ],
            },
            BlockId::Tag(BlockTag::Latest),
        )
        .await
        .expect("Error calling contract");

    println!("Old user balance: {}", format!("{:#064x}", old_balance[1]));
    println!("New user balance: {}", format!("{:#064x}", balance_result[1]));

    Ok(())
}

/// Deploy ERC20 Contract.
///
/// # Arguments
///
/// * `name` - The name of the ERC20 token.
/// * `symbol` - The symbol of the ERC20 token.
/// * `total_supply` - The total supply of the ERC20 token.
/// * `recipient` - The initial recipient of the total supply.
///
/// # Returns
///
/// This function returns a `Result` indicating success or an error.
async fn deploy_erc20(
    recipient: FieldElement,
    account: &SingleOwnerAccount<JsonRpcClient<HttpTransport>, LocalWallet>,
    erc20_class_hash: FieldElement
) -> Result<(FieldElement, FieldElement)> {
   // Instantiate the contract factory.
    let erc20_factory = ContractFactory::new(erc20_class_hash, account);
    println!(
        "\n==> Deploying ERC20 Contracts",
    );
    let unique = true;
    let salt = account.get_nonce().await?;
    let erc20_token_0_contract_deployment = erc20_factory.deploy(vec![FieldElement::from_hex_be("0x5459415330").unwrap(), FieldElement::from_hex_be("0x2459415330").unwrap(), FieldElement::from(0_u32), FieldElement::from_hex_be("0x3b9ac9ff").unwrap(), recipient], salt, unique);
    let erc20_token_0_deployed_address = erc20_token_0_contract_deployment.deployed_address();
    println!("Token TYAS0 Address: {}", format!("{:#064x}", erc20_token_0_deployed_address));
    let estimated_fee = erc20_token_0_contract_deployment.estimate_fee().await?.overall_fee * 3 / 2;
    erc20_token_0_contract_deployment.max_fee(estimated_fee.into()).send().await?.transaction_hash;

    let erc20_token_1_contract_deployment = erc20_factory.deploy(vec![FieldElement::from_hex_be("0x5459415331").unwrap(), FieldElement::from_hex_be("0x2459415331").unwrap(), FieldElement::from(0_u32), FieldElement::from_hex_be("0x3b9ac9ff").unwrap(), recipient], salt, unique);
    let erc20_token_1_deployed_address = erc20_token_1_contract_deployment.deployed_address();
    println!("Token TYAS1 Address: {}", format!("{:#064x}", erc20_token_1_deployed_address));
    let estimated_fee = erc20_token_1_contract_deployment.estimate_fee().await?.overall_fee * 3 / 2;
    erc20_token_1_contract_deployment.max_fee(estimated_fee.into()).send().await?.transaction_hash;

    Ok((erc20_token_0_deployed_address, erc20_token_1_deployed_address))
}