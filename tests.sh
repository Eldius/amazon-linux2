#!/bin/bash

VM='AMZN2-test'
AWS_VDI=${PWD}/images/amzn2-virtualbox.vdi
VERSION=2.0.20190115
VDI_LINK="https://cdn.amazonlinux.com/os-images/2.0.20190115/virtualbox/amzn2-virtualbox-2.0.20190115-x86_64.xfs.gpt.vdi"

#vagrant package --base $VM --output build/amazonlinux2.box

#vagrant cloud version create Eldius/linux-amzn2 $VERSION --description "Based on the image ${VERSION}. From ${VDI_LINK}"

vagrant cloud \
    publish \
    --version-description "Based on the image \`${VERSION}\`.\n From ${VDI_LINK}" \
    --force \
    --release \
    Eldius/linux-amzn2 \
    "$VERSION" \
    virtualbox \
    build/amazonlinux2.box

#vagrant cloud version release Eldius/linux-amzn2 $VERSION

notify-send --urgency=low "hey you!" "take a look..."
