deps: install-dojo
	curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh -s -- -v  0.7.0 \

fmt:
	scarb fmt 
	npx prettier -w .

install-dojo:
	@echo "Installing Dojo..."
	@if [ ! -d "${HOME}/.dojo" ]; then mkdir -p ${HOME}/.dojo; fi
	@cd ${HOME}/.dojo && \
	if [ ! -d "dojo" ]; then git clone https://github.com/dojoengine/dojo; fi && \
	cd dojo && \
	cargo install --path ./crates/katana --locked --force
	@echo "Dojo installation complete."

start-katana:
	katana

build:
	scarb build

deploy:
	cargo run --bin deploy
	
demo-local:
	cargo run --bin local

test:
	scarb test

declare-testnet:
	@./scripts/check_env_vars.sh
	@echo "\n==> Declaring Router"
	starkli declare --watch --keystore ${STARKNET_KEYSTORE} --account ${STARKNET_ACCOUNT} ./target/dev/yas_YASRouter.sierra.json 
	@echo "\n==> Declaring Factory"
	starkli declare --watch --keystore ${STARKNET_KEYSTORE} --account ${STARKNET_ACCOUNT} ./target/dev/yas_YASFactory.sierra.json 
	@echo "\n==> Declaring YASPool"
	starkli declare --watch --keystore ${STARKNET_KEYSTORE} --account ${STARKNET_ACCOUNT} ./target/dev/yas_YASPool.sierra.json

