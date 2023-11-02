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

KATANA_PRIVATE_KEY = 0x1800000000300000180000000000030000000000003006001800006600
KATANA_ACCOUNT_ADDRESS = 0x517ececd29116499f4a1b64b094da79ba08dfd54a3edaa316134c41f8160973
KATANA_URL = http://0.0.0.0:5050

local-example:
	@echo "\n==> Declaring ERC20"; \
	starkli declare --watch --private-key $(KATANA_PRIVATE_KEY) --account ~/.starkli-wallets/account_katana.json --rpc $(KATANA_URL) ./target/dev/yas_core_ERC20.sierra.json > tmp_erc20_declare.txt; \
	cat ./tmp_erc20_declare.txt

	@echo "\n==> Declaring Router"; \
	starkli declare --watch --private-key $(KATANA_PRIVATE_KEY) --account ~/.starkli-wallets/account_katana.json --rpc $(KATANA_URL) ./target/dev/yas_core_YASRouter.sierra.json > tmp_router_declare.txt; \
	cat ./tmp_router_declare.txt

	@echo "\n==> Declaring Factory"; \
	starkli declare --watch --private-key $(KATANA_PRIVATE_KEY) --account ~/.starkli-wallets/account_katana.json --rpc $(KATANA_URL) ./target/dev/yas_core_YASFactory.sierra.json > tmp_factory_declare.txt; \
	cat ./tmp_factory_declare.txt

	@echo "\n==> Declaring Pool"; \
	starkli declare --watch --private-key $(KATANA_PRIVATE_KEY) --account ~/.starkli-wallets/account_katana.json --rpc $(KATANA_URL) ./target/dev/yas_core_YASPool.sierra.json > tmp_pool_declare.txt; \
	cat ./tmp_pool_declare.txt;

	@echo "\n==> Deploying YAS0 token"
	@ERC20_CLASS_HASH=$(shell cat ./tmp_erc20_declare.txt); \
	starkli deploy --watch "$$ERC20_CLASS_HASH" --private-key $(KATANA_PRIVATE_KEY) --rpc $(KATANA_URL) --account ~/.starkli-wallets/account_katana.json \
		362274706224 \
		156116276016 \
		u256:4000000000000000000 \
		$(KATANA_ACCOUNT_ADDRESS) > tmp_token_0_address.txt; \
	cat ./tmp_token_0_address.txt;

	@echo "\n==> Deploying YAS1 token"
	@ERC20_CLASS_HASH=$(shell cat ./tmp_erc20_declare.txt); \
	starkli deploy --watch "$$ERC20_CLASS_HASH" --private-key $(KATANA_PRIVATE_KEY) --rpc $(KATANA_URL) --account ~/.starkli-wallets/account_katana.json \
		362274706225 \
		156116276017 \
		u256:4000000000000000000 \
		$(KATANA_ACCOUNT_ADDRESS) > tmp_token_1_address.txt; \
	cat ./tmp_token_1_address.txt;

	@echo "\n==> Deploying Factory"
	@FACTORY_CLASS_HASH=$(shell cat ./tmp_factory_declare.txt); \
	POOL_CLASS_HASH=$(shell cat ./tmp_pool_declare.txt); \
	starkli deploy --watch "$$FACTORY_CLASS_HASH" --private-key $(KATANA_PRIVATE_KEY) --rpc $(KATANA_URL) --account ~/.starkli-wallets/account_katana.json \
	$(KATANA_ACCOUNT_ADDRESS) \
	"$$POOL_CLASS_HASH" > tmp_factory_address.txt; \
	cat ./tmp_factory_address.txt;

	@echo "\n==> Deploying Router"
	@ROUTER_CLASS_HASH=$(shell cat ./tmp_router_declare.txt); \
	starkli deploy --watch "$$ROUTER_CLASS_HASH" --private-key $(KATANA_PRIVATE_KEY) --rpc $(KATANA_URL) --account ~/.starkli-wallets/account_katana.json

	@echo "\n==> Deploying Pool"
	@FACTORY_ADDRESS=$(shell cat ./tmp_factory_address.txt); \
	TOKEN_0_ADDRESS=$(shell cat ./tmp_token_0_address.txt); \
	TOKEN_1_ADDRESS=$(shell cat ./tmp_token_1_address.txt); \
	POOL_CLASS_HASH=$(shell cat ./tmp_pool_declare.txt); \
	starkli deploy --watch "$$POOL_CLASS_HASH" --private-key $(KATANA_PRIVATE_KEY) --rpc $(KATANA_URL) --account ~/.starkli-wallets/account_katana.json \
		"$$FACTORY_ADDRESS" \
		"$$TOKEN_0_ADDRESS" \
		"$$TOKEN_1_ADDRESS" \
		3000 \
		60 0 > tmp_pool_address.txt;
	cat ./tmp_pool_address.txt;

	@echo "\n==> Initialize Pool"
	@POOL_ADDRESS=$(shell cat ./tmp_pool_address.txt); \
	starkli invoke --watch --private-key $(KATANA_PRIVATE_KEY) --rpc $(KATANA_URL) "$$POOL_ADDRESS" initialize \
		u256:79228162514264337593543950336 \
		0;