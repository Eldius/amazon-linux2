# Amazon Linuz 2 Vagrant Box #

This box is registered as a Vagrant Box at [https://app.vagrantup.com/Eldius/boxes/linux-amzn2](https://app.vagrantup.com/Eldius/boxes/linux-amzn2).

The latest image was built over the version `amzn2-virtualbox-2.0.20190115-x86_64` of AWS Virtualbox provided image.

To build this box you just need to run the `./build.sh` script. You may change the base image by changing the download URL (near the `CHANGE_HERE` tag on coment at `get_base_vdi` function).

## Notes ##

VBoxManage clonehd --format RAW amzn2-virtualbox-2.0.20190115-x86_64.xfs.gpt.vdi amzn2-virtualbox-2.0.20190115-x86_64.xfs.gpt.vdi.img

## LINKS ##

- [poflynn/AMZN2Vagrant](https://github.com/poflynn/AMZN2Vagrant)
- [Create VirtualBox VM from the command line](https://www.perkin.org.uk/posts/create-virtualbox-vm-from-the-command-line.html)
- [VBox Manual - ch08](https://www.virtualbox.org/manual/ch08.html#idm4249)
- [Send keystrokes to Virtualbox guest console](https://blogs.oracle.com/letthesunshinein/send-keystrokes-to-virtualbox-guest-console)
- [Can I non-interactively send keyboard commands to a virtualbox image?](https://superuser.com/questions/1131771/can-i-non-interactively-send-keyboard-commands-to-a-virtualbox-image)
- [VBox Manual - Chapter 6. Virtual networking](https://www.virtualbox.org/manual/ch06.html)
