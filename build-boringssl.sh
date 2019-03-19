#!/bin/sh
# WARN: This script need to run as root!
. ./versions.sh

# preparation
mkdir -p /root/build
cd /root/build
yum update -y
yum groupinstall "Development Tools" -y
yum install git patch wget pcre pcre-devel zlib zlib-devel libxml2 libxml2-devel libxslt-devel gd gd-devel libatomic_ops-devel -y

# fetch patch
cd /root/build
mkdir patch
pushd patch
wget https://raw.githubusercontent.com/hakasenyang/openssl-patch/master/nginx_strict-sni.patch
popd

# openssl upgrade -step1: fetch source
wget https://www.openssl.org/source/openssl-${openssl_ver}.tar.gz
tar -zxvf openssl-${openssl_ver}.tar.gz
rm -rf openssl-${openssl_ver}.tar.gz

# step2: build
pushd openssl-${openssl_ver}
./config --prefix=/usr/local/openssl
make -j$(nproc) && make install
popd

# step3: replace old version
mv /usr/bin/openssl /usr/bin/openssl.old
mv /usr/lib64/openssl /usr/lib64/openssl.old
mv /usr/lib64/libssl.so /usr/lib64/libssl.so.old
ln -s /usr/local/openssl/bin/openssl /usr/bin/openssl
ln -s /usr/local/openssl/include/openssl /usr/include/openssl
ln -s /usr/local/openssl/lib/libssl.so /usr/lib64/libssl.so
echo "/usr/local/openssl/lib" >> /etc/ld.so.conf
ldconfig -v

# step4: clean
rm -rf openssl-${openssl_ver}

# ngx_brotli_module
git clone https://github.com/google/ngx_brotli.git
pushd ngx_brotli
git submodule update --init
popd

# zlib
git clone https://github.com/cloudflare/zlib.git
pushd zlib
./configure
popd

# ndk
wget https://github.com/simplresty/ngx_devel_kit/archive/v${ndk_ver}.tar.gz
tar -zxvf v${ndk_ver}.tar.gz
rm -rf v${ndk_ver}.tar.gz

# ngx_more_headers
git clone https://github.com/openresty/headers-more-nginx-module.git

# ngx_lua_module
wget https://github.com/openresty/lua-nginx-module/archive/v${ngx_lua_ver}.tar.gz
tar -zxvf v${ngx_lua_ver}.tar.gz
rm -rf v${ngx_lua_ver}.tar.gz

# luajit2
wget https://github.com/openresty/luajit2/archive/v${luajit_ver}.tar.gz
tar -zxvf v${luajit_ver}.tar.gz
pushd luajit2-${luajit_ver}
make -j$(nproc) && make install
popd
export LUAJIT_LIB=/usr/local/lib
export LUAJIT_INC=/usr/local/include/luajit-2.1

# pcre
wget https://ftp.pcre.org/pub/pcre/pcre-${pcre_ver}.tar.gz
tar -zxvf pcre-${pcre_ver}.tar.gz
rm -rf pcre-${pcre_ver}.tar.gz

# cache_purge_module
wget https://github.com/FRiCKLE/ngx_cache_purge/archive/${cache_ver}.tar.gz
tar -zxvf ${cache_ver}.tar.gz
rm -rf ${cache_ver}.tar.gz

# boringssl
git clone https://boringssl.googlesource.com/boringssl
cd boringssl
mkdir build && cd build && make -j$(nproc) ../ && make -j$(nproc) && cd ../
mkdir -p .openssl/lib && cd .openssl && ln -s ../include . && cd ../
cp build/crypto/libcrypto.a build/ssl/libssl.a .openssl/lib
cd ../

# nginx
wget https://athena.ifreetion.com/Sources/nginx/nginx-${ngx_ver}.tar.gz
tar -zxvf nginx-${ngx_ver}.tar.gz
pushd nginx-${ngx_ver}
touch ../boringssl/.openssl/include/openssl/ssl.h
patch -p1 < ../patch/nginx_strict-sni.patch
./configure \
--prefix=/etc/nginx \
--sbin-path=/usr/sbin/nginx \
--modules-path=/usr/lib64/nginx/modules \
--conf-path=/etc/nginx/nginx.conf \
--error-log-path=/var/log/nginx/error.log \
--http-log-path=/var/log/nginx/access.log \
--pid-path=/var/run/nginx.pid \
--lock-path=/var/run/nginx.lock \
--http-client-body-temp-path=/var/cache/nginx/client_temp \
--http-proxy-temp-path=/var/cache/nginx/proxy_temp \
--http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
--http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
--http-scgi-temp-path=/var/cache/nginx/scgi_temp \
--user=nginx \
--group=nginx \
--with-compat \
--with-file-aio \
--with-threads \
--with-http_addition_module \
--with-http_auth_request_module \
--with-http_dav_module \
--with-http_flv_module \
--with-http_gunzip_module \
--with-http_gzip_static_module \
--with-http_mp4_module \
--with-http_random_index_module \
--with-http_realip_module \
--with-http_secure_link_module \
--with-http_slice_module \
--with-http_ssl_module \
--with-http_stub_status_module \
--with-http_sub_module \
--with-http_v2_module \
--with-http_xslt_module \
--with-http_image_filter_module \
--with-http_degradation_module \
--with-select_module \
--with-poll_module \
--with-mail \
--with-mail_ssl_module \
--with-stream \
--with-stream_realip_module \
--with-stream_ssl_module \
--with-stream_ssl_preread_module \
--with-libatomic \
--with-ld-opt=-Wl,-rpath,/usr/local/lib \
--add-module=../ngx_brotli \
--add-module=../ngx_devel_kit-${ndk_ver} \
--add-module=../headers-more-nginx-module \
--add-module=../lua-nginx-module-${ngx_lua_ver} \
--add-module=../ngx_cache_purge-${cache_ver} \
--with-pcre=../pcre-${pcre_ver} \
--with-zlib=../zlib \
--with-openssl=../boringssl

make -j$(nproc)
chmod -R 777 *
openssl version
./objs/nginx -v && ./objs/nginx -V
popd
