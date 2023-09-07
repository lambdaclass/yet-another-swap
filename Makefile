deps:
	curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh -s -- -v  0.7.0 \
	&& curl https://get.starkli.sh | sh

build:
	scarb build

declare: 
	starkli declare target/dev/fractal_swap_AMM.sierra.json --keystore ~/.starkli-wallets/keystore.json --account ~/.starkli-wallets/account.json

CLASS_HASH:=
deploy:
	starkli deploy $(CLASS_HASH) --keystore ~/.starkli-wallets/keystore.json  --account ~/.starkli-wallets/account.json

test:
	scarb test
