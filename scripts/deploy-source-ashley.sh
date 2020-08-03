#! /bin/bash
# Run this on a dev server that already has secrets available and deploy keys available

HOST="$1"
if [ "$1" == "" ]; then
    echo -e "You need to provide a host name or ip to deploy source: './scripts/deploy-source-ashley.sh borngosugaming.com'"
    exit 1
fi

ROOT_DIR="/tmp/born-gosu-gaming"
ASHLEY_DIR="/tmp/born-gosu-gaming/ashley"

echo -e "Cloning a fresh Ashley"
rm -rf ${ASHLEY_DIR}
git clone git@github.com:AshenKyle/bg-ctl-helper.git ${ASHLEY_DIR}

echo -e "Ensuring fresh secrets"
pushd ${ASHLEY_DIR}
npm run decrypt-secrets
popd

echo -e "Moving files to server at '${HOST}'"
ssh root@${HOST} "rm -rf ${ASHLEY_DIR}; mkdir ${ASHLEY_DIR}"
scp -r ${ASHLEY_DIR} root@${HOST}:${ROOT_DIR}
