#/bin/bash

if [ ! -f /usr/lib64/libdl.a ]; then
    echo "cannot find /usr/lib64/libdl.a"
    echo "you need to install glibc-static"
    echo "for centos, try: yum -y install glibc-static"
    exit 1
fi

HAPROXY_SRC=haproxy-1.6.9
ZLIB_SRC=zlib-1.2.8
OPENSSL_SRC=openssl-OpenSSL_1_0_2h
PCRE_SRC=pcre-8.38
rm -rf $HAPROXY_SRC
rm -rf $ZLIB_SRC
rm -rf $OPENSSL_SRC
rm -rf $PCRE_SRC

CWD=`pwd`

HAPROXY_BIN=$CWD/haproxy_bin
ZLIB_BIN=$CWD/zlib_bin
OPENSSL_BIN=$CWD/openssl_bin
PCRE_BIN=$CWD/pcre_bin
rm -rf $HAPROXY_BIN
rm -rf $ZLIB_BIN
rm -rf $OPENSSL_BIN
rm -rf $PCRE_BIN

mkdir -p $HAPROXY_BIN
mkdir -p $ZLIB_BIN
mkdir -p $OPENSSL_BIN
mkdir -p $PCRE_BIN

set -e
tar xzf haproxy-1.6.9.tar.gz
tar xzf zlib-1.2.8.tar.gz
tar xzf OpenSSL_1_0_2h.tar.gz
tar xjf pcre-8.38.tar.bz2
set +e

# build openssl
cd $OPENSSL_SRC
./config --prefix=$OPENSSL_BIN no-shared no-ssl2
make && make install_sw
cd -

# build pcre
cd $PCRE_SRC
CFLAGS='-O2 -Wall' ./configure --prefix=$PCRE_BIN --disable-shared
make && make install
cd -

# build zlib
cd $ZLIB_SRC
./configure --static --prefix=$ZLIB_BIN
make && make install
cd -

cd $HAPROXY_SRC
patch -p1 < ../haproxy.patch

make LDFLAGS=-static TARGET=linux2628 USE_STATIC_PCRE=1 USE_ZLIB=1 USE_OPENSSL=1 ZLIB_LIB=$ZLIB_BIN/lib ZLIB_INC=$ZLIB_BIN/include SSL_INC=$OPENSSL_BIN/include SSL_LIB=$OPENSSL_BIN/lib ADDLIB=-ldl -lzlib PCREDIR=$PCRE_BIN USE_LIBCRYPT= USE_CRYPT_H=
make install PREFIX=$HAPROXY_BIN
cd -

echo "haproxy is statically built at $HAPROXY_BIN/sbin/haproxy"
