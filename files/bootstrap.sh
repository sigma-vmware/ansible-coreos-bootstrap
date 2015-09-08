#/bin/bash

set -e

cd

if [[ -e $PKG_HOME/.bootstrapped ]]; then
  exit 0
fi

mkdir -p `dirname "$PYPY_HOME"`
wget -O - "$PYPY_DOWNLOAD_URL/pypy-$PYPY_VERSION-linux64.tar.bz2" |tar -xjf -
mv -n "pypy-$PYPY_VERSION-linux64" "$PYPY_HOME"

## library fixup
mkdir -p "$PYPY_HOME/lib"

CURSES_LIB=/lib64/libncurses.so.5.9
if [ -e "$CURSES_LIB" ]; then
    ln -snf "$CURSES_LIB" "$PYPY_HOME/lib/libtinfo.so.5"
fi

mkdir -p "$PKG_HOME/bin"

cat > "$PKG_HOME/bin/python" <<EOF
#!/bin/bash
LD_LIBRARY_PATH="$PYPY_HOME/lib:\$LD_LIBRARY_PATH" exec "$PYPY_HOME/bin/pypy" "\$@"
EOF

cat > "$PKG_HOME/bin/pip" <<EOF
#!/bin/bash
LD_LIBRARY_PATH="$PYPY_HOME/lib:\$LD_LIBRARY_PATH" exec "$PYPY_HOME/bin/pip" "\$@"
EOF

chmod +x "$PKG_HOME/bin/python"
chmod +x "$PKG_HOME/bin/pip"

"$PKG_HOME/bin/python" --version

touch "$PKG_HOME/.bootstrapped"
