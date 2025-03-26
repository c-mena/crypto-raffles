#!/bin/bash
rm -rf .dfx .mops 
rm mops.toml
mops init
mops add base
mops add map
mops add datetime
mops install