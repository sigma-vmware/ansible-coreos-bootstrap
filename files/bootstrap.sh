#!/bin/bash

set -e
set -x

if [[ `stat -c '%U' $PKG_HOME 2>/dev/null || echo root` != `whoami` ]]; then
    SUDO="sudo"
else
    SUDO=""
fi

PYPY_HOME="$PKG_HOME/pypy"
PYPY_INSTALL="$PKG_HOME/.pypy"

cd /tmp

FILENAME="pypy-$PYPY_VERSION-$PYPY_FLAVOR.tar.bz2"
curl --retry 5 -L -o "$FILENAME" "$PYPY_DOWNLOAD_URL/$FILENAME"

if [[ -n "$PYPY_SHA256" ]]; then
    echo "$PYPY_SHA256  $FILENAME" > "$FILENAME.sha256"
    sha256sum -c "$FILENAME.sha256"
fi

tar -xjf "$FILENAME"
rm -f "$FILENAME"

$SUDO mkdir -p "$PYPY_INSTALL"
$SUDO rm -rf "$PYPY_INSTALL"
$SUDO mv -n "pypy-$PYPY_VERSION-$PYPY_FLAVOR" "$PYPY_INSTALL"

# make sure PATH contains the location where pip, wheel and friends are
# so that ansible knows where to find them
# this is needed since ansible 2.1 changed the way ansible_python_interpreter
# is parsed
cat <<EOF > "$PYPY_INSTALL/site-packages/sitecustomize.py"
import os
import sys

os.environ["PATH"] += os.pathsep + os.path.sep.join([sys.prefix, "bin"])
EOF

$SUDO mkdir -p `dirname "$PYPY_HOME"`
$SUDO rm -rf "$PYPY_HOME"

$SUDO "$PYPY_INSTALL/bin/pypy" "$PYPY_INSTALL/bin/virtualenv-pypy" --system-site-packages "$PYPY_HOME"

$SUDO mkdir -p "$PKG_HOME/bin"

$SUDO ln -sf "$PYPY_HOME/bin/python" "$PKG_HOME/bin/python"
$SUDO ln -sf "$PYPY_HOME/bin/pip" "$PKG_HOME/bin/pip"
$SUDO ln -sf "$PYPY_HOME/bin/wheel" "$PKG_HOME/bin/wheel"

sudo mkdir -p "$ANSIBLE_FACTS_DIR"
sudo chown `whoami` "$ANSIBLE_FACTS_DIR"

PYPY_SSL_PATH=`$PYPY_INSTALL/bin/pypy -c 'from __future__ import print_function; import ssl; print(ssl.get_default_verify_paths().openssl_capath)'`

if [ $PYPY_SSL_PATH != "None" ]; then
    sudo mkdir -p `dirname $PYPY_SSL_PATH`
    sudo ln -sf $COREOS_SSL_CERTS $PYPY_SSL_PATH
fi

PIP_VERSION=`$PYPY_HOME/bin/pip --version | awk '{ print $2 }'`
WHEEL_VERSION=`$PYPY_HOME/bin/wheel version | awk '{ print $2 }'`

# install needed modules
$PYPY_HOME/bin/pip install docker-py

cat > "$ANSIBLE_FACTS_DIR/bootstrap.fact" <<EOF
[pypy]
version=$PYPY_VERSION
ssl_path=$PYPY_SSL_PATH

[pip]
version=$PIP_VERSION

[wheel]
version=$WHEEL_VERSION
EOF
