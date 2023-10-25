# Testing GitHub workflows locally

We are using [act](`https://github.com/nektos/act`) to test GitHub actions locally
### Installation

#### For Linux users:

1. Download `act` tool
```bash
curl -s https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash
```

2. Move it to the appropiate /bin folder:

```bash
mv ./bin/act /bin/act
```

3. Verify it is correctly installed:

```bash
act --version
```

#### For MacOS users:
1. simply run:
```bash
brew install act
```

2. Verify it is correctly installed:

```bash
act --version
```

### How to use act
#### Linux
To run all the 'workflows':
```bash
act -a .github/workflows/
```

To run only one of the github events, specify it with the `-j` flag

```bash
act -a .github/workflows/ -j katana
```

#### For MacOS users with M1 processor or newer versions:
To run all the 'workflows':
```bash
act -a .github/workflows/ --container-architecture linux/amd64
``` 

To run only one of the github events, specify it with the `-j` flag:
```bash
act -a .github/workflows/ -j katana --container-architecture linux/amd64
```
