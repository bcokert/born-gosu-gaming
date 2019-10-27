#! /bin/bash
# Run this on a server to provision it, after running scripts/deploy-source
# This only needs to be done once in a while per server

ROOT_DIR="/var/born-gosu-gaming"

if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install git
else
    apt-get update
    apt-get -y install git
fi

if [ ! -d ${ROOT_DIR}/asdf ]; then
    git clone https://github.com/asdf-vm/asdf.git ${ROOT_DIR}/asdf --branch v0.7.2
fi

# Node Deps
if command -v nvm; then
    curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash
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
    apt-get -y install curl
    apt-get -y install libssl-dev

    # Elixir Deps
    apt-get -y install unzip

    # Monitoring Deps
    apt-get -y install influxdb
fi

source ${ROOT_DIR}/asdf/asdf.sh

asdf plugin-add elixir
asdf plugin-add erlang

asdf install erlang 21.1
asdf global erlang 21.1

asdf install elixir 1.8.2
asdf global elixir 1.8.2

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install 11.10.0
nvm use 11.10.0
nvm alias default 11.10.0

if [[ "$OSTYPE" == "darwin"* ]]; then
    mkdir -p db
else
    mkdir -p ${ROOT_DIR}/db
fi
