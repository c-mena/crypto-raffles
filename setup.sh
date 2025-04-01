#!/bin/bash

if ! command -v curl &>/dev/null; then
  echo "Installing curl..."
  sudo apt update && sudo apt install curl -y
fi

if ! command -v dfx &>/dev/null; then
  echo "Installing IC SDK..."
  sh -ci "$(curl -fsSL https://internetcomputer.org/install.sh)"
  source "$HOME/.bashrc" # Load SDK environment in current shell
fi
echo "IC SDK is installed (versión: $(dfx --version))."

if ! command -v node &> /dev/null; then
  echo "Error: Node.js is not installed. Install it and run the script again."
  exit 1
fi

if [ ! -d "./.mops" ]; then
  echo "Installing mops..."
  curl -fsSL cli.mops.one/install.sh | sh
  mops init
  mops install
fi


