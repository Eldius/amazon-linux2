#!/bin/bash

VM='AMZN2-test'
AWS_VDI=${PWD}/images/amzn2-virtualbox.vdi
VERSION=2.0.20190115
VDI_LINK="https://cdn.amazonlinux.com/os-images/2.0.20190115/virtualbox/amzn2-virtualbox-2.0.20190115-x86_64.xfs.gpt.vdi"

function clean {
    echo ""
    echo "Cleaning old work files..."
    echo ""

    VBoxManage controlvm $VM poweroff
    sleep 10s
    VBoxManage unregistervm $VM --delete
    sleep 10s

    rm -rf build
    mkdir build

    echo ""
    echo "Old work files cleaned."
    echo ""
}

clean
