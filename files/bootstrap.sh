#!/bin/bash

set -e
set -x

if [[ `stat -c '%U' $PKG_HOME` != `whoami` ]]; then
    SUDO="sudo"
else
    SUDO=""
fi

PYPY_HOME="$PKG_HOME/pypy"
PYPY_INSTALL="$PKG_HOME/.pypy"

cd /tmp

FILENAME="pypy-$PYPY_VERSION-$PYPY_FLAVOR.tar.bz2"
curl -L -o "$FILENAME" "$PYPY_DOWNLOAD_URL/$FILENAME"

if [[ -n "$PYPY_SHA256" ]]; then
    echo "$PYPY_SHA256 $FILENAME" > "$FILENAME.sha256"
    sha256sum -c "$FILENAME.sha256"
fi

tar -xjf "$FILENAME"
rm -f "$FILENAME"

$SUDO rm -rf "$PYPY_INSTALL"
$SUDO mv -n "pypy-$PYPY_VERSION-$PYPY_FLAVOR" "$PYPY_INSTALL"

$SUDO mkdir -p `dirname "$PYPY_HOME"`
$SUDO rm -rf "$PYPY_HOME"

$SUDO "$PYPY_INSTALL/bin/pypy" "$PYPY_INSTALL/bin/virtualenv-pypy" "$PYPY_HOME"

$SUDO mkdir -p "$PKG_HOME/bin"

$SUDO ln -sf "$PYPY_HOME/bin/python" "$PKG_HOME/bin/python"
$SUDO ln -sf "$PYPY_HOME/bin/pip" "$PKG_HOME/bin/pip"

sudo mkdir -p "$ANSIBLE_FACTS_DIR"
sudo chown `whoami` "$ANSIBLE_FACTS_DIR"

PYPY_SSL_PATH=`$PYPY_INSTALL/bin/pypy -c 'from __future__ import print_function; import ssl; print(ssl.get_default_verify_paths().openssl_capath)'`

sudo mkdir -p `dirname $PYPY_SSL_PATH`
sudo ln -sf $COREOS_SSL_CERTS $PYPY_SSL_PATH

PIP_VERSION=`$PYPY_HOME/bin/pip --version | awk '{ print $2 }'`
WHEEL_VERSION=`$PYPY_HOME/bin/wheel version | awk '{ print $2 }'`

cat > "$ANSIBLE_FACTS_DIR/bootstrap.fact" <<EOF
[pypy]
version=$PYPY_VERSION
ssl_path=$PYPY_SSL_PATH

[pip]
version=$PIP_VERSION

[wheel]
version=$WHEEL_VERSION
EOF
