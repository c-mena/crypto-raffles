#!/bin/bash

if ! command -v curl &>/dev/null; then
  echo "Installing curl..."
  sudo apt update && sudo apt install curl -y
fi

if ! command -v node &> /dev/null; then
  echo "Error: Node.js is not installed. It is required by mops. Install Node.js and run the script again."
  exit 1
fi

if ! command -v dfx &>/dev/null; then
  echo "Installing IC SDK..."  # https://internetcomputer.org/docs/building-apps/getting-started/install
  sh -ci "$(curl -fsSL https://internetcomputer.org/install.sh)"
  source "$HOME/.bashrc" # Load SDK environment in current shell
fi
echo "IC SDK is installed (version: $(dfx --version))."

if [ ! -d "./.mops" ]; then
  echo "Installing mops..."
  curl -fsSL cli.mops.one/install.sh | sh
  mops init
  mops install
fi
mops -v | awk '/^CLI/{cli=$2} /^API/{api=$2; printf "mops is installed (version: CLI %s, API %s).\n", cli, api}'