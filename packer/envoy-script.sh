#!/bin/bash

while sudo fuser /var/lib/dpkg/lock; do
   echo "waiting for external APT process to terminate..."
   sleep 5
done

if [ -z "$SERVER_KEY" ]; then
   echo "No private key SERVER_KEY found"
   exit 1
fi

if [ -z "$SERVER_CERT" ]; then
   echo "No public certificate SERVER_CERT found"
   exit 1
fi

echo "Loading private key"
echo "$SERVER_KEY" | sudo tee /etc/ssl/private/server.key > /dev/null
sudo chown root:root /etc/ssl/private/server.key
sudo chmod 400 /etc/ssl/private/server.key

echo "Loading public certificate"
echo "$SERVER_CERT" | sudo tee /etc/ssl/certs/server.pem > /dev/null
sudo chown root:root /etc/ssl/certs/server.pem
sudo chmod 600 /etc/ssl/certs/server.pem

if ! sudo test -f /etc/ssl/private/server.key; then
   echo "private key /etc/ssl/private/server.key was not correctly written"
   exit 1
fi
if ! sudo test -s /etc/ssl/private/server.key; then
   echo "private key /etc/ssl/private/server.key is empty"
   exit 1
fi
echo "Private key successfully loaded"

if ! sudo test -f /etc/ssl/certs/server.pem; then
   echo "public certificate /etc/ssl/certs/server.pem was not correctly written"
   exit 1
fi
if ! sudo test -s /etc/ssl/certs/server.pem; then
   echo "public certificate /etc/ssl/certs/server.pem is empty"
   exit 1
fi
echo "Public key successfully loaded"

cat | sudo tee /etc/systemd/system/envoy.service > /dev/null <<EOF
[Unit]
Description=The ENVOY proxy server
After=syslog.target network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target

[Service]
Type=simple
PIDFile=/run/envoy.pid
ExecStartPre=/bin/bash -c '/usr/local/bin/envoy --mode validate -c /etc/envoy.yaml | tee'
ExecStart=/bin/bash -c '/usr/local/bin/envoy -c /etc/envoy.yaml | tee'
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
sudo chown root:root /etc/systemd/system/envoy.service
sudo chmod 644 /etc/systemd/system/envoy.service

if ! sudo test -f /etc/systemd/system/envoy.service; then
   echo "Service file /etc/systemd/system/envoy.service was not correctly written"
   exit 1
fi
if ! sudo test -s /etc/systemd/system/envoy.service; then
   echo "Service file /etc/systemd/system/envoy.service is empty"
   exit 1
fi
echo "Service file successfully loaded"

sudo systemctl daemon-reload
sudo systemctl enable envoy

sudo DEBIAN_FRONTEND=noninteractive apt-get --quiet update
sudo DEBIAN_FRONTEND=noninteractive apt-get --quiet -y install \
   autoconf \
   automake \
   cmake \
   curl \
   libtool \
   make \
   patch \
   unzip \
   python3-pip \
   virtualenv \
   ninja-build \
   nginx

if ! ninja --version; then
  echo 'Error could not find ninja builder'
  exit 1
fi

sudo wget -qO /usr/local/bin/bazel https://github.com/bazelbuild/bazelisk/releases/download/v1.12.0/bazelisk-linux-amd64
sudo chmod +x /usr/local/bin/bazel

if ! bazel --version; then
  echo 'Error could not find bazel builder'
  exit 1
fi

sudo curl -s -LO https://go.dev/dl/go1.18.3.linux-amd64.tar.gz
if [ -d /usr/local/go ]; then
   sudo rm -rf /usr/local/go
fi
sudo tar -C /usr/local -xzf go1.18.3.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin

if ! go version; then
  echo 'Error could not find go'
  exit 1
fi

go install github.com/bazelbuild/buildtools/buildifier@5.1.0
go install github.com/bazelbuild/buildtools/buildozer@5.1.0

if [ -d ./envoy ]; then
   sudo rm -rf ./envoy
fi

git clone -q --branch v1.21.0 https://github.com/envoyproxy/envoy.git
cd envoy
bazel build envoy
if [ -x bazel-bin/source/exe/envoy-static ]; then
   sudo mv bazel-bin/source/exe/envoy-static /usr/local/bin/envoy
fi
cd ..
sudo rm -rf ./envoy

if ! envoy --version; then
  echo 'Error could not find envoy'
  exit 1
fi

echo 'Build successful'
exit 0