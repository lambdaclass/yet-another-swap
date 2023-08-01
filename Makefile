deps:
	curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh \
	&& curl https://get.starkli.sh | sh

build:
	scarb build

declare: 
	starkli declare target/dev/contracts_Ownable.sierra.json --account $STARKNET_ACCOUNT --network=goerli-1 --compiler-version=2.0.1


