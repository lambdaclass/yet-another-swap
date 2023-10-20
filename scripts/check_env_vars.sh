#!/bin/bash

if [ -z "${STARKNET_KEYSTORE}" ]; then
    echo "Error: STARKNET_KEYSTORE environment variable is not defined."
    echo ""
    echo "Did you declare the STARKNET_KEYSTORE environment variable?"
    echo "It should look something like this:"
    echo '   export STARKNET_KEYSTORE="~/.starkli-wallets/keystore.json"'
    echo "Declare it and try again! :)"
    echo ""
    exit 1
fi

if [ -z "${STARKNET_ACCOUNT}" ]; then
    echo "Error: STARKNET_ACCOUNT environment variable is not defined."
    echo "Did you declare the STARKNET_ACCOUNT environment variable?"
    echo "It should look something like this:"
    echo '   export STARKNET_ACCOUNT="~/.starkli-wallets/account.json"'
    echo "Declare it and try again! :)"
    echo ""
    exit 2
fi

