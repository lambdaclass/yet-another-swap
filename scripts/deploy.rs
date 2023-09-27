use std::sync::Arc;
use std::{env, fs};

use dotenv::dotenv;
use eyre::Result;
use starknet::accounts::{Account, ConnectedAccount, ExecutionEncoding, SingleOwnerAccount};
use starknet::contract::ContractFactory;
use starknet::core::types::contract::SierraClass;
use starknet::core::types::{BlockId, BlockTag, FieldElement, StarknetError};
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
        println!("==> Declaring Contract: {contract_name}");
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
    let pool_class_hash = declare_contract(&account, "YASPool").await?;
    let factory_class_hash = declare_contract(&account, "YASFactory").await?;

    // Instantiate the contract factory.
    let salt = account.get_nonce().await?;
    let contract_factory = ContractFactory::new(factory_class_hash, account);
    let owner_address = FieldElement::from_hex_be(&env::var("OWNER_ADDRESS").expect("OWNER_ADDRESS not set"))
        .expect("Invalid Owner Address");
    let unique = true;
    println!(
        "==> Deploying Factory Contract\nOWNER_ADDRESS: {:#064x}\nPOOL_CLASS_HASH: {:#064x}\nSALT: {}\nUNIQUE: {}",
        owner_address, pool_class_hash, salt, unique
    );

    let contract_deployment = contract_factory.deploy(vec![owner_address, pool_class_hash], salt, unique);
    let deployed_address = contract_deployment.deployed_address();
    println!("Contract Address: {}", format!("{:#064x}", deployed_address));

    // Estimate the deployment fee and deploy the contract.
    let estimated_fee = contract_deployment.estimate_fee().await?.overall_fee * 3 / 2; // add buffer
    let tx = contract_deployment.max_fee(estimated_fee.into()).send().await?.transaction_hash;
    println!("Transaction Hash: {}", format!("{:#064x}", tx));

    Ok(())
}
