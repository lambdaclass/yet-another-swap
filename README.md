# Fractal-Swap

Fractal Swap is a Uniswap V3 implementation on StarkNet.

## Setting up a Testnet Smart Wallet

**This is a guide for declaring and deploying contracts on a testnet. You won't be able to use the commands in the Makefile unless you follow it.**

A smart wallet consists of two parts: a Signer and an Account Descriptor. The Signer is a smart contract capable of signing transactions (we need its private key). The Account Descriptor is a JSON file containing information about the smart wallet, such as its address and public key.

Follow the steps below to set up a testnet smart wallet:

1. Create a Smart wallet on Goerli Testnet. This can be done using Argent X or Braavos Wallet.

2. Fund the newly created account using the Goerli Testnet Faucet: [https://faucet.goerli.starknet.io](https://faucet.goerli.starknet.io).

3. **Signer Creation:**
    1. Retrieve the private key of the account. Each wallet provides a specific path to achieve this:
        - For Braavos:
            Navigate to the "Settings" section → "Privacy and Security" → "Export Private Key".
        - For Argent X:
            Go to the "Settings" section → Select your Account → "Export Private Key".
    2. Create a folder using the following command:
        ```bash
        mkdir -p ~/.starkli-wallets/deployer
        ```
    3. Run the `starkli` command to store the private key encrypted:
        ```bash
        starkli signer keystore from-key ~/.starkli-wallets/deployer/keystore.json
        ```

4. **Account Descriptor:**
    1. Create a file for the descriptor:
        ```bash
        touch ~/.starkli-wallets/deployer/account.json
        ```
    2. The account descriptor should have the following structure:
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
    3. **Public Key**: This was returned in step 3.3 by the starkli signer, you can also find it with this command:
        ```bash
        starkli signer keystore inspect ~/.starkli-wallets/deployer/keystore.json
        ```
    4. **Address**: The address is the address of your smart wallet. 
    5. **Class-hash**: This is related to the type of wallet. You can fetch it using the following command: 
        ```bash
        starkli class-hash-at <SMART_WALLET_ADDRESS>
        ```
5. **Setting Up Enviromnet Variables**
    There are two primary environment variables that are vital for effective usage of Starkli’s CLI. These are the location of the keystore file for the Signer, and the location of the Account Descriptor file:
    ```bash
    export STARKNET_ACCOUNT=~/.starkli-wallets/deployer/account.json
    export STARKNET_KEYSTORE=~/.starkli-wallets/deployer/keystore.json
    ```


