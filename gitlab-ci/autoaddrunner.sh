#!/bin/bash

timestamp=$(date +"%F"_"%T")

echo "Set runner token"
read run_token
echo "Set name of VM"
read vm_name

EXT_IP=$(yc compute instance get --name $vm_name | sed -n '24p' | awk '{print $2}')

echo "Send script to $vm_name"
chmod +x addreg.sh
scp addreg.sh yc-user@$EXT_IP

echo "Force pseudo terminal allocation"
ssh -t yc-user@$EXT_IP \
./addreg.sh $EXT_IP $timestamp $run_token
