#!/bin/bash

while sudo fuser /var/lib/dpkg/lock; do
   echo "waiting for external APT process to terminate..."
   sleep 5
done

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

sudo wget -qO /usr/local/bin/bazel https://github.com/bazelbuild/bazelisk/releases/download/v1.12.0/bazelisk-linux-amd64
sudo chmod +x /usr/local/bin/bazel

sudo curl -s -LO https://go.dev/dl/go1.18.3.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.18.3.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
go version

go install github.com/bazelbuild/buildtools/buildifier@5.1.0
go install github.com/bazelbuild/buildtools/buildozer@5.1.0

git clone -q --branch v1.21.0 https://github.com/envoyproxy/envoy.git
cd envoy
bazel build envoy
sudo mv bazel-bin/source/exe/envoy-static /usr/local/bin/envoy
envoy --version
cd ..