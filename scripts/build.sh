#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
mkdir -p output/diagnostics

case "${1:-}" in
  prepare)
    [[ "${GITHUB_ACTIONS:-}" == true ]] || { echo 'prepare is only intended for an ephemeral GitHub runner'; exit 1; }
    # Remove preinstalled SDKs only on the disposable GitHub runner.
    sudo rm -rf /usr/share/dotnet /usr/local/lib/android /opt/ghc /opt/hostedtoolcache/CodeQL
    sudo apt-get update
    sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      build-essential clang flex bison g++ gawk gcc-multilib g++-multilib \
      gettext git libncurses-dev libssl-dev python3 python3-setuptools \
      python3-pyelftools rsync swig unzip zlib1g-dev file wget curl \
      ccache libelf-dev subversion time patch perl tar xz-utils zstd \
      device-tree-compiler u-boot-tools
    df -h
    available_kb="$(df -Pk "$ROOT" | awk 'NR==2 {print $4}')"
    (( available_kb >= 45 * 1024 * 1024 )) || { echo 'At least 45 GiB free disk space is required'; exit 1; }
    ;;
  configure)
    ref="${SOURCE_REF:-istoreos-24.10}"
    [[ "$ref" =~ ^[A-Za-z0-9][A-Za-z0-9._/-]*$ ]] && [[ "$ref" != *..* ]] || { echo 'Invalid source ref'; exit 1; }
    git init openwrt
    git -C openwrt remote add origin https://github.com/istoreos/istoreos.git
    git -C openwrt fetch --depth=1 origin "$ref"
    git -C openwrt checkout --detach FETCH_HEAD
    git -C openwrt rev-parse HEAD > output/diagnostics/source-commit.txt
    grep -q 'define Device/xunlong_orangepi-5-plus' openwrt/target/linux/rockchip/image/legacy.mk
    cd openwrt
    ./scripts/feeds update -a 2>&1 | tee "$ROOT/output/diagnostics/feeds-update.log"
    ./scripts/feeds install -a 2>&1 | tee "$ROOT/output/diagnostics/feeds-install.log"
    cp "$ROOT/config/seed.config" .config
    make defconfig 2>&1 | tee "$ROOT/output/diagnostics/configure.log"
    # Stop early if upstream changes cause a requested target/package to disappear.
    while IFS= read -r setting; do
      case "$setting" in
        CONFIG_TARGET_*=y|CONFIG_PACKAGE_*=y)
          grep -Fxq "$setting" .config || { echo "Required setting missing after defconfig: $setting"; exit 1; }
          ;;
      esac
    done < "$ROOT/config/seed.config"
    cp .config "$ROOT/output/diagnostics/resolved.config"
    ./scripts/diffconfig.sh > "$ROOT/output/diagnostics/diffconfig"
    for feed in feeds/*; do
      if [[ -d "$feed/.git" ]]; then printf '%s %s\n' "${feed##*/}" "$(git -C "$feed" rev-parse HEAD)"; fi
    done > "$ROOT/output/diagnostics/feed-commits.txt"
    {
      echo '### Build configuration'
      echo '- Device: Orange Pi 5 Plus (RK3588)'
      printf -- '- Official source ref: `%s`\n' "$ref"
      printf -- '- Source commit: `%s`\n' "$(git rev-parse HEAD)"
      echo '- Target: rockchip/armv8, xunlong_orangepi-5-plus'
    } >> "$GITHUB_STEP_SUMMARY"
    ;;
  download)
    cd openwrt
    make download -j8 2>&1 | tee "$ROOT/output/diagnostics/download.log" || \
      make download -j2 V=s 2>&1 | tee "$ROOT/output/diagnostics/download-retry.log"
    ;;
  compile)
    cd openwrt
    export CCACHE_MAXSIZE=2G
    # Keep two jobs at most on a small runner, and leave memory for the linker.
    jobs="$(nproc)"
    if (( $(awk '/MemTotal/ {print $2}' /proc/meminfo) < 12000000 )); then jobs=2; fi
    make -j"$jobs" 2>&1 | tee "$ROOT/output/diagnostics/compile.log" || \
      make -j1 V=s 2>&1 | tee "$ROOT/output/diagnostics/compile-retry.log"
    ;;
  collect)
    mkdir -p output/firmware
    target=openwrt/bin/targets/rockchip/armv8
    shopt -s nullglob
    images=("$target"/*xunlong_orangepi-5-plus*squashfs-sysupgrade.img.gz)
    (( ${#images[@]} == 1 )) || { echo "Expected exactly one Orange Pi 5 Plus firmware, found ${#images[@]}"; exit 1; }
    # OpenWrt appends upgrade metadata after the gzip stream. Strip it only
    # from the validation stream; keep the distributable image untouched.
    openwrt/staging_dir/host/bin/fwtool -T -i output/firmware/image-metadata.json "${images[0]}" | gzip -t
    cp "${images[0]}" output/firmware/
    for file in "$target"/*xunlong_orangepi-5-plus*.manifest "$target/profiles.json" "$target/config.buildinfo" "$target/feeds.buildinfo" "$target/version.buildinfo"; do
      if [[ -f "$file" ]]; then cp "$file" output/firmware/; fi
    done
    cp output/diagnostics/source-commit.txt output/diagnostics/feed-commits.txt output/diagnostics/diffconfig output/firmware/
    (cd output/firmware && sha256sum -- *.img.gz > sha256sums)
    {
      echo '### Firmware ready'
      printf -- '- Image: `%s`\n' "${images[0]##*/}"
      echo '- Download the iStoreOS-OrangePi5Plus artifact on this run page.'
      echo '- SHA256 checksums and source/feed commits are included.'
    } >> "$GITHUB_STEP_SUMMARY"
    ;;
  *) echo 'Usage: bash scripts/build.sh {prepare|configure|download|compile|collect}'; exit 2 ;;
esac
