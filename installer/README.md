# Installers

The release archives put these launchers at the top level of the package:

| Folder | Platform | Launchers |
|---|---|---|
| `windows/launchers/` | Windows (PowerShell, `windows/simscraft.ps1`) | `install.bat`, `update.bat`, `collect-logs.bat` |
| `unix/launchers-macos/` | macOS (`unix/simscraft.sh`) | `Install SimsCraft.command`, `Update SimsCraft.command`, `Collect logs.command` |
| `unix/launchers-linux/` | Linux (`unix/simscraft.sh`) | `install.sh`, `update.sh`, `collect-logs.sh` |

From a git checkout you can run the scripts directly:

```bash
installer/unix/simscraft.sh install|update|logs                    # macOS / Linux
powershell -ExecutionPolicy Bypass -File installer\windows\simscraft.ps1 install   # Windows
```

Environment variables: `SIMSCRAFT_DIR` — server folder (default `~/AzerothCore-SimsCraft`), `SIMSCRAFT_LANG` — `en` or `ru`.
