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
    sudo yum -y install gcc \
                        gcc-c++ \
                        git \
                        make \
                        automake \
                        autoconf \
                        curl \
                        wget \
                        lua-devel \
                        libtool \
                        pcre-devel \
                        ruby \
                        ruby-devel \
                        rubygems \
                        rubygems-devel \
                        rpm-build \
                        libffi \
                        libffi-devel \
                        luarocks
}

INSTALL_FPM()
{
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

REMOVE_CACHE()
{
    sudo rm -rf /tmp/apioak
    sudo rm -rf ${PWD}/apioak
}

VERSION=$1
ITERATION=$2

if [[ ${VERSION} =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]; then
    echo "Build APIOAK Version: v${VERSION}"
else
    echo "Build Version Invalid, Example: ./build.sh 0.1.0"
    exit 1
fi

if [[ ${ITERATION} = "" ]]; then
    ITERATION=1
fi

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

chown -R root.root apioak bin conf logs deps dashboard COPYRIGHT README.md README_CN.md
chmod -R 755 apioak bin conf logs deps dashboard COPYRIGHT README.md README_CN.md

cp -rf apioak bin conf logs deps dashboard COPYRIGHT README.md README_CN.md /tmp/apioak/usr/local/apioak/
cp -rf bin/apioak /tmp/apioak/usr/bin/

fpm -f -s dir -t rpm -n apioak \
    -m 'Janko <shuaijinchao@gmail.com>' \
    -v ${VERSION} \
    --iteration ${ITERATION}.el7 \
    --description 'APIOAK is complete lifecycle management API gateway.' \
    --license "Apache License 2.0"  \
    -C /tmp/apioak \
    -p ${PWD} \
    --url 'https://apioak.com' \
    -d 'openresty >= 1.15.8.2' \
    -d 'luarocks >= 2.3.0'
