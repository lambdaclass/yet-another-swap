# Testing GitHub workflows locally

## Using 'act' (`https://github.com/nektos/act`) to test GitHub actions locally
### Installation

For MacOS users simply run:
```brew install act```

For Linux users:

1. Download `act` tool
```bash
curl -s https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

Now to verify it is correctly installed:

```bash
act --version
```

You will have to specify the 'workflows' folder with `-a` parameter:

```bash
act -a .github/workflows/
```

To only run one of the github events you can specify it with the `-j` flag

```bash
act -a .github/workflows/ -j katana
```
