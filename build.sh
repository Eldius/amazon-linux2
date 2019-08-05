#!/bin/bash

# TODO ADD EXECUTION ERROR VALIDATIONS
VM='AMZN2-test'
VERSION="2.0.20190612"
FILENAME=amzn2-virtualbox-${VERSION}-x86_64.xfs.gpt.vdi
AWS_VDI=${PWD}/images/${FILENAME}
VDI_LINK="https://cdn.amazonlinux.com/os-images/${VERSION}/virtualbox/amzn2-virtualbox-${VERSION}-x86_64.xfs.gpt.vdi"

function usage_description {
    echo "#################################################################################################\n"
    echo "# Modo de usar:                                                                                 #\n"
    echo "# ./build.sh [options]                                                                          #\n"
    echo "# Options:                                                                                      #\n"
    echo "#  --dry-run: Don't publish version to Vagrant Cloud                                            #\n"
    echo "#  --headless: Don't show Virtualbox VM window                                                  #\n"
    echo "#  --import-local: Import Created box to local Box list                                         #\n"
    echo "#  --test-local: Test the created image locally                                                 #\n"
    echo "#  --debug-mode: Stop the process after the end of configuration and open an SSH console        #\n"
    echo "#                                                                                               #\n"
    echo "#                                                                                               #\n"
    echo "#################################################################################################\n"
}
DRY="0"
HEADLESS="0"
LOCAL="0"
TEST="0"
DEBUG="0"

for var in "$@"
do
  case $var in
    "--dry-run"            )
        echo " -> Dry run ON"
        DRY="1"
        ;;
    "--headless"           )
        echo " -> Headless ON"
        HEADLESS=" --type headless "
        ;;
    "--import-local"       )
        echo " -> Import local ON"
        LOCAL="1"
        ;;
    "--test-local"         )
        echo " -> Test local ON"
        TEST="1"
        LOCAL="1"
        ;;
    "--debug-mode"         )
        echo " -> Debug mode ON"
        DEBUG="1"
        ;;
    --help                 )
        usage_description
        exit 0
        ;;
  esac
done


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

    wget \
        https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant \
        -O build/insecure_key
    chmod 600 build/insecure_key

    echo ""
    echo "Old work files cleaned."
    echo ""
}

function get_base_vdi {
    echo ""
    echo "Downloading Amazon Linux 2 image..."
    echo ""

    FILE=${PWD}/work/${FILENAME}
    if [ ! -f $FILE ]; then
        echo "amzn2-virtualbox-${VERSION}-x86_64.xfs.gpt" > .imageVersion
        ## CHANGE_HERE If you want to use a newer version of AWS provided base image
        wget \
            "$VDI_LINK" \
            -O $FILE
    fi
    cp $FILE $AWS_VDI

    echo ""
    echo "Amazon Linux 2 image downloaded."
    echo ""
}

function generate_seed {
    echo ""
    echo "Generating seed image..."
    echo ""

    genisoimage -input-charset utf-8 -output build/seed.iso -volid cidata -joliet -rock seedconfig/user-data seedconfig/meta-data

    echo ""
    echo "Seed image generated."
    echo ""
}

function create_machine {

    echo ""
    echo ""
    echo "#####################################"
    echo "#####################################"
    echo "Create VM '$VM'"
    echo ""

    VBoxManage createvm --name $VM --ostype "Linux_64" --register

    echo ""
    echo "#####################################"
    echo "#####################################"

    echo ""

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

    echo ""
    echo ""

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
    STATE=$( ssh -i build/insecure_key vagrant@localhost -p 9999 -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -o "ConnectTimeout=3" ls -la )

    while [ $? -ne 0 ]
    do
        echo "waiting boot fish..."
        sleep 10
        STATE=$( ssh -i build/insecure_key vagrant@localhost -p 9999 -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -o "ConnectTimeout=3" ls -la )
    done
}



function wait_first_setup_finishes {
    STATE=$(ssh -i build/insecure_key vagrant@localhost -p 9999 -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -o "ConnectTimeout=3" cat /home/vagrant/state_file)

    while [ "$STATE" != "FINISHED" ]
    do
        echo "waiting startup setup..."
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
        --medium emptydrive

    sleep 5

    VBoxManage storageattach $VM \
        --storagectl "cdrom" \
        --port 0 \
        --device 0 \
        --type dvddrive \
        --forceunmount \
        --medium /usr/share/virtualbox/VBoxGuestAdditions.iso

    sleep 5

    echo ""
    echo "#####################################"
    echo "#####################################"

    echo ""

ssh -i build/insecure_key vagrant@localhost -p 9999 -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -o "ConnectTimeout=3" << SSH
    echo "----------------"
    echo " => UPDATING KERNEL PACKAGES"
    yum update kernel* -y
    echo "----------------"
    reboot
SSH

wait_boot_finishes

ssh -i build/insecure_key vagrant@localhost -p 9999 -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -o "ConnectTimeout=3" << SSH

    KERN_DIR=/usr/src/kernels/`uname -r`/build

    sudo yum update -y

    echo "----------------"
    echo " => CREATING MOUNTING POINT"
    sudo mkdir -p /media/cdrom1
    echo " => MOUNTING GUEST ADITIONS CD"
    sudo mount -t iso9660 -o ro /dev/sr0 /media/cdrom1
    cd /media/cdrom1/
    echo " => STARTING INSTALLATION"
    sudo ./VBoxLinuxAdditions.run

    echo "----------------"
    echo "TESTING VBOX GUEST ADDITIONS PRESENCE"
    echo "test result: \$( lsmod | grep vboxguest )"
    echo "----------------"

    sudo reboot
SSH

    #ssh -i build/insecure_key vagrant@localhost -p 9999 -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -o "ConnectTimeout=3"

    VBoxManage storageattach $VM \
        --storagectl "cdrom" \
        --port 0 \
        --device 0 \
        --type dvddrive \
        --forceunmount \
        --medium emptydrive

    wait_boot_finishes

ssh -i build/insecure_key vagrant@localhost -p 9999 -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -o "ConnectTimeout=3" << SSH
    echo "----------------"
    echo "[AGAIN] TESTING VBOX GUEST ADDITIONS PRESENCE"
    echo "test result: \$( lsmod | grep vboxguest )"
    echo "----------------"
SSH

    test_vbox_guest_aditions
}

function publish_version {
    echo ""
    echo "Publishing image to Vagrant Cloud..."
    echo ""

    if [ "${DRY}" -eq "0" ];then
        vagrant cloud \
            publish \
            --version-description "Based on the image \`${VERSION}\`.\n From ${VDI_LINK}" \
            --force \
            --release \
            Eldius/linux-amzn2 \
            "$VERSION" \
            virtualbox \
            build/amazonlinux2.box
    else
        echo "Dry run. Not publishing..."
    fi

    echo ""
    echo "Box published at Vagrant Cloud."
    echo ""
}

function test_error {
    echo "Ooops! Something went wrong here... Take a look!"
    exit 1
}

function test_generated_box {
    echo ""
    echo "Starting a test instance..."
    echo ""

    if [ "${TEST}" -eq "1" ];then
        cd test
        vagrant destroy -f && \
            vagrant up --debug && \
            echo "Successfully tested the new Box" || \
            test_error
    fi

    echo ""
    echo "Box published at Vagrant Cloud."
    echo ""
}

function package_box {
    echo ""
    echo "Packaging box..."
    echo ""

    vagrant package --base $VM --output build/amazonlinux2.box

    echo ""
    echo "Box package finished"
    echo ""
}

function import_local {

    if [ "${LOCAL}" -eq "1" ];then
        echo ""
        echo "Importing box to local repository..."
        echo ""

        vagrant box add Eldius/linux-amzn2 build/amazonlinux2.box --force

        echo ""
        echo "Finished box import to local repository."
        echo ""

    fi
}

function test_vbox_guest_aditions {
    wait_boot_finishes

    TEST_RESULT=$( ssh \
        -i build/insecure_key vagrant@localhost \
        -p 9999 \
        -o "StrictHostKeyChecking no" \
        -o "UserKnownHostsFile=/dev/null" \
        -o "ConnectTimeout=3" \
            echo "  --\> test result: \$( sudo lsmod | grep vboxguest ) \<-- "
    )

    echo "----------------"
    echo "[AGAIN] TESTING VBOX GUEST ADDITIONS PRESENCE"
    echo "test result: ${TEST_RESULT}"
    echo "----------------"
}

function get_cloudinit_log {

sftp -i build/insecure_key vagrant@localhost -p 9999 -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -o "ConnectTimeout=3" << SFTP
    get /var/log/cloud-init*
SFTP

}

function clean_image {

ssh -i build/insecure_key vagrant@localhost -p 9999 -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -o "ConnectTimeout=3" << SSH
    #sudo yum clean all
    sudo rm -rfv /var/cache/yum
    sudo rm /home/vagrant/state_file
    cat /dev/null > ~/.bash_history && history -c
SSH

}

function debug_virtual_machine {
    if [ "${DEBUG}" -eq "1" ];then
        echo "## ENTERING DEBUG MODE ###"

        ssh \
            -i build/insecure_key \
            vagrant@localhost \
            -p 9999 \
            -o "StrictHostKeyChecking no" \
            -o "UserKnownHostsFile=/dev/null" \
            -o "ConnectTimeout=3"

        echo "## EXITING DEBUG MODE ###"
    fi
}

clean
get_base_vdi
generate_seed

create_machine

VBoxManage startvm $VM $HEADLESS

#vboxmanage showvminfo $VM

sleep 60
wait_first_setup_finishes
setup_guest_adition

debug_virtual_machine

#read -p "Press enter to continue"

echo ""
echo "####################"
echo "####################"
echo "##   FINISHED!   ###"
echo "####################"
echo "####################"
echo ""



notify-send --urgency=low "hey you!" "Finished VM creation..."

#get_cloudinit_log

clean_image

package_box
import_local
test_generated_box
publish_version

notify-send --urgency=low "hey you!" "Finished Vagrant Box creation."
