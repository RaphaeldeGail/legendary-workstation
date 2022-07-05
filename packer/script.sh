#!/bin/bash

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
   ninja-build

# git clone -q https://github.com/ninja-build/ninja.git
# cd ninja
# cmake -Bbuild-cmake
# cmake --build build-cmake
# sudo mv build-cmake/ninja /usr/local/bin/ninja
# cd ..

sudo wget -qO /usr/local/bin/bazel https://github.com/bazelbuild/bazelisk/releases/latest/download/bazelisk-linux-$([ $(uname -m) = "aarch64" ] && echo "arm64" || echo "amd64")
sudo chmod +x /usr/local/bin/bazel

sudo curl -s -LO https://go.dev/dl/go1.18.3.linux-amd64.tar.gz
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.18.3.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee -a /etc/profile

/usr/local/go/bin/go install github.com/bazelbuild/buildtools/buildifier@latest
/usr/local/go/bin/go install github.com/bazelbuild/buildtools/buildozer@latest

git clone -q --branch v1.22.2 https://github.com/envoyproxy/envoy.git
cd envoy
bazel build --show_result=1 --verbose_failures -c opt envoy
cd ..