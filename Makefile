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

deploy: build
	@./scripts/deploy.sh
	
demo-local: build
	@./scripts/run_local_demo.sh

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

setup-katana-account: 
	@./scripts/setup_katana_account.sh
