#!/bin/bash

# TODO ADD EXECUTION ERROR VALIDATIONS

VM='AMZN2-test'
AWS_VDI=${PWD}/images/amzn2-virtualbox.vdi
VERSION=2.0.20190115
VDI_LINK="https://cdn.amazonlinux.com/os-images/${VERSION}/virtualbox/amzn2-virtualbox-${VERSION}-x86_64.xfs.gpt.vdi"

function clean {
    #ssh-keygen -f "/home/eldius/.ssh/known_hosts" -R [localhost]:9999
    VBoxManage controlvm $VM poweroff
    sleep 10s
    VBoxManage unregistervm $VM --delete
    sleep 10s

    rm -rf build
    mkdir build

    wget \
        https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant \
        -O build/insecure_key
    chmod 600 build/insecure_key
}

function get_base_vdi {
    FILE=work/amazon_image.vdi
    if [ ! -f $FILE ]; then
        echo "amzn2-virtualbox-${VERSION}-x86_64.xfs.gpt" > .imageVersion
        ## CHANGE_HERE If you want to use a newer version of AWS provided base image
        wget \
            "$VDI_LINK" \
            -O work/amazon_image.vdi
    fi
    cp work/amazon_image.vdi $AWS_VDI
}

function generate_seed {
    genisoimage -input-charset utf-8 -output build/seed.iso -volid cidata -joliet -rock seedconfig/user-data seedconfig/meta-data
}

function create_machine {

    echo "#####################################"
    echo "#####################################"
    echo "Create VM '$VM'"
    echo ""

    VBoxManage createvm --name $VM --ostype "Linux_64" --register

    echo ""
    echo "#####################################"
    echo "#####################################"

    echo "#####################################"
    echo "#####################################"
    echo "Add Main Drive Media"
    echo ""

    VBoxManage storagectl $VM \
        --name "main_disk" \
        --add sata \
        --controller IntelAHCI


    VBoxManage storageattach $VM \
        --storagectl "main_disk" \
        --port 0 \
        --device 0 \
        --type hdd \
        --medium $AWS_VDI

    echo ""
    echo "#####################################"
    echo "#####################################"
    echo "Creating storage controller for DVD ROM"
    echo ""

    VBoxManage storagectl $VM \
        --name "cdrom" \
        --add ide

    echo ""
    echo "#####################################"
    echo "#####################################"

    echo ""
    echo "#####################################"
    echo "#####################################"
    echo "Add User Data Media"
    echo ""

    VBoxManage storageattach $VM \
        --storagectl "cdrom" \
        --port 0 \
        --device 0 \
        --type dvddrive \
        --medium ${PWD}/build/seed.iso

    echo ""
    echo "#####################################"
    echo "#####################################"

    echo "#####################################"
    echo "#####################################"
    echo "Configuring RAM and VRAM"
    echo ""

    VBoxManage modifyvm $VM --memory 1024 --vram 128

    echo ""
    echo "#####################################"
    echo "#####################################"

    echo "#####################################"
    echo "#####################################"
    echo "Configuring SSH port forward"
    echo ""

    VBoxManage modifyvm $VM --natpf1 "guestssh,tcp,,9999,,22"

    echo ""
    echo "#####################################"
    echo "#####################################"

}

function wait_boot_finishes {
    STATE=$(ssh -i build/insecure_key vagrant@localhost -p 9999 -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -o "ConnectTimeout=3" cat /home/vagrant/state_file)

    while [ "$STATE" != "FINISHED" ]
    do
        echo "waiting..."
        sleep 10
        STATE=$(ssh -i build/insecure_key vagrant@localhost -p 9999 -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -o "ConnectTimeout=3" cat /home/vagrant/state_file)
    done
}

function setup_guest_adition {
    echo "#####################################"
    echo "#####################################"
    echo "Add Guest Additions Media"
    echo ""

    VBoxManage storageattach $VM \
        --storagectl "cdrom" \
        --port 0 \
        --device 0 \
        --type dvddrive \
        --forceunmount \
        --medium /usr/share/virtualbox/VBoxGuestAdditions.iso

    echo ""
    echo "#####################################"
    echo "#####################################"

ssh -i build/insecure_key vagrant@localhost -p 9999 -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -o "ConnectTimeout=3" << SSH
    sudo yum update -y
    sudo mkdir -p /media/cdrom1
    sudo mount -t iso9660 -o ro /dev/sr0 /media/cdrom1
    cd /media/cdrom1/
    sudo ./VBoxLinuxAdditions.run
    sudo yum clean all
    sudo rm -rf /var/cache/yum
    sudo rm /home/vagrant/state_file
    cat /dev/null > ~/.bash_history && history -c
SSH

    VBoxManage storageattach $VM \
        --storagectl "cdrom" \
        --port 0 \
        --device 0 \
        --type dvddrive \
        --forceunmount \
        --medium emptydrive

}

clean
get_base_vdi
generate_seed

create_machine

VBoxManage startvm $VM --type headless

#vboxmanage showvminfo $VM

sleep 60
wait_boot_finishes
setup_guest_adition

echo "####################"
echo "####################"
echo "##   FINISHED!   ###"
echo "####################"
echo "####################"

notify-send --urgency=low "hey you!" "take a look..."

#VBoxManage startvm  AMZN2-test
#vboxmanage showvminfo AMZN2-test
#vagrant package --base AMZN --output build/amazonlinux2.box
vagrant package --base $VM --output build/amazonlinux2.box

#vagrant cloud version create Eldius/linux-amzn2 $VERSION --description "Based on the image ${VERSION}. From ${VDI_LINK}"
#vagrant cloud publish Eldius/linux-amzn2 $VERSION virtualbox build/amazonlinux2.box
#vagrant cloud version release Eldius/linux-amzn2 $VERSION

vagrant cloud \
    publish \
    --version-description "Based on the image \`${VERSION}\`.\n From ${VDI_LINK}" \
    --force \
    --release \
    Eldius/linux-amzn2 \
    "$VERSION" \
    virtualbox \
    build/amazonlinux2.box


notify-send --urgency=low "hey you!" "take a look..."
