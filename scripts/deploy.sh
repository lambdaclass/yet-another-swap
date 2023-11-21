#!/bin/bash

source .env

export STARKNET_ACCOUNT=$ACCOUNT_SRC
export STARKNET_RPC=$RPC_URL

# ANSI format
GREEN='\e[32m'
RESET='\e[0m'

# Declare all contracts

echo -e "$GREEN\n==> Declaring Router$RESET"
ROUTER_CLASS_HASH=$(starkli declare --watch --private-key $ACCOUNT_PRIVATE_KEY ./target/dev/yas_core_YASRouter.sierra.json)
echo -e $GREEN$ROUTER_CLASS_HASH

echo -e "$GREEN\n==> Declaring Factory$RESET"
FACTORY_CLASS_HASH=$(starkli declare --watch --private-key $ACCOUNT_PRIVATE_KEY ./target/dev/yas_core_YASFactory.sierra.json)
echo -e $GREEN$FACTORY_CLASS_HASH$RESET

echo -e "$GREEN\n==> Declaring Pool$RESET"
POOL_CLASS_HASH=$(starkli declare --watch --private-key $ACCOUNT_PRIVATE_KEY ./target/dev/yas_core_YASPool.sierra.json)
echo -e $GREEN$POOL_CLASS_HASH$RESET

echo -e "$GREEN\n==> Deploying Factory$RESET"
FACTORY_ADDRESS=$(starkli deploy --watch $FACTORY_CLASS_HASH --private-key $ACCOUNT_PRIVATE_KEY \
	$ACCOUNT_ADDRESS \
	$POOL_CLASS_HASH)
echo -e $GREEN$FACTORY_ADDRESS$RESET

echo -e "$GREEN\n==> Deploying Router$RESET"
ROUTER_ADDRESS=$(starkli deploy --watch $ROUTER_CLASS_HASH --private-key $ACCOUNT_PRIVATE_KEY)
echo -e $GREEN$ROUTER_ADDRESS$RESET