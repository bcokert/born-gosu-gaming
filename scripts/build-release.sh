#! /bin/bash
# Run this on server to build a new release and prepare it to run, after running scripts/deploy-source

ROOT_DIR="/tmp/born-gosu-gaming"
BUILD_DIR="/tmp/born-gosu-gaming/build"
ASHLEY_DIR="/tmp/born-gosu-gaming/ashley"
RELEASE_DIR="/var/born-gosu-gaming/release"
RELEASE_ASHLEY_DIR="/var/born-gosu-gaming/ashley"

if [ -d ${RELEASE_DIR} ]; then
    ${RELEASE_DIR}/bin/born_gosu_gaming stop
fi
if [ -d ${RELEASE_ASHLEY_DIR} ]; then
    service stop ashley
fi

source ${ROOT_DIR}/asdf/asdf.sh

cd ${BUILD_DIR}
mix local.hex --force
mix local.rebar --force
mix deps.get

MIX_ENV=prod mix release

cp -r _build/prod/rel/born_gosu_gaming ${RELEASE_DIR}

cd ${ASHLEY_DIR}
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm use 11.10.0
npm install

cp -r ${ASHLEY_DIR} ${RELEASE_ASHLEY_DIR}
cp ${BUILD_DIR}/config/secret/prod/ashley.service /lib/systemd/system

rm -rf ${BUILD_DIR}
rm -rf ${RELEASE_DIR}
rm -rf ${RELEASE_ASHLEY_DIR}

MIX_ENV=prod ${RELEASE_DIR}/bin/born_gosu_gaming start
service start ashley
