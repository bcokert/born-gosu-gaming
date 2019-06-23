#! /bin/bash
# Run this on server to build a new release and prepare it to run, after running scripts/deploy-source

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

cp -r _build/prod/rel/born_gosu_gaming ${RELEASE_DIR}

${RELEASE_DIR}/bin/born_gosu_gaming start
