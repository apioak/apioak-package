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

INSTALL_FPM()
{
    sudo apt-get install -y ruby ruby-dev rubygems build-essential
    sudo gem sources --add https://gems.ruby-china.com/ --remove https://rubygems.org/
    sudo gem sources -l
    sudo gem update --system
    sudo gem install --no-ri --no-rdoc fpm
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
    sudo luarocks install rockspec/apioak-master-0.rockspec --tree=/usr/local/apioak/deps --only-deps --local
    sudo make install
    sudo mkdir -p /tmp/apioak/usr/local
    sudo mv /usr/local/apioak /tmp/apioak/usr/local/apioak
    sudo make uninstall
    cd ${ABS_PATH}

    fpm -f -s dir -t deb -n apioak \
        -m 'Janko <shuaijinchao@gmail.com>' \
        -v ${VERSION} \
        --iteration ${ITERATION} \
        --description 'APIOAK provides full life cycle management of API release, management, and operation and maintenance.' \
        --license "Apache License 2.0"  \
        -C /tmp/apioak \
        -p ${ABS_PATH} \
        --url 'https://apioak.com' \
        --deb-no-default-config-files \
        --before-install ${ABS_PATH}/ubuntu/install_before.sh

    REMOVE_CACHE_PATH ${ABS_PATH}
}
