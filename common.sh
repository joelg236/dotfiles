#!/bin/env bash
set -euo pipefail

DOTFILES_DIR=$(realpath $(dirname "$0"))

PACKAGES=()

function include_pkg() {
  PACKAGES+=( $@ )
}

function bold_msg() {
  echo -e "\e[1m$1\e[0m"
}

function install_msg() {
  bold_msg "--- Installing $1 ---"
}

function install_packages() {
  list=${PACKAGES[@]}
  num=${#PACKAGES[@]}
  if [[ -n "${list}" ]]; then
    install_msg "$num packages: $list"
    sudo apt-get install -y $list --no-install-recommends
    PACKAGES=()
  fi
}

function install_snap() {
  pkgs=$@

  if binary_or_override snap; then
    include_pkg snapd
    install_packages

    sudo snap install core
  fi

  sudo snap install $pkgs
}

function binary_or_override() {
  binary_name=$1
  override_var_name=`echo ${2:-INSTALL_${binary_name^^}} | tr '-' '_'`

  if ! which $binary_name > /dev/null || [[ "${!override_var_name:-}" == "1" ]]; then
    return 0
  else
    return 1
  fi
}

function volta_component() {
  binary_name=$1

  if ! test -e $VOLTA_HOME/bin/$binary_name || ! $VOLTA_HOME/bin/$binary_name -v 2>&1 > /dev/null; then
    return 0
  else
    return 1
  fi
}

function final_steps() {
  install_packages # install any packages that were remaining
  sudo apt-get clean
  sudo apt-get -y autoremove
}

function setup_opt() {
  if [[ ! -e /opt/bin ]]; then
    sudo mkdir -p /opt/bin
  fi

  if [[ ! -w /opt ]]; then
    sudo chown -R $USER:$USER /opt
  fi

  if ! grep -q "/opt/bin" $HOME/.profile; then
    echo 'export PATH="/opt/bin:$PATH"' | tee -a $HOME/.profile
  fi
}


