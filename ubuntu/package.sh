#!/usr/bin/env bash

export PATH=$PATH:/usr/local/bin

CHECK_COMMAND()
{
    if type $1 2>/dev/null; then
        echo "OK"
    else
        echo "FAIL"
    fi
}

INSTALL_TOOLS()
{
    sudo apt-get update
    sudo apt-get install -y gcc \
                            g++ \
                            git \
                            cmake \
                            make \
                            automake \
                            autoconf \
                            pkg-config \
                            curl \
                            wget \
                            libtool \
                            libpcre3-dev \
                            build-essential \
                            ruby \
                            ruby-dev \
                            rubygems \
                            luarocks
}

INSTALL_FPM()
{
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

REMOVE_CACHE()
{
    sudo rm -rf /tmp/apioak
    sudo rm -rf ${PWD}/apioak
}

VERSION=$1
ITERATION=$2

if [[ ${VERSION} = "" ]]; then
    exit 1
fi

if [[ ${ITERATION} = "" ]]; then
    ITERATION=1
fi

echo "================================="
echo "Build APIOAK Version: v${VERSION}"
echo "================================="

INSTALL_TOOLS

REMOVE_CACHE

OPENRESTY_EXISTS=$(CHECK_COMMAND openresty)
if [[ ${OPENRESTY_EXISTS} = "FAIL" ]]; then
    INSTALL_OPENRESTY
fi

FPM_EXISTS=$(CHECK_COMMAND fpm)
if [[ ${FPM_EXISTS} = "FAIL" ]]; then
    INSTALL_FPM
fi

git clone -b v${VERSION} https://github.com/apioak/apioak.git
cd apioak
sudo luarocks install rockspec/apioak-master-0.rockspec --tree=deps --only-deps --local

wget https://github.com/apioak/dashboard/releases/download/v${VERSION}/dashboard-${VERSION}.tar.gz
tar -zxvf dashboard-${VERSION}.tar.gz
rm -f dashboard-${VERSION}.tar.gz

sudo mkdir -p /tmp/apioak/usr/local/apioak
sudo mkdir -p /tmp/apioak/usr/bin

chown -R root.root apioak bin conf logs dashboard COPYRIGHT README.md README_CN.md
chmod -R 755 apioak bin conf logs dashboard COPYRIGHT README.md README_CN.md

cp -rf apioak bin conf logs dashboard COPYRIGHT README.md README_CN.md /tmp/apioak/usr/local/apioak/
cp -rf bin/apioak /tmp/apioak/usr/bin/

fpm -f -s dir -t deb -n apioak \
    -m 'Janko <shuaijinchao@gmail.com>' \
    -v ${VERSION} \
    --iteration ${ITERATION} \
    --description 'APIOAK is complete lifecycle management API gateway.' \
    --license "Apache License 2.0"  \
    -C /tmp/apioak \
    -p ${PWD} \
    --url 'https://apioak.com' \
    --deb-no-default-config-files \
    -d 'openresty >= 1.15.8.2' \
    -d 'luarocks >= 2.3.0'
