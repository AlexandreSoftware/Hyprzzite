#!/bin/bash
# build.sh — desktop image entry point (thin wrapper)

set -ouex pipefail

/ctx/build-common.sh
/ctx/build-desktop.sh
