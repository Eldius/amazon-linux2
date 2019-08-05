#!/bin/bash

VM='AMZN2-test'
AWS_VDI=${PWD}/images/amzn2-virtualbox.vdi
VERSION=2.0.20190115
VDI_LINK="https://cdn.amazonlinux.com/os-images/2.0.20190115/virtualbox/amzn2-virtualbox-2.0.20190115-x86_64.xfs.gpt.vdi"

#VBoxManage controlvm $VM poweroff
#sleep 10
##VBoxManage startvm $VM --type headless 
#VBoxManage startvm $VM

function wait_boot_finishes {
    STATE=$( ssh -i build/insecure_key vagrant@localhost -p 9999 -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -o "ConnectTimeout=3" ls -la )

    while [ $? -ne 0 ]
    do
        echo "waiting..."
        sleep 10
        STATE=$( ssh -i build/insecure_key vagrant@localhost -p 9999 -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -o "ConnectTimeout=3" ls -la )
    done
}

wait_boot_finishes

ssh -i build/insecure_key vagrant@localhost -p 9999 -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -o "ConnectTimeout=3" << SSH
    echo "----------------"
    echo "[AGAIN] TESTING VBOX GUEST ADDITIONS PRESENCE"
    echo "test result: \$( lsmod | grep vboxguest )"
    echo "----------------"
SSH

notify-send --urgency=low "hey you!" "take a look..."
