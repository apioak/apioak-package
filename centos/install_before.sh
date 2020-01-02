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
    sudo rm -f /usr/bin/cmake
    sudo yum -y install gcc gcc-c++ git cmake3 make automake autoconf curl wget
    sudo ln -s /usr/bin/cmake3 /usr/bin/cmake
}

INSTALL_OPENRESTY()
{
    sudo yum install -y yum-utils
    sudo yum-config-manager --add-repo https://openresty.org/package/centos/openresty.repo
    sudo yum install -y openresty openresty-resty pcre-devel openssl-devel lua-devel libtool
}

INSTALL_LUAROCKS()
{
    wget http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    sudo rpm -ivh epel-release-latest-7.noarch.rpm
    sudo yum -y install luarocks
    sudo rm -f epel-release-latest-7.noarch.rpm
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
