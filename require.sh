#!/bin/sh
. ./versions.sh

# Preparation
yum install wget libffi* -y
yum groupinstall "Development Tools" -y
# yum install centos-release-scl -y
# yum install devtoolset-8 -y
# scl enable devtoolset-8 bash

# Download and install cmake
mkdir -p /opt/require/build
mkdir -p /opt/cmake
pushd /opt/require
wget https://github.com/Kitware/CMake/releases/download/v${cmake_ver}/cmake-${cmake_ver}-Linux-x86_64.sh
sh /opt/require/cmake-${cmake_ver}-Linux-x86_64.sh --prefix=/opt/cmake --exclude-subdir --skip-license
popd

# LLVM
cd /opt/require
wget http://releases.llvm.org/${llvm_ver}/llvm-${llvm_ver}.src.tar.xz
tar -Jxf llvm-${llvm_ver}.src.tar.xz
rm -rf llvm-${llvm_ver}.src.tar.xz
cd llvm-${llvm_ver}.src

# Clang
pushd tools
wget http://releases.llvm.org/${llvm_ver}/cfe-${llvm_ver}.src.tar.xz
tar -Jxf cfe-${llvm_ver}.src.tar.xz
rm -rf cfe-${llvm_ver}.src.tar.xz
mv cfe-${llvm_ver}.src clang
popd

# Clang-extra-tools
pushd tools/clang/tools
wget http://releases.llvm.org/${llvm_ver}/clang-tools-extra-${llvm_ver}.src.tar.xz
tar -Jxf clang-tools-extra-${llvm_ver}.src.tar.xz
rm -rf clang-tools-extra-${llvm_ver}.src.tar.xz
mv clang-tools-extra-${llvm_ver}.src extra
popd

# libc++
pushd projects
wget http://releases.llvm.org/${llvm_ver}/libcxx-${llvm_ver}.src.tar.xz
tar -Jxf libcxx-${llvm_ver}.src.tar.xz
rm -rf libcxx-${llvm_ver}.src.tar.xz
mv libcxx-${llvm_ver}.src libcxx
popd

# libc++ api
pushd projects
wget http://releases.llvm.org/${llvm_ver}/libcxxabi-${llvm_ver}.src.tar.xz
tar -Jxf libcxxabi-${llvm_ver}.src.tar.xz
rm -rf libcxxabi-${llvm_ver}.src.tar.xz
mv libcxxabi-${llvm_ver}.src libcxxabi
popd

# Compiler-rt
pushd projects
wget http://releases.llvm.org/${llvm_ver}/compiler-rt-${llvm_ver}.src.tar.xz
tar -Jxf compiler-rt-${llvm_ver}.src.tar.xz
rm -rf compiler-rt-${llvm_ver}.src.tar.xz
mv compiler-rt-${llvm_ver}.src compiler-rt
popd

cd ../build

/opt/cmake/bin/cmake -G "Unix Makefiles" ../llvm-${llvm_ver}.src \
  -DCMAKE_INSTALL_PREFIX=/opt/llvm  \
  -DCMAKE_BUILD_TYPE=Release \
  -DLLVM_ENABLE_FFI=ON \
  -DLLVM_BUILD_LLVM_DYLIB=ON \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
  -DLLVM_TARGETS_TO_BUILD="host" \
  -Wno-dev

make -j$(nproc) && make install