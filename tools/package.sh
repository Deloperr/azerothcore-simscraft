#!/bin/bash
# Builds release archives: dist/SimsCraft-<ver>-windows.zip, -macos.zip, -linux.tar.gz
# Собирает архивы релиза для трёх платформ.
set -e
cd "$(dirname "$0")/.."
VER="${1:-1.0.0}"
rm -rf dist && mkdir -p dist
common() {
    local d="$1"
    mkdir -p "$d/server" "$d/client" "$d/docs" "$d/installer"
    cp -R server/lua_scripts server/sql "$d/server/"
    cp -R client/Interface "$d/client/"
    cp README.md README.ru.md LICENSE CHANGELOG.md "$d/"
    cp docs/INSTALL.md docs/INSTALL.ru.md "$d/docs/"
    find "$d" -name '.DS_Store' -delete
}
# Windows
W="dist/SimsCraft-$VER-windows"; common "$W"
mkdir -p "$W/installer/windows"; cp installer/windows/simscraft.ps1 "$W/installer/windows/"
cp installer/windows/launchers/*.bat "$W/"
# macOS
M="dist/SimsCraft-$VER-macos"; common "$M"
mkdir -p "$M/installer/unix"; cp installer/unix/simscraft.sh "$M/installer/unix/"
cp installer/unix/launchers-macos/*.command "$M/"; chmod +x "$M"/*.command "$M/installer/unix/simscraft.sh"
# Linux
L="dist/SimsCraft-$VER-linux"; common "$L"
mkdir -p "$L/installer/unix"; cp installer/unix/simscraft.sh "$L/installer/unix/"
cp installer/unix/launchers-linux/*.sh "$L/"; chmod +x "$L"/*.sh "$L/installer/unix/simscraft.sh"
# Windows files with CRLF
for f in "$W"/*.bat "$W/installer/windows/simscraft.ps1"; do python3 - "$f" <<'PY'
import sys; p = sys.argv[1]; b = open(p, 'rb').read().replace(b'\r\n', b'\n').replace(b'\n', b'\r\n'); open(p, 'wb').write(b)
PY
done
(cd dist && zip -qr -X "SimsCraft-$VER-windows.zip" "SimsCraft-$VER-windows" && zip -qr -X "SimsCraft-$VER-macos.zip" "SimsCraft-$VER-macos" \
    && tar czf "SimsCraft-$VER-linux.tar.gz" --owner=0 --group=0 "SimsCraft-$VER-linux")
(cd dist && sha256sum SimsCraft-$VER-* 2>/dev/null | grep -v '/$' > SHA256SUMS.txt || true)
ls -la dist
