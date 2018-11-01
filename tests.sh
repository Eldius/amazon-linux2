#!/bin/bash

STATE=$(ssh -i build/insecure_key vagrant@localhost -p 2222 -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -o "ConnectTimeout=3" cat /home/vagrant/state_file)

while [ "$STATE" != "FINISHED" ]
do
    echo "waiting..."
    sleep 10
    STATE=$(ssh -i build/insecure_key vagrant@localhost -p 2222 -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -o "ConnectTimeout=3" cat /home/vagrant/state_file)
done

