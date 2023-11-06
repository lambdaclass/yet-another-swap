#!/bin/bash

# This values are from Katana, just for testing
KATANA_PRIVATE_KEY=0x1800000000300000180000000000030000000000003006001800006600
KATANA_ACCOUNT_ADDRESS=0x517ececd29116499f4a1b64b094da79ba08dfd54a3edaa316134c41f8160973
KATANA_URL=http://0.0.0.0:5050

KATANA_ACCOUNT_SRC="~/.starkli-wallets/account_katana.json"

U128_MAX=340282366920938463463374607431768211455

export STARKNET_ACCOUNT=$KATANA_ACCOUNT_SRC
export STARKNET_RPC=$KATANA_URL

# Declare all contracts
echo -e "\n==> Declaring ERC20"
ERC20_CLASS_HASH=$(starkli declare --watch --private-key $KATANA_PRIVATE_KEY ./target/dev/yas_core_ERC20.sierra.json)
echo -e $ERC20_CLASS_HASH

echo -e "\n==> Declaring Router"
ROUTER_CLASS_HASH=$(starkli declare --watch --private-key $KATANA_PRIVATE_KEY ./target/dev/yas_core_YASRouter.sierra.json)
echo -e $ROUTER_CLASS_HASH

echo -e "\n==> Declaring Factory"
FACTORY_CLASS_HASH=$(starkli declare --watch --private-key $KATANA_PRIVATE_KEY ./target/dev/yas_core_YASFactory.sierra.json)
echo -e $FACTORY_CLASS_HASH

echo -e "\n==> Declaring Pool"
POOL_CLASS_HASH=$(starkli declare --watch --private-key $KATANA_PRIVATE_KEY ./target/dev/yas_core_YASPool.sierra.json)
echo -e $POOL_CLASS_HASH

echo -e "\n==> Deploying TYAS0 token"
# name: TYAS0
# symbol: $YAS0
# supply: 4000000000000000000
# recipent: Katana account
TOKEN_0_ADDRESS=$(starkli deploy --watch $ERC20_CLASS_HASH --private-key $KATANA_PRIVATE_KEY \
    362274706224 \
    156116276016 \
    u256:4000000000000000000 \
    $KATANA_ACCOUNT_ADDRESS)
echo -e $TOKEN_0_ADDRESS

echo -e "\n==> Deploying TYAS1 token"
# name: TYAS1
# symbol: $YAS1
# supply: 4000000000000000000
# recipent: Katana account
TOKEN_1_ADDRESS=$(starkli deploy --watch $ERC20_CLASS_HASH --private-key $KATANA_PRIVATE_KEY \
    362274706225 \
    156116276017 \
    u256:4000000000000000000 \
    $KATANA_ACCOUNT_ADDRESS)
echo -e $TOKEN_1_ADDRESS

echo -e "\n==> Deploying Factory"
FACTORY_ADDRESS=$(starkli deploy --watch $FACTORY_CLASS_HASH --private-key $KATANA_PRIVATE_KEY \
	$KATANA_ACCOUNT_ADDRESS \
	$POOL_CLASS_HASH)
echo -e $FACTORY_ADDRESS

echo -e "\n==> Deploying Router"
ROUTER_ADDRESS=$(starkli deploy --watch $ROUTER_CLASS_HASH --private-key $KATANA_PRIVATE_KEY)
echo -e $ROUTER_ADDRESS

echo -e "\n==> Deploying Pool"
POOL_ADDRESS=$(starkli deploy --watch $POOL_CLASS_HASH --private-key $KATANA_PRIVATE_KEY \
    $FACTORY_ADDRESS \
    $TOKEN_0_ADDRESS \
    $TOKEN_1_ADDRESS \
    3000 \
    60 0 )
echo -e $POOL_ADDRESS

echo -e "\n==> Initialize Pool"
starkli invoke --watch --private-key $KATANA_PRIVATE_KEY $POOL_ADDRESS initialize \
    u256:79228162514264337593543950336 \
    0;

echo -e "\n==> TYAS0 Approve"
starkli invoke --watch --private-key $KATANA_PRIVATE_KEY $TOKEN_0_ADDRESS approve \
    $ROUTER_ADDRESS \
    $U128_MAX \
    $U128_MAX

echo -e "\n==> TYAS1 Approve"
starkli invoke --watch --private-key $KATANA_PRIVATE_KEY $TOKEN_1_ADDRESS approve \
    $ROUTER_ADDRESS \
    $U128_MAX \
    $U128_MAX

OWNER_T0_BALANCE_BF_MINT=$(starkli call $TOKEN_0_ADDRESS balanceOf $KATANA_ACCOUNT_ADDRESS)
OWNER_T1_BALANCE_BF_MINT=$(starkli call $TOKEN_1_ADDRESS balanceOf $KATANA_ACCOUNT_ADDRESS)

echo -e "\n==> Balance before mint"
echo -e "      TYAS0: $OWNER_T0_BALANCE_BF_MINT\n      TYAS1: $OWNER_T1_BALANCE_BF_MINT"

echo -e "\n==> Mint"
starkli invoke --watch --private-key $KATANA_PRIVATE_KEY $ROUTER_ADDRESS mint \
    $POOL_ADDRESS \
    $KATANA_ACCOUNT_ADDRESS \
    887220 1 \
    887220 0 \
    2000000000000000000

OWNER_T0_BALANCE_AF_MINT=$(starkli call $TOKEN_0_ADDRESS balanceOf $KATANA_ACCOUNT_ADDRESS)
OWNER_T1_BALANCE_AF_MINT=$(starkli call $TOKEN_1_ADDRESS balanceOf $KATANA_ACCOUNT_ADDRESS)

echo -e "\n==> Balance after mint"
echo -e "      TYAS0: $OWNER_T0_BALANCE_AF_MINT\n      TYAS1: $OWNER_T1_BALANCE_AF_MINT"

echo -e "\n==> Swap"
starkli invoke --watch --private-key $KATANA_PRIVATE_KEY $ROUTER_ADDRESS swap \
    $POOL_ADDRESS \
    $KATANA_ACCOUNT_ADDRESS \
    1 \
    500000000000000000 0 \
    1 \
    4295128740 0 0 \

OWNER_T0_BALANCE_AF_SWAP=$(starkli call $TOKEN_0_ADDRESS balanceOf $KATANA_ACCOUNT_ADDRESS)
OWNER_T1_BALANCE_AF_SWAP=$(starkli call $TOKEN_1_ADDRESS balanceOf $KATANA_ACCOUNT_ADDRESS)

echo -e "\n==> Balance after swap"
echo -e "      TYAS0: $OWNER_T0_BALANCE_AF_SWAP\n      TYAS1: $OWNER_T1_BALANCE_AF_SWAP"