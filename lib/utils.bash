#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
set -euo pipefail

TOOL_NAME="mysql"
BINARY_NAME="mysql"

fail() { echo -e "\e[31mFail:\e[m $*" >&2; exit 1; }

get_platform() {
  case "$(uname -s)" in
    Darwin) echo "macos" ;;
    Linux) echo "linux-glibc" ;;
    *) fail "Unsupported OS" ;;
  esac
}

get_arch() {
  case "$(uname -m)" in
    x86_64|amd64) echo "x86_64" ;;
    aarch64|arm64) echo "arm64" ;;
    *) fail "Unsupported arch" ;;
  esac
}

list_all_versions() {
  local curl_opts=(-sL)
  [[ -n "${GITHUB_TOKEN:-}" ]] && curl_opts+=(-H "Authorization: token $GITHUB_TOKEN")
  curl "${curl_opts[@]}" "https://api.github.com/repos/mysql/mysql-server/tags" 2>/dev/null | \
    grep -o '"name": "mysql-[^"]*"' | sed 's/"name": "mysql-//' | sed 's/"$//' | sort -V
}

download_release() {
  local version="$1" download_path="$2"
  local os="$(get_platform)" arch="$(get_arch)"
  local url="https://dev.mysql.com/get/Downloads/MySQL-${version%.*}/mysql-${version}-${os}2.4-${arch}.tar.xz"

  echo "Downloading MySQL $version..."
  mkdir -p "$download_path"
  curl -fsSL "$url" -o "$download_path/mysql.tar.xz" || fail "Download failed"
  tar -xJf "$download_path/mysql.tar.xz" -C "$download_path" --strip-components=1
  rm -f "$download_path/mysql.tar.xz"
}

install_version() {
  local install_type="$1" version="$2" install_path="$3"
  cp -r "$ASDF_DOWNLOAD_PATH"/* "$install_path/"
  chmod +x "$install_path/bin/"* 2>/dev/null || true
}
