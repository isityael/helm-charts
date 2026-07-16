#!/bin/sh
set -eu

version="1.3.3"
install_dir="${ORAS_INSTALL_DIR:-/tmp/oras-bin}"

case "$(uname -m)" in
  x86_64|amd64)
    arch="amd64"
    checksum="9ce999f8d2de03fc03968b29d743077a58783e545e5eaa53917ca177352d0e59"
    ;;
  aarch64|arm64)
    arch="arm64"
    checksum="ac7156f93a21e903f7ad606c792f3560f17e0cd0e36365634701b1e7cc4e4eca"
    ;;
  *)
    echo "Unsupported runner architecture: $(uname -m)" >&2
    exit 1
    ;;
esac

archive="oras_${version}_linux_${arch}.tar.gz"
archive_path="${install_dir}/${archive}"
mkdir -p "$install_dir"
download_url="https://github.com/oras-project/oras/releases/download/v${version}/${archive}"
if command -v curl >/dev/null 2>&1; then
  curl --fail --location --silent --show-error "$download_url" --output "$archive_path"
elif command -v wget >/dev/null 2>&1; then
  wget -qO "$archive_path" "$download_url"
else
  echo "curl or wget is required to download oras." >&2
  exit 1
fi
printf '%s  %s\n' "$checksum" "$archive_path" | sha256sum -c
tar -xzf "$archive_path" -C "$install_dir" oras
"${install_dir}/oras" version
