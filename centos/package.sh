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
    wget http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    sudo rpm -ivh epel-release-latest-7.noarch.rpm
    sudo yum -y install luarocks
    sudo rm -f epel-release-latest-7.noarch.rpm
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

    fpm -f -s dir -t rpm -n apioak \
        -m 'Janko <shuaijinchao@gmail.com>' \
        -v ${VERSION} \
        --iteration ${ITERATION}.el7 \
        --description 'APIOAK provides full life cycle management of API release, management, and operation and maintenance.' \
        --license "Apache License 2.0"  \
        -C /tmp/apioak \
        -p ${ABS_PATH} \
        --url 'https://apioak.com' \
        -d 'openresty >= 1.15.8.1' \
        -d 'etcd >= 3.2.2' \
        -d 'luarocks >= 2.2.2'

    REMOVE_CACHE_PATH ${ABS_PATH}
}
