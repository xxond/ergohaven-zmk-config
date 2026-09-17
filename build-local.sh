#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
mkdir -p "$repo_dir/build/.work"

docker run --rm \
  --mount "type=bind,src=$repo_dir/config,dst=/config,readonly" \
  --mount "type=bind,src=$repo_dir/build/.work,dst=/work" \
  --mount "type=bind,src=$repo_dir/build,dst=/output" \
  --workdir /work \
  zmkfirmware/zmk-build-arm:stable bash -euc '
    git config --global http.lowSpeedLimit 1
    git config --global http.lowSpeedTime 30
    mkdir -p /work/config
    cp -r /config/. /work/config/
    if [ ! -d /work/.west ]; then
      west init -l /work/config
    fi
    west update --narrow -o=--depth=1
    west zephyr-export
    west build -p auto -s zmk/app -d /work/build-left -b ergohaven -S studio-rpc-usb-uart -- \
      -DZMK_CONFIG=/work/config \
      -DSHIELD=k03_left \
      -DCONFIG_ZMK_STUDIO=y
    cp /work/build-left/zephyr/zmk.uf2 /output/k03_left-ergohaven-zmk.uf2
    sha256sum /output/k03_left-ergohaven-zmk.uf2
  '
