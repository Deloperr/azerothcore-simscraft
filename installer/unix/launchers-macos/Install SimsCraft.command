#!/bin/bash
# SimsCraft: double-click to run. / Двойной щелчок для запуска.
exec bash "$(cd "$(dirname "$0")" && pwd)/installer/unix/simscraft.sh" install
