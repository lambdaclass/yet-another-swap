<div align="center">
<img src="./yas.png" height="150">
</div>

# YAS - Yet Another Swap

YAS is Yet Another Swap on Starknet 😝. It's an AMM based on Uniswap v3 that
will add some new features to the Starknet ecosystem.

- Provide a more capital efficient liquidity layer
- Based on a robust and battle-tested protocol. LPs from Uniswap v3 will feel
  right at home.
- Provide the best prices for aggregators and traders.

At YAS we believe product quality should always be a priority so we are commited
to provide the best experience for users that want to put Starknet to the limit.

This project will be built in the open, **_it's still in development_**. We love
the Starknet developer ecosystem and we know that a lot of smart and hungry
developers would like to collaborate in the future of Starknet. If that's your
case you are more than welcome to join us!

**_Follow us on [Twitter](https://twitter.com/yetanotherswap)_**

## Important Disclaimer

Currently, **the project is in a development stage, it has not been audited yet
and is not ready for production**. We are also using our
[fork](https://github.com/dpinones/orion) of
[Orion](https://github.com/gizatechxyz/orion/tree/main/src/numbers/signed_integer)
`signed integer` implementation until all features are implemented and supported
in the latest version of Cairo.

> Note: In our Orion fork, we've added the capability for signed integers to be
> stored in a smart contract.

## Requirements

### Rust and Cargo

Visit the [rustup](https://rustup.rs/) website and follow the instructions on the page or run the following command in the terminal:

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

Check the version;

```bash
rustc --version
cargo --version
```

### Starkli

[Starkli](https://github.com/xJonathanLEI/starkli) is CLI tool for Starknet. For install;

```bash
curl https://get.starkli.sh | sh
```

Update `starkli` simply by running;

```bash
starkliup
```

## Install dependencies

Run the following command:

```bash
make deps
```

This will end up installing:

- [Scarb](https://docs.swmansion.com/scarb) (Cairo/Starknet packet manager) -
  Includes a specific version of the Cairo compiler.
- [Starkli](https://github.com/xJonathanLEI/starkli) (Starknet CLI)

## Build Project

Run the following command:

```bash
make build
```

This command executes the Scarb build process, resulting in the creation of a
Sierra program.

## Test Project

Run the following command to run all tests:

```bash
make test
```

You can also filter the tests to run, by module or even by individual test name, for example to run tests within the Mint module, execute:

```bash
make test Mint
```

Or to run only the "test_invalid_max_tick" function:

```bash
make test test_invalid_max_tick
```

Be careful though, this parameters is case-sensitive

## Setting up a Testnet Smart Wallet

**This guide will help you declare and deploy contracts on a testnet. Please
note that you won't be able to use the commands in the Makefile unless you
follow these instructions.**

A smart wallet consists of two parts: a Signer and an Account Descriptor. The
Signer is a smart contract capable of signing transactions (for which we need
its private key). The Account Descriptor is a JSON file containing information
about the smart wallet, such as its address and public key.

Follow the steps below to set up a testnet smart wallet using `starkli`:

1. **Connect to a Provider**: to interact with the network you need an RPC
   Provider. For our project we will be using Alchemy's free tier in Goerli
   Testnet.

   1. Go to [Alchemy website](https://www.alchemy.com/) and create an account.
   2. It will ask which network you want to develop on and choose Starknet.
   3. Select the Free version of the service (we will only need access to send
      some transactions to deploy the contracts)
   4. Once the account creation process is done, go to _My apps_ and create a
      new Application. Choose Starknet as a Chain and Goerli Starknet as a
      Network.
   5. Click on _View key_ on the new Starknet Application and copy the HTTPS
      url.
   6. On your terminal run:

      ```bash
      export STARKNET_RPC="<ALCHEMY_API_HTTPS_URL>"
      ```

2. **Create a Keystore**: A Keystore is a encrypted `json` file that stores the
   private keys.

   1. **Create a hidden folder**: Use the following command:

      ```bash
      mkdir -p ~/.starkli-wallets
      ```

   2. **Generate a new Keystore file**: Run the following command to create a
      new private key stored in the file. It will **ask for a password** to
      encrypt the file:

      ```bash
      starkli signer keystore new ~/.starkli-wallets/keystore.json
      ```

      The command will return the Public Key of your account, copy it to your
      clipboard to fund the account.

   3. **Set STARKNET_ACCOUNT**: To set the environment variable just run:

      ```bash
      export STARKNET_KEYSTORE="~/.starkli-wallets/keystore.json"
      ```

3. **Account Creation**: In Starknet every account is a smart contract, so to
   create one it will need to be deployed.

   1. **Initiate the account with the Open Zeppelin Account contract**:

      ```bash
      starkli account oz init --keystore ~/.starkli-wallets/keystore.json ~/.starkli-wallets/account.json
      ```

   2. **Deploy the account by running**:

      ```bash
      starkli account deploy --keystore ~/.starkli-wallets/keystore.json ~/.starkli-wallets/account.json
      ```

      For the deployment `starkli` will ask you to fund an account. To do so
      you will need to fund the address given by `starkli` with the
      [Goerli Starknet Faucet](https://faucet.goerli.starknet.io)

4. **Setting Up Environment Variables**: There are two primary environment
   variables vital for effective usage of Starkli’s CLI. These are the location
   of the keystore file for the Signer, and the location of the Account
   Descriptor file:

   ```bash
   export STARKNET_ACCOUNT=~/.starkli-wallets/account.json
   export STARKNET_KEYSTORE=~/.starkli-wallets/keystore.json
   ```

## Declare and Deploy Contracts in Testnet

By following the previous two steps, you should now have a account funded on the
Goerli testnet.

Now we are going to declare the contracts YASRouter, YASFactory, and YASPool. We are also going to deploy the contracts YASRouter and YASFactory on Testnet.

On Starknet, the deployment process is in two steps:

- Declaring the class of your contract, or sending your contract’s code to the
  network
- Deploying a contract or creating an instance of the previously declared code
  with the necessary parameters

1. Updated `.env` file: Please modify the variables with your Testnet account and your RPC provider.

   ```bash
   ACCOUNT_ADDRESS=<ACCOUNT_ADDRESS>
   ACCOUNT_PRIVATE_KEY=<ACCOUNT_PRIVATE_KEY>
   ACCOUNT_SRC=~/.starkli-wallets/account.json
   RPC_URL=<STARKNET_RPC_HTTPS_URL>
   ```

2. Build the project

   ```bash
   make build
   ```

3. Declare and Deploy: We sequentially declare and deploy the contracts.

   ```bash
   make deploy
   ```

> **Note:**
> To obtain your private key, you need to execute the following command:
>
> ```bash
> starkli signer keystore inspect-private ~/.starkli-wallets/account.json
> ```

## Setup Katana Account for Starkli

If this is the first time you are running make deploy or make demo-local in Katana, you need to generate the account file so that Starkli can use it. This is responsible for declaring and deploying contracts.

1. Start Local Testnet

   ```bash
   make start-katana
   ```

2. Setup Katana Account
   ```bash
   starkli account fetch 0x517ececd29116499f4a1b64b094da79ba08dfd54a3edaa316134c41f8160973 --output ~/.starkli-wallets/account_katana.json
   ```

The contract address we see in the above command belongs to one of Katana's pre-funded accounts.
Now we are ready to declare and deploy our contracts in Katana.

## Declare and Deploy Contracts in Katana

Katana provides us with pre-funded accounts. We will use one of them for deployment. Katana generates the same accounts, and since we know the port it's running on, we can now complete the `.env` file.

1. Updated `.env` file:

   ```bash
   # Katana Prefunded Account
   ACCOUNT_ADDRESS=0x517ececd29116499f4a1b64b094da79ba08dfd54a3edaa316134c41f8160973
   ACCOUNT_PRIVATE_KEY=0x1800000000300000180000000000030000000000003006001800006600
   ACCOUNT_SRC=~/.starkli-wallets/account_katana.json
   RPC_URL=http://0.0.0.0:5050
   ```

2. Build the project

   ```bash
   make build
   ```

3. Start Local Testnet

   ```bash
   make start-katana
   ```

4. Declare and Deploy: We sequentially declare and deploy the contracts. Local deployment needs `katana` running. The account used for deployment is a pre-funded one.

   ```bash
   make deploy
   ```

## Run local demo in Katana

This demo will perform the following steps:

- Declaration of the following contracts: ERC20 Token, YASFactory, YASPool, and YASRouter.
- Deployment of 2 ERC20 Tokens, YASFactory, YASPool, and YASRouter.
- Initialization of YASPool with a 1:1 token price.
- Execute approve() for the router to use tokens from the user.
- Execute mint() within the range [-887220, 887220] with 2000000000000000000 tokens.
- Execute swap() exchanging 500000000000000000 of token 0 for token 1.
- Display current balances of both the pool and the user.

1. Updated `.env` file:

   ```bash
   # Katana Prefunded Account
   ACCOUNT_ADDRESS=0x517ececd29116499f4a1b64b094da79ba08dfd54a3edaa316134c41f8160973
   ACCOUNT_PRIVATE_KEY=0x1800000000300000180000000000030000000000003006001800006600
   ACCOUNT_SRC=~/.starkli-wallets/account_katana.json
   RPC_URL=http://0.0.0.0:5050
   ```

1. Build the project

   ```bash
   make build
   ```

1. Start Local Testnet

   ```bash
   make start-katana
   ```

1. Run Local Demo

   ```bash
   make demo-local
   ```

## Contracts Starknet Testnet

- Router: `0x06c3b1076e09b1d16642808b0bfef750a683ad06724f9e4f1aaaca17bc44fad5`
- Factory: `0x0490c81e19516eba9eb531b48e58f9876259ac9396444dc759a84e4a8aefa628`
- Pool (USDC-ETH): `0x016648670892a29b68b66c98892f408ab2e174ffb827c023ad9f4ca0eff816eb`

## Version Specifications

- Cairo 2.2.0
- Scarb v0.7.0
- Starkli 0.1.9
- Orion `main` branch (library from Giza)

## Tooling

- [Starkli](https://book.starkli.rs/)
- [Scarb](https://book.starknet.io/chapter_2/scarb.html)
- [Cairo 1.0 VSCode Extension](https://marketplace.visualstudio.com/items?itemName=starkware.cairo1)
- [Starknet Foundry](https://foundry-rs.github.io/starknet-foundry/) **In the
  near future once it's more mature**

## Useful resources

- [Cairo Book](https://book.cairo-lang.org/)
- [Cairo by example](https://cairo-by-example.com/)
- [Starknet Book](https://book.starknet.io/index.html)
- [Uniswap Protocol](https://docs.uniswap.org/concepts/uniswap-protocol)
- [Uniswap V3 Development Book](https://uniswapv3book.com/docs/introduction/uniswap-v3/)
- [Liquidity Math in Uniswap V3](https://atiselsts.github.io/pdfs/uniswap-v3-liquidity-math.pdf)
- [UNISWAP V3 - New Era Of AMMs? Architecture Explained](https://www.youtube.com/watch?v=Ehm-OYBmlPM)
- [ZK Podcast: Exploring Uniswap V3 and a Multi-L2 Future with Noah and Moody](https://zeroknowledge.fm/185-2/)

## License

This project is licensed under the Apache 2.0 license. See [LICENSE](./LICENSE)
for more information.

## Contributors ✨

Thanks goes to these wonderful people
([emoji key](https://allcontributors.org/docs/en/emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tbody>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/rcatalan98"><img src="https://avatars.githubusercontent.com/u/13773225?v=4" width="100px;" alt="Roberto Catalan "/><br /><sub><b>Roberto Catalan </b></sub></a><br /><a href="https://github.com/lambdaclass/yet-another-swap/commits?author=rcatalan98" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/dpinones"><img src="https://avatars.githubusercontent.com/u/30808181?v=4" width="100px;" alt="Damián Piñones "/><br /><sub><b>Damián Piñones </b></sub></a><br /><a href="https://github.com/lambdaclass/yet-another-swap/commits?author=dpinones" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/dubzn"><img src="https://avatars.githubusercontent.com/u/58611754?v=4" width="100px;" alt="Santiago Galván (Dub) "/><br /><sub><b>Santiago Galván (Dub) </b></sub></a><br /><a href="https://github.com/lambdaclass/yet-another-swap/commits?author=dubzn" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/SantiagoPittella"><img src="https://avatars.githubusercontent.com/u/87827390?v=4" width="100px;" alt="Santiago Pittella "/><br /><sub><b>Santiago Pittella </b></sub></a><br /><a href="https://github.com/lambdaclass/yet-another-swap/commits?author=SantiagoPittella" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/FranFiuba"><img src="https://avatars.githubusercontent.com/u/5733366?v=4" width="100px;" alt="Francisco Strambini "/><br /><sub><b>Francisco Strambini </b></sub></a><br /><a href="https://github.com/lambdaclass/yet-another-swap/commits?author=FranFiuba" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/WiseMrMusa"><img src="https://avatars.githubusercontent.com/u/37452594?s=96&v=4" width="100px;" alt="Musa AbdulKareem "/><br /><sub><b>Musa AbdulKareem </b></sub></a><br /><a href="https://github.com/lambdaclass/yet-another-swap/commits?author=WiseMrMusa" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/0xd3bs"><img src="https://avatars.githubusercontent.com/u/6605280?v=4" width="100px;" alt="dblanco "/><br /><sub><b>dblanco </b></sub></a><br /><a href="https://github.com/lambdaclass/yet-another-swap/commits?author=0xd3bs" title="Code">💻</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/Nadai2010"><img src="https://avatars.githubusercontent.com/u/112663528?v=4" width="100px;" alt="Nadai "/><br /><sub><b>Nadai </b></sub></a><br /><a href="https://github.com/lambdaclass/yet-another-swap/commits?author=Nadai2010" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/dbejarano820"><img src="https://avatars.githubusercontent.com/u/58019353?v=4" width="100px;" alt="Daniel Bejarano "/><br /><sub><b>Daniel Bejarano </b></sub></a><br /><a href="https://github.com/lambdaclass/yet-another-swap/commits?author=dbejarano820" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/ftupas"><img src="https://avatars.githubusercontent.com/u/35031356?v=4" width="100px;" alt="ftupas "/><br /><sub><b>ftupas </b></sub></a><br /><a href="https://github.com/lambdaclass/yet-another-swap/commits?author=ftupas" title="Code">💻</a></td>
    </tr>
  </tbody>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the
[all-contributors](https://github.com/all-contributors/all-contributors)
specification. Contributions of any kind welcome!
