#! /bin/bash
# Setups up a local asdf dev environment. Usually only needs to be run on development machines

BUILD_DIR=".asdf"

if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install git
else
    apt-get update
    apt-get -y install git
fi

if [ ! -d ${BUILD_DIR} ]; then
    git clone https://github.com/asdf-vm/asdf.git ${BUILD_DIR} --branch v0.7.2
fi

chmod a+x .asdf/asdf.sh
. ${BUILD_DIR}/asdf.sh

asdf plugin-add elixir
asdf plugin-add erlang

export KERL_CONFIGURE_OPTIONS="--without-javac --with-ssl=$(brew --prefix openssl)"
asdf install erlang 21.1
asdf install elixir 1.8.2

asdf global erlang 21.1
asdf global elixir 1.8.2

echo "You can now run \". ${BUILD_DIR}/asdf.sh\" in each shell you want to work in"

