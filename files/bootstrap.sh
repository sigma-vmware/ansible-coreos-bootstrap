#!/bin/bash

set -e
set -x

cd

mkdir -p `dirname "$PYPY_HOME"`
wget -O - "$PYPY_DOWNLOAD_URL/pypy-$PYPY_VERSION-$PYPY_FLAVOR.tar.bz2" |tar -xjf -

rm -rf "$PYPY_INSTALL"
mv -n "pypy-$PYPY_VERSION-$PYPY_FLAVOR" "$PYPY_INSTALL"

rm -rf "$PYPY_HOME"
"$PYPY_INSTALL/bin/pypy" "$PYPY_INSTALL/bin/virtualenv-pypy" "$PYPY_HOME"

mkdir -p "$PKG_HOME/bin"

ln -sf "$PYPY_HOME/bin/python" "$PKG_HOME/bin/python"
ln -sf "$PYPY_HOME/bin/pip" "$PKG_HOME/bin/pip"

FACTSD="/etc/ansible/facts.d"
sudo mkdir -p "$FACTSD"
sudo chown core "$FACTSD"

cat > "$FACTSD/bootstrap.fact" <<EOF
[pypy]
version=$PYPY_VERSION
EOF
