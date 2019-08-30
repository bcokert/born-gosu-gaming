#! /bin/bash
# Run this on a dev server that already has secrets available and deploy keys available

HOST="$1"
if [ "$1" == "" ]; then
    echo -e "You need to provide a host name or ip to deploy source: './scripts/deploy-source.sh borngosugaming.com'"
    exit 1
fi

ROOT_DIR="/tmp/born-gosu-gaming"
BUILD_DIR="/tmp/born-gosu-gaming/build"
ASHLEY_DIR="/tmp/born-gosu-gaming/ashley"

echo -e "Cloning a fresh Alfred"
rm -rf ${BUILD_DIR}
git clone git@github.com:bcokert/born-gosu-gaming.git ${BUILD_DIR}

echo -e "Cloning a fresh Ashley"
rm -rf ${ASHLEY_DIR}
git clone git@github.com:AshenKyle/bg-ctl-helper.git ${ASHLEY_DIR}

echo -e "Ensuring fresh secrets"
pushd ${BUILD_DIR}
${BUILD_DIR}/scripts/decrypt-secrets.sh
popd

echo -e "Moving files to server at '${HOST}'"
ssh root@${HOST} "rm -rf ${BUILD_DIR}; mkdir ${BUILD_DIR}"
scp -r ${BUILD_DIR} root@${HOST}:${ROOT_DIR}
scp -r ${ASHLEY_DIR} root@${HOST}:${ROOT_DIR}
