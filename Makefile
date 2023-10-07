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

GREEN := \033[32m
RESET := \033[0m
FILTER = off
test:
	@if [ "$(FILTER)" = "off" ]; then \
		scarb test; \
	else \
		echo "     $(GREEN)Running$(RESET) cairo-test yas with filter=$(FILTER)\ntesting yas ...\n";\
		scarb test | grep -P --color=always '$(FILTER)' | sed -E 's/$(FILTER)/\x1b[34m&\x1b[0m/g; s/ ok /\x1b[32m&\x1b[0m/g; s/ fail /\x1b[31m&\x1b[0m/g'; \
		echo "";\
	fi

declare-testnet:
	@./scripts/check_env_vars.sh
	@echo "\n==> Declaring Router"
	starkli declare --watch --keystore ${STARKNET_KEYSTORE} --account ${STARKNET_ACCOUNT} ./target/dev/yas_YASRouter.sierra.json 
	@echo "\n==> Declaring Factory"
	starkli declare --watch --keystore ${STARKNET_KEYSTORE} --account ${STARKNET_ACCOUNT} ./target/dev/yas_YASFactory.sierra.json 
	@echo "\n==> Declaring YASPool"
	starkli declare --watch --keystore ${STARKNET_KEYSTORE} --account ${STARKNET_ACCOUNT} ./target/dev/yas_YASPool.sierra.json

