deps:
	curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh -s -- -v  0.7.0 \
	&& curl https://get.starkli.sh | sh

build:
	scarb build

declare: 
	@echo "Declare YAS Pool contract"
	starkli declare target/dev/yas_YASPool.sierra.json --keystore ~/.starkli-wallets/keystore.json --account ~/.starkli-wallets/account.json
	
	@echo "Declare YAS Factory contract"
	starkli declare target/dev/yas_YASFactory.sierra.json --keystore ~/.starkli-wallets/keystore.json --account ~/.starkli-wallets/account.json

deploy:
	cargo run --bin deploy

test:
	scarb test
