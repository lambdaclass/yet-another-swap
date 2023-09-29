deps: install-dojo
	curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh -s -- -v  0.7.0 \

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

test:
	scarb test
