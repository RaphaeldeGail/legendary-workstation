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