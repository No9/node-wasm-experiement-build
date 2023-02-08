FROM docker.io/rockylinux/rockylinux:8 as rhel8builder

RUN dnf update -y
RUN dnf install -y dnf-plugins-core
RUN dnf config-manager --set-enabled plus
RUN dnf config-manager --set-enabled devel
RUN dnf config-manager --set-enabled powertools
RUN dnf clean all
RUN dnf update -y
RUN dnf repolist --all
RUN dnf -y install epel-release

RUN dnf install -y git python3 which redhat-lsb-core systemd-devel yajl-devel \ 
    libseccomp-devel pkg-config libgcrypt-devel \
    glibc-static python3-libmount libtool libcap-devel

RUN git clone --depth 1 -b napi-libnode https://github.com/mmomtchev/node.git
RUN dnf install -y gcc-c++
WORKDIR /node
RUN ./configure --shared
RUN make
WORKDIR /
RUN git clone --depth 1 -b node-wasm-experiment https://github.com/mhdawson/crun.git
WORKDIR /crun
RUN cp /node/out/Release/libnode.so.*  /lib64/libnode.so
RUN cp /node/src/js_native_api.h /usr/include/js_native_api.h
RUN cp /node/src/js_native_api_types.h /usr/include/js_native_api_types.h
RUN cp /node/src/node_api.h /usr/include/node_api.h
RUN cp /node/src/node_api_types.h /usr/include/node_api_types.h
RUN ./autogen.sh
RUN ./configure --with-wasm_nodejs --enable-embedded-yajl
RUN make

# Copy crun wasmedge and libnode.so out and put 