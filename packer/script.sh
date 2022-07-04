#!/bin/bash

sudo apt-get update
sudo apt-get -y install \
   autoconf \
   automake \
   cmake \
   curl \
   libtool \
   make \
   patch \
   unzip \
   gcc \
   g++

git clone https://github.com/ninja-build/ninja.git
cd ninja
cmake -Bbuild-cmake
cmake --build build-cmake
sudo mv build-cmake/ninja /usr/local/bin/ninja
cd ..

sudo wget -O /usr/local/bin/bazel https://github.com/bazelbuild/bazelisk/releases/latest/download/bazelisk-linux-$([ $(uname -m) = "aarch64" ] && echo "arm64" || echo "amd64")
sudo chmod +x /usr/local/bin/bazel

sudo curl -LO https://go.dev/dl/go1.18.3.linux-amd64.tar.gz
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.18.3.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee -a /etc/profile

/usr/local/go/bin/go install github.com/bazelbuild/buildtools/buildifier@latest
/usr/local/go/bin/go install github.com/bazelbuild/buildtools/buildozer@latest

git clone https://github.com/envoyproxy/envoy.git
cd envoy
bazel build envoy
cd ..