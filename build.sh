#!/bin/sh
# WARN: This script need to run as root!
. ./versions.sh

# preparation
yum install epel-release -y
yum groupinstall "Development Tools" -y
yum install git patch wget pcre pcre-devel zlib zlib-devel libxml2 libxml2-devel libunwind libunwind-devel libxslt libxslt-devel gd gd-devel libatomic_ops-devel GeoIP GeoIP-devel libmaxminddb libmaxminddb-devel -y

# nginx
wget https://nginx.org/download/nginx-${ngx_ver}.tar.gz
tar -zxvf nginx-${ngx_ver}.tar.gz
rm -rf nginx-${ngx_ver}.tar.gz
mv nginx-${ngx_ver} build
chmod 0755 * -R
cd build

# fetch openssl
mkdir deps
cd deps
wget https://www.openssl.org/source/openssl-${openssl_ver}.tar.gz
tar -zxvf openssl-${openssl_ver}.tar.gz
rm -rf openssl-${openssl_ver}.tar.gz

# ngx_brotli_module
git clone https://github.com/google/ngx_brotli.git
pushd ngx_brotli
git submodule update --init
popd

# ngx_more_headers
git clone https://github.com/openresty/headers-more-nginx-module.git

# geoip2_module
wget https://github.com/leev/ngx_http_geoip2_module/archive/refs/tags/${geoip2_ver}.tar.gz
tar -zxvf ${geoip2_ver}.tar.gz
rm -rf ${geoip2_ver}.tar.gz

# pcre
wget https://ftp.pcre.org/pub/pcre/pcre-${pcre_ver}.tar.gz
tar -zxvf pcre-${pcre_ver}.tar.gz
rm -rf pcre-${pcre_ver}.tar.gz

# zlib
git clone https://github.com/cloudflare/zlib.git
pushd zlib
./configure
popd

# compile
cd ..
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
--add-module=./deps/ngx_brotli \
--add-module=./deps/headers-more-nginx-module \
--add-module=./deps/ngx_http_geoip2_module-${geoip2_ver} \
--with-pcre=../pcre-${pcre_ver} \
--with-pcre-jit \
--with-zlib=./deps/zlib \
--with-openssl=./deps/openssl-${openssl_ver} \
--with-openssl-opt=enable-weak-ssl-ciphers

make -j$(nproc)
chmod -R 777 *
openssl version
./objs/nginx -v && ./objs/nginx -V
popd
