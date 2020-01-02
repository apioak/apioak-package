#!/usr/bin/env bash

BUILD_VERSION=$1
BUILD_ITERATION=$2
SYSTEM_NAME=$(lsb_release -is)

set -e

source /etc/profile

if [[ ${SYSTEM_NAME} = "CentOS" ]]; then
    echo "Build APIOAK System : ${SYSTEM_NAME}"
    . centos/package.sh
elif [[ ${SYSTEM_NAME} = "Ubuntu" ]]; then
    echo "Build APIOAK System : ${SYSTEM_NAME}"
    . ubuntu/package.sh
else
    echo "Build System Invalid, Only CentOS and Ubuntu are supported"
    exit 1
fi


if [[ ${BUILD_VERSION} =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]; then
    echo "Build APIOAK Version: v${BUILD_VERSION}"
else
    echo "Build Version Invalid, Example: run.sh 0.1.0"
    exit 1
fi


if [[ ${BUILD_ITERATION} = "" ]]; then
    BUILD_ITERATION=1
fi


INSTALL_BASE_TOOLS


FPM_EXISTS=$(CHECK_COMMAND fpm)
if [[ ${FPM_EXISTS} = "FAIL" ]]; then
    INSTALL_FPM
fi


OPENRESTY_EXISTS=$(CHECK_COMMAND openresty)
if [[ ${OPENRESTY_EXISTS} = "FAIL" ]]; then
    INSTALL_OPENRESTY
fi


LUAROCKS_EXISTS=$(CHECK_COMMAND luarocks)
if [[ ${LUAROCKS_EXISTS} = "FAIL" ]]; then
    INSTALL_LUAROCKS
fi


BUILD_PACKAGE ${BUILD_VERSION} ${BUILD_ITERATION}
