#! /bin/bash
# Run this on server to build a new release and prepare it to run, after running scripts/deploy-source

SERVER_DIR="/var/born-gosu-gaming/release"

if [ -d ${SERVER_DIR} ]; then
    ${SERVER_DIR}/bin/born_gosu_gaming stop
fi

mix local.hex --force
mix local.rebar --force
mix deps.get

MIX_ENV=prod mix release
