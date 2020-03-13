#! /bin/bash
# Run this on server to build a new release and prepare it to run, after running scripts/deploy-source-alfred

BUILD_DIR="/tmp/born-gosu-gaming/build"
ASHLEY_DIR="/tmp/born-gosu-gaming/ashley"
RELEASE_ASHLEY_DIR="/var/born-gosu-gaming/ashley"

if [ -d ${RELEASE_ASHLEY_DIR} ]; then
    systemctl stop ashley
    systemctl stop ashleyprime
fi

cd ${ASHLEY_DIR}
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm use 11.10.0
npm install

rm -rf ${RELEASE_ASHLEY_DIR}
cp -r ${ASHLEY_DIR} ${RELEASE_ASHLEY_DIR}
rm -rf /lib/systemd/system/ashley.service
rm -rf /lib/systemd/system/ashleyprime.service
cp ${BUILD_DIR}/config/secret/prod/ashley.service /lib/systemd/system/ashley.service
cp ${BUILD_DIR}/config/secret/prod/ashleyprime.service /lib/systemd/system/ashleyprime.service
systemctl daemon-reload

systemctl start ashley
systemctl start ashleyprime
