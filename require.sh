#!/bin/sh
. ./versions.sh

# Preparation
yum install wget libffi* -y
yum groupinstall "Development Tools" -y
yum install centos-release-scl -y
yum install llvm-toolset-7-clang* devtoolset-7-llvm*
scl enable devtoolset-7 bash && scl enable llvm-toolset-7 bash