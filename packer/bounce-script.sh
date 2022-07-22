#!/bin/bash

if [ -d /etc/custom ]; then
   sudo rm -rf /etc/custom
fi

sudo mkdir /etc/custom
sudo chmod 0700 /etc/custom

if [ -z "$RSA_KEY" ]; then
   echo "No private key RSA_KEY found"
   exit 1
fi

if [ -z "$RSA_PUB" ]; then
   echo "No public key RSA_KEY found"
   exit 1
fi

echo "Loading private key"
echo "$RSA_KEY" | sudo tee /etc/custom/ssh_host_rsa_key > /dev/null
sudo chown root:root /etc/custom/ssh_host_rsa_key
sudo chmod 400 /etc/custom/ssh_host_rsa_key

echo "Loading public key"
echo "$RSA_PUB" | sudo tee /etc/custom/ssh_host_rsa_key.pub > /dev/null
sudo chown root:root /etc/custom/ssh_host_rsa_key.pub
sudo chmod 600 /etc/custom/ssh_host_rsa_key.pub

echo "Loading configuration file"
echo "HostKey /etc/custom/ssh_host_rsa_key" | sudo tee /etc/ssh/sshd_config.d/custom.conf > /dev/null

if ! sudo test -f /etc/custom/ssh_host_rsa_key; then
   echo "private key /etc/custom/ssh_host_rsa_key was not correctly written"
   exit 1
fi
if ! sudo test -s /etc/custom/ssh_host_rsa_key; then
   echo "private key /etc/custom/ssh_host_rsa_key is empty"
   exit 1
fi
echo "Private key successfully loaded"

if ! sudo test -f /etc/custom/ssh_host_rsa_key.pub; then
   echo "public key /etc/custom/ssh_host_rsa_key.pub was not correctly written"
   exit 1
fi
if ! sudo test -s /etc/custom/ssh_host_rsa_key.pub; then
   echo "public key /etc/custom/ssh_host_rsa_key.pub is empty"
   exit 1
fi
echo "Public key successfully loaded"

if ! sudo test -f /etc/ssh/sshd_config.d/custom.conf; then
   echo "configuration file /etc/ssh/sshd_config.d/custom.conf was not correctly written"
   exit 1
fi
if ! sudo test -s /etc/ssh/sshd_config.d/custom.conf; then
   echo "configuration file /etc/ssh/sshd_config.d/custom.conf is empty"
   exit 1
fi
echo "Configuration file successfully loaded"

echo "Build succesful"
exit 0