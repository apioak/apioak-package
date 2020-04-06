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
    sudo yum -y install gcc gcc-c++ git make automake autoconf curl wget lua-devel libtool pcre-devel
}

INSTALL_FPM()
{
    sudo yum -y install ruby ruby-devel rubygems rubygems-devel rpm-build libffi libffi-devel
    sudo gem sources --add https://gems.ruby-china.com/ --remove https://rubygems.org/
    sudo gem sources -l
    sudo gem update --system
    sudo gem install ffi
    sudo gem install --no-ri --no-rdoc fpm
}

INSTALL_OPENRESTY()
{
    sudo yum install -y yum-utils
    sudo yum-config-manager --add-repo https://openresty.org/package/centos/openresty.repo
    sudo yum install -y openresty openresty-resty pcre-devel openssl-devel lua-devel libtool
}

INSTALL_LUAROCKS()
{
    sudo yum -y install luarocks
}

REMOVE_CACHE_PATH()
{
    sudo rm -rf /usr/local/apioak
    sudo rm -rf /tmp/apioak
    sudo rm -rf $1/apioak
}

REMOVE_CACHE_FILE()
{
    sudo rm -rf $1/*.rpm
    sudo rm -rf $1/*.deb
}

BUILD_PACKAGE()
{
    VERSION=$1
    ITERATION=$2
    ABS_PATH=${PWD}

    REMOVE_CACHE_PATH ${ABS_PATH}
    REMOVE_CACHE_FILE ${ABS_PATH}

    git clone -b v${VERSION} https://github.com/apioak/apioak.git
    cd apioak
    sudo luarocks make rockspec/apioak-master-0.rockspec --tree=/usr/local/apioak/deps --local

    sudo mkdir -p /tmp/apioak/usr/local
    sudo mkdir -p /tmp/apioak/usr/bin

    chown -R root:root /usr/local/apioak
    chmod -R 755 /usr/local/apioak

    cp -rf /usr/local/apioak /tmp/apioak/usr/local/
    cp -rf /usr/local/apioak/bin/apioak /tmp/apioak/usr/bin/

    sudo make uninstall
    cd ${ABS_PATH}

    fpm -f -s dir -t rpm -n apioak \
        -m 'Janko <shuaijinchao@gmail.com>' \
        -v ${VERSION} \
        --iteration ${ITERATION}.el7 \
        --description 'APIOAK is complete lifecycle management API gateway.' \
        --license "Apache License 2.0"  \
        -C /tmp/apioak \
        -p ${ABS_PATH} \
        --url 'https://apioak.com' \
        -d 'openresty >= 1.15.8.2' \
        -d 'luarocks >= 2.3.0'

    REMOVE_CACHE_PATH ${ABS_PATH}
}
