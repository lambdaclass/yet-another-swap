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

clean:
	scarb clean

build: clean
	scarb build

deploy: clean
	cargo run --bin deploy
	
demo-local: build
	cargo run --bin local

demo-local-cli:
	@./scripts/demo_local_cli.sh

Command := $(firstword $(MAKECMDGOALS))
FILTER := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
test:
ifneq ($(FILTER),)
	scarb test -f $(FILTER)
else
	scarb test
endif
%::
	@true

declare-testnet:
	@./scripts/check_env_vars.sh
	@echo "\n==> Declaring Router"
	starkli declare --watch --keystore ${STARKNET_KEYSTORE} --account ${STARKNET_ACCOUNT} --rpc ${STARKNET_RPC} ./target/dev/yas_core_YASRouter.sierra.json
	@echo "\n==> Declaring Factory"
	starkli declare --watch --keystore ${STARKNET_KEYSTORE} --account ${STARKNET_ACCOUNT} --rpc ${STARKNET_RPC} ./target/dev/yas_core_YASFactory.sierra.json
	@echo "\n==> Declaring Pool"
	starkli declare --watch --keystore ${STARKNET_KEYSTORE} --account ${STARKNET_ACCOUNT} --rpc ${STARKNET_RPC} ./target/dev/yas_core_YASPool.sierra.json
