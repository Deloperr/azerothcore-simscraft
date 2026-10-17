#!/bin/bash
# SimsCraft for Linux: update
exec bash "$(cd "$(dirname "$0")" && pwd)/installer/unix/simscraft.sh" update "$@"
