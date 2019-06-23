#! /bin/bash
# Run this on a server to provision it, after running scripts/deploy-source
# This only needs to be done once in a while per server

ROOT_DIR="/tmp/born-gosu-gaming"

if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install git
else
    apt-get update
    apt-get -y install git
fi

if [ ! -d ${ROOT_DIR}/asdf ]; then
    git clone https://github.com/asdf-vm/asdf.git ${ROOT_DIR}/asdf --branch v0.7.2
fi

if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install autoconf
    brew install automake libtool openssl wxmac
    brew install libtool openssl wxmac
    brew install openssl
else
    # Erlang Deps
    apt-get -y install build-essential
    apt-get -y install autoconf
    apt-get -y install m4
    apt-get -y install libncurses5-dev
    apt-get -y install libssh-dev

    # Elixir Deps
    apt-get install unzip
fi

source ${ROOT_DIR}/asdf/asdf.sh

asdf plugin-add elixir
asdf plugin-add erlang

asdf install erlang 21.1
asdf global erlang 21.1

asdf install elixir 1.8.2
asdf global elixir 1.8.2

mkdir -p /var/born-gosu-gaming/db
