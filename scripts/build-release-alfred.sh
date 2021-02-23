#! /bin/bash
# Run this on server to build a new release and prepare it to run, after running scripts/deploy-source-alfred

ROOT_DIR="/tmp/born-gosu-gaming"
BUILD_DIR="/tmp/born-gosu-gaming/build"
RELEASE_DIR="/var/born-gosu-gaming/release"

if [ -d ${RELEASE_DIR} ]; then
    ${RELEASE_DIR}/bin/born_gosu_gaming stop
fi

source ${ROOT_DIR}/asdf/asdf.sh

cd ${BUILD_DIR}
mix local.hex --force
mix local.rebar --force
mix deps.get

MIX_ENV=prod mix release

rm -rf ${RELEASE_DIR}
cp -r _build/prod/rel/born_gosu_gaming ${RELEASE_DIR}

mkdir -p ${RELEASE_DIR}/log/
MIX_ENV=prod ${RELEASE_DIR}/bin/born_gosu_gaming start
