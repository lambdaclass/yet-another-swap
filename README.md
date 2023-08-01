# Fractal-Swap

Fractal Swap is a Uniswap V3 implementation on StarkNet.

## Install dependencies
Run the following command:

```bash
make deps
```
This will end up installing:
- [Scarb](https://docs.swmansion.com/scarb) (Cairo/Starknet packet manager)
  - Includes a specific version of the Cairo compiler.
- [Starkli](https://github.com/xJonathanLEI/starkli) (Starknet CLI)


## Build Project
Run the following command:

```bash
make build   
```

This command executes the Scrab build process, resulting in the creation of a Sierra program.
    
## Setting up a Testnet Smart Wallet

**This guide will help you declare and deploy contracts on a testnet. Please note that you won't be able to use the commands in the Makefile unless you follow these instructions.**

A smart wallet consists of two parts: a Signer and an Account Descriptor. The Signer is a smart contract capable of signing transactions (for which we need its private key). The Account Descriptor is a JSON file containing information about the smart wallet, such as its address and public key.

Follow the steps below to set up a testnet smart wallet:

1. **Create a Smart Wallet**: You can do this on the Goerli Testnet using Argent X or Braavos Wallet.

2. **Funding**: Fund the newly created account using the Goerli Testnet Faucet: [https://faucet.goerli.starknet.io](https://faucet.goerli.starknet.io).

3. **Signer Creation:**
    1. **Retrieve the Private Key**: Each wallet provides a specific path to do this:
        - For Braavos:
            Navigate to the "Settings" section → "Privacy and Security" → "Export Private Key".
        - For Argent X:
            Go to the "Settings" section → Select your Account → "Export Private Key".
    2. **Create a Folder**: Use the following command:
        ```bash
        mkdir -p ~/.starkli-wallets/deployer
        ```
    3. **Store the Private Key**: Run the `starkli` command to store the private key encrypted:
        ```bash
        starkli signer keystore from-key ~/.starkli-wallets/deployer/keystore.json
        ```

4. **Account Descriptor:**
    1. **Create a File**: For the descriptor:
        ```bash
        touch ~/.starkli-wallets/deployer/account.json
        ```
    2. **Define the Structure**: The account descriptor should look like this:
        ```json
        {
            "version": 1,
            "variant": {
                "type": "open_zeppelin",
                "version": 1,
                "public_key": "<SMART_WALLET_PUBLIC_KEY>"
            },
            "deployment": {
                "status": "deployed",
                "class_hash": "<SMART_WALLET_CLASS_HASH>",
                "address": "<SMART_WALLET_ADDRESS>"
            }
        }        
        ```
    3. **Public Key**: This was returned in step 3.3 by the `starkli` signer. You can also find it with this command:
        ```bash
        starkli signer keystore inspect ~/.starkli-wallets/deployer/keystore.json
        ```
    4. **Address**: This is the address of your smart wallet. 
    5. **Class-hash**: This is related to the type of wallet. Retrieve it using the following command: 
        ```bash
        starkli class-hash-at <SMART_WALLET_ADDRESS>
        ```

5. **Setting Up Environment Variables**: There are two primary environment variables vital for effective usage of Starkli’s CLI. These are the location of the keystore file for the Signer, and the location of the Account Descriptor file:
    ```bash
    export STARKNET_ACCOUNT=~/.starkli-wallets/deployer/account.json
    export STARKNET_KEYSTORE=~/.starkli-wallets/deployer/keystore.json
    ```

## Declare and Deploy Contracts

By following the previous two steps, you should now have a compiled program and an account funded on the Goerli testnet.

Now we have to deploy the contract to the Testnet.

On Starknet, the deployment process is in two steps:

- Declaring the class of your contract, or sending your contract’s code to the network
- Deploying a contract, or creating an instance of the code you previously declared

1. Declare:
    ```bash
    starkli declare target/dev/contracts_Ownable.sierra.json --account $STARKNET_ACCOUNT --network=goerli-1 --compiler-version=2.0.1
    ```
2. Deploy:
    ```bash
    starkli deploy <CLASS_HASH> <CONSTRUCTOR_INPUTS> --network=goerli-1
    ```
## Tooling
- [Starkli](https://book.starkli.rs/)
- [Scarb](https://book.starknet.io/chapter_2/scarb.html)
- [Starknet Foundry](https://foundry-rs.github.io/starknet-foundry/)

## Useful resources
- [Cairo Book](https://book.cairo-lang.org/)
- [Cairo by example](https://cairo-by-example.com/)
- [Starknet Book](https://book.starknet.io/index.html)
- [Uniswap Protocol](https://docs.uniswap.org/concepts/uniswap-protocol)
- [Uniswap V3](https://uniswapv3book.com/docs/introduction/uniswap-v3/)
- [UNISWAP V3 - New Era Of AMMs? Architecture Explained](https://www.youtube.com/watch?v=Ehm-OYBmlPM)
- [ZK Podcast: Exploring Uniswap V3 and a Multi-L2 Future with Noah and Moody](https://zeroknowledge.fm/185-2/)
