#!/bin/bash

source .env

# This values are from Katana, just for testing
KATANA_PRIVATE_KEY=0x1800000000300000180000000000030000000000003006001800006600
KATANA_ACCOUNT_ADDRESS=0x517ececd29116499f4a1b64b094da79ba08dfd54a3edaa316134c41f8160973
KATANA_URL=http://0.0.0.0:5050

U128_MAX=340282366920938463463374607431768211455

KATANA_ACCOUNT_SRC=$ACCOUNT_SRC

export STARKNET_ACCOUNT=$KATANA_ACCOUNT_SRC
export STARKNET_RPC=$KATANA_URL

# ANSI format
GREEN='\e[32m'
RESET='\e[0m'

# Check if the JSON file exists
if [ ! -f "$KATANA_ACCOUNT_SRC" ]; then
    $(starkli account fetch --output $KATANA_ACCOUNT_SRC $KATANA_ACCOUNT_ADDRESS)
    echo -e "$GREEN\n==> Katana JSON account file created at: $KATANA_ACCOUNT_SRC$RESET"
else
    echo -e "$GREEN\n==> Katana JSON account file already exists at: $KATANA_ACCOUNT_SRC$RESET"
fi

# Declare all contracts
echo -e "$GREEN\n==> Declaring ERC20$RESET"
ERC20_CLASS_HASH=$(starkli declare --watch --private-key $KATANA_PRIVATE_KEY ./target/dev/yas_core_ERC20.sierra.json)
echo -e $GREEN$ERC20_CLASS_HASH$RESET

echo -e "$GREEN\n==> Declaring Router$RESET"
ROUTER_CLASS_HASH=$(starkli declare --watch --private-key $KATANA_PRIVATE_KEY ./target/dev/yas_core_YASRouter.sierra.json)
echo -e $GREEN$ROUTER_CLASS_HASH

echo -e "$GREEN\n==> Declaring Factory$RESET"
FACTORY_CLASS_HASH=$(starkli declare --watch --private-key $KATANA_PRIVATE_KEY ./target/dev/yas_core_YASFactory.sierra.json)
echo -e $GREEN$FACTORY_CLASS_HASH$RESET

echo -e "$GREEN\n==> Declaring Pool$RESET"
POOL_CLASS_HASH=$(starkli declare --watch --private-key $KATANA_PRIVATE_KEY ./target/dev/yas_core_YASPool.sierra.json)
echo -e $GREEN$POOL_CLASS_HASH$RESET

echo -e "$GREEN\n==> Deploying TYAS0 token$RESET"
# name: TYAS0
# symbol: $YAS0
# supply: 4000000000000000000
# recipent: Katana account
TOKEN_0_ADDRESS=$(starkli deploy --watch $ERC20_CLASS_HASH --private-key $KATANA_PRIVATE_KEY \
    362274706224 \
    156116276016 \
    u256:4000000000000000000 \
    $KATANA_ACCOUNT_ADDRESS)
echo -e $GREEN$TOKEN_0_ADDRESS$RESET

echo -e "$GREEN\n==> Deploying TYAS1 token$RESET"
# name: TYAS1
# symbol: $YAS1
# supply: 4000000000000000000
# recipent: Katana account
TOKEN_1_ADDRESS=$(starkli deploy --watch $ERC20_CLASS_HASH --private-key $KATANA_PRIVATE_KEY \
    362274706225 \
    156116276017 \
    u256:4000000000000000000 \
    $KATANA_ACCOUNT_ADDRESS)
echo -e $GREEN$TOKEN_1_ADDRESS$RESET

echo -e "$GREEN\n==> Deploying Factory$RESET"
FACTORY_ADDRESS=$(starkli deploy --watch $FACTORY_CLASS_HASH --private-key $KATANA_PRIVATE_KEY \
	$KATANA_ACCOUNT_ADDRESS \
	$POOL_CLASS_HASH)
echo -e $GREEN$FACTORY_ADDRESS$RESET

echo -e "$GREEN\n==> Deploying Router$RESET"
ROUTER_ADDRESS=$(starkli deploy --watch $ROUTER_CLASS_HASH --private-key $KATANA_PRIVATE_KEY)
echo -e $GREEN$ROUTER_ADDRESS$RESET

echo -e "$GREEN\n==> Deploying Pool$RESET"
POOL_ADDRESS=$(starkli deploy --watch $POOL_CLASS_HASH --private-key $KATANA_PRIVATE_KEY \
    $FACTORY_ADDRESS \
    $TOKEN_0_ADDRESS \
    $TOKEN_1_ADDRESS \
    3000 \
    60 0 )
echo -e $GREEN$POOL_ADDRESS$RESET

echo -e "$GREEN\n==> Initialize Pool$RESET"
starkli invoke --watch --private-key $KATANA_PRIVATE_KEY $POOL_ADDRESS initialize \
    u256:79228162514264337593543950336 \
    0;

echo -e "$GREEN\n==> TYAS0 Approve$RESET"
starkli invoke --watch --private-key $KATANA_PRIVATE_KEY $TOKEN_0_ADDRESS approve \
    $ROUTER_ADDRESS \
    $U128_MAX \
    $U128_MAX

echo -e "$GREEN\n==> TYAS1 Approve$RESET"
starkli invoke --watch --private-key $KATANA_PRIVATE_KEY $TOKEN_1_ADDRESS approve \
    $ROUTER_ADDRESS \
    $U128_MAX \
    $U128_MAX

OWNER_T0_BALANCE_BF_MINT=$(starkli call $TOKEN_0_ADDRESS balanceOf $KATANA_ACCOUNT_ADDRESS)
OWNER_T1_BALANCE_BF_MINT=$(starkli call $TOKEN_1_ADDRESS balanceOf $KATANA_ACCOUNT_ADDRESS)

echo -e "$GREEN\n==> Balance before mint$RESET"
echo -e "$GREEN      TYAS0: $OWNER_T0_BALANCE_BF_MINT\n      TYAS1: $OWNER_T1_BALANCE_BF_MINT$RESET"

echo -e "$GREEN\n==> Mint$RESET"
starkli invoke --watch --private-key $KATANA_PRIVATE_KEY $ROUTER_ADDRESS mint \
    $POOL_ADDRESS \
    $KATANA_ACCOUNT_ADDRESS \
    887220 1 \
    887220 0 \
    2000000000000000000

OWNER_T0_BALANCE_AF_MINT=$(starkli call $TOKEN_0_ADDRESS balanceOf $KATANA_ACCOUNT_ADDRESS)
OWNER_T1_BALANCE_AF_MINT=$(starkli call $TOKEN_1_ADDRESS balanceOf $KATANA_ACCOUNT_ADDRESS)

echo -e "$GREEN\n==> Balance after mint$RESET"
echo -e "$GREEN      TYAS0: $OWNER_T0_BALANCE_AF_MINT\n      TYAS1: $OWNER_T1_BALANCE_AF_MINT$RESET"

echo -e "$GREEN\n==> Swap"
starkli invoke --watch --private-key $KATANA_PRIVATE_KEY $ROUTER_ADDRESS swap \
    $POOL_ADDRESS \
    $KATANA_ACCOUNT_ADDRESS \
    1 \
    500000000000000000 0 \
    1 \
    4295128740 0 0 \

OWNER_T0_BALANCE_AF_SWAP=$(starkli call $TOKEN_0_ADDRESS balanceOf $KATANA_ACCOUNT_ADDRESS)
OWNER_T1_BALANCE_AF_SWAP=$(starkli call $TOKEN_1_ADDRESS balanceOf $KATANA_ACCOUNT_ADDRESS)

echo -e "$GREEN\n==> Balance after swap$RESET"
echo -e "$GREEN      TYAS0: $OWNER_T0_BALANCE_AF_SWAP\n      TYAS1: $OWNER_T1_BALANCE_AF_SWAP$RESET"
