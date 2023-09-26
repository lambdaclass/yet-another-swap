deps:
	curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh -s -- -v  0.7.0 \

build:
	scarb build

deploy:
	cargo run --bin deploy

test:
	scarb test
