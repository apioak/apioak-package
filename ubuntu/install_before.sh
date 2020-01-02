#!/usr/bin/env bash

CHECK_COMMAND()
{
    if type $1 2>/dev/null; then
        echo "OK"
    else
        echo "FAIL"
    fi
}

INSTALL_BASE_TOOLS()
{
    sudo apt-get update
    sudo apt-get install -y gcc g++ git cmake make automake autoconf pkg-config curl wget
}

INSTALL_OPENRESTY()
{
    wget -qO - https://openresty.org/package/pubkey.gpg | sudo apt-key add -
    sudo apt-get update
    sudo apt-get -y install software-properties-common
    sudo add-apt-repository -y "deb http://openresty.org/package/ubuntu $(lsb_release -sc) main"
    sudo apt-get update
    sudo apt-get install -y openresty openresty-resty libpcre3 libpcre3-dev libssl1.0-dev libtool
}

INSTALL_LUAROCKS()
{
    sudo apt-get install luarocks
}

INSTALL_BASE_TOOLS

OPENRESTY_EXISTS=$(CHECK_COMMAND openresty)
if [[ ${OPENRESTY_EXISTS} = "FAIL" ]]; then
    INSTALL_OPENRESTY
fi


LUAROCKS_EXISTS=$(CHECK_COMMAND luarocks)
if [[ ${LUAROCKS_EXISTS} = "FAIL" ]]; then
    INSTALL_LUAROCKS
fi
