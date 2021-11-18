#! /bin/bash
set -e
git submodule init
git submodule update
yarn install
yarn build
yarn server
