# Fractal-Swap

Fractal Swap is a Uniswap V3 implementation on StarkNet.

## Important Disclaimer
This is the Development branch. Currently we are using Scarb 0.6.0-alpha.4 which is not compatible with the latest `starkli` release. Therefore, the project can not be deployed. This decision was made to include `signed integers` that were introduced in the latest corelib update in Cairo.

The following commands will not work in this branch:
- `make declare`
- `make deploy`

The main branch should always include contracts that can be deployed to Starknet.

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

Follow the steps below to set up a testnet smart wallet using `starkli`:

1. **Connect to a Provider**: to interact with the network you need an RPC Provider. For our project we will be using Alchemy's free tier in Goerli Testnet.
   1. Go to [Alchemy website](https://www.alchemy.com/) and create an account.
   2. It will ask which network you want to develop on and choose Starknet.
   3. Select the Free version of the service (we will only need access to send some transactions to deploy the contracts)
   4. Once the account creation process is done, go to *My apps* and create a new Application. Choose Starknet as a Chain and Goerli Starknet as a Network.
   5. Click on *View key* on the new Starknet Application and copy the HTTPS url.
   6. On your terminal run:
        ```bash
        export STARKNET_RPC="<ALCHEMY_API_HTTPS_URL>"
        ```

2. **Create a Keystore**: A Keystore is a encrypted `json` file that stores the private keys.
   1. **Create a hidden folder**: Use the following command:
        ```bash
        mkdir -p ~/.starkli-wallets
        ```
   2. **Generate a new Keystore file**: Run the following command to create a new private key stored in the file. It will **ask for a password** to encrypt the file:
        ```bash
        starkli signer keystore new ~/.starkli-wallets/keystore.json
        ```
        The command will return the Public Key of your account, copy it to your clipboard to fund the account.
    
   3. **Set STARKNET_ACCOUNT**: To set the environment variable just run:
        ```bash
        export STARKNET_KEYSTORE="~/.starkli-wallets/keystore.json"
        ```

3. **Account Creation**: In Starknet every account is a smart contract, so to create one it will need to be deployed.
   1. **Initiate the account with the Open Zeppelin Account contract**:
        ```bash
        starkli account oz init --keystore ~/.starkli-wallets/keystore.json ~/.starkli-wallets/account.json
        ```
   2. **Deploy the account by running**:
        ```bash
        starkli account deploy --keystore ~/.starkli-wallets/keystore.json ~/.starkli-wallets/account.json
        ```
        For the deployment `starkli` will ask you to fund an account. To do so you will need to fund  the address given by `starkli` with the [Goerli Starknet Faucet](https://faucet.goerli.starknet.io)

4. **Setting Up Environment Variables**: There are two primary environment variables vital for effective usage of Starkli’s CLI. These are the location of the keystore file for the Signer, and the location of the Account Descriptor file:
    ```bash
    export STARKNET_ACCOUNT=~/.starkli-wallets/deployer/account.json
    export STARKNET_KEYSTORE=~/.starkli-wallets/deployer/keystore.json
    ```

## Declare and Deploy Contracts

By following the previous two steps, you should now have a account funded on the Goerli testnet.

Now we have to deploy the simple AMM contract to the Testnet.

On Starknet, the deployment process is in two steps:

- Declaring the class of your contract, or sending your contract’s code to the network
- Deploying a contract, or creating an instance of the code you previously declared

1. Build the project:
    ```bash
    make build
    ```
2. Declare:
    ```bash
    make declare
    ```
    Copy the declare Class Hash provided to use in the following step.
3. Deploy:
   ```bash
   make deploy CLASS_HASH="<CLASS_HASH>"
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
