FROM microsoft/dotnet:2.2.104-sdk-stretch as builder
LABEL maintainer "FunctionalStack, Inc. <rajiv.mounguengue@functionalstack.io>"
ENV MONO_THREADS_PER_CPU 50
RUN MONO_VERSION=5.16.0.179 && \
    FSHARP_VERSION=10.2.1 && \
    FSHARP_BASENAME=fsharp-$FSHARP_VERSION && \
    FSHARP_ARCHIVE=$FSHARP_VERSION.tar.gz && \
    FSHARP_ARCHIVE_URL=https://github.com/fsharp/fsharp/archive/$FSHARP_VERSION.tar.gz && \
    export GNUPGHOME="$(mktemp -d)" && \
    apt-get update && apt-get --no-install-recommends install -y gnupg dirmngr && \
    apt-get install unzip && \
    apt-key adv --no-tty --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF && \
    echo "deb https://download.mono-project.com/repo/debian stable-stretch/snapshots/$MONO_VERSION main" | tee /etc/apt/sources.list.d/mono-official-stable.list && \
    apt-get install -y apt-transport-https && \
    apt-get update -y && \
    apt-get --no-install-recommends install -y pkg-config make nuget mono-devel msbuild ca-certificates-mono locales && \
    rm -rf /var/lib/apt/lists/* && \
    echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen && /usr/sbin/locale-gen && \
    mkdir -p /tmp/src && \
    cd /tmp/src && \
    printf "namespace a { class b { public static void Main(string[] args) { new System.Net.WebClient().DownloadFile(\"%s\", \"%s\");}}}" $FSHARP_ARCHIVE_URL $FSHARP_ARCHIVE > download-fsharp.cs && \
    mcs download-fsharp.cs && mono download-fsharp.exe && rm download-fsharp.exe download-fsharp.cs && \
    tar xf $FSHARP_ARCHIVE && \
    cd $FSHARP_BASENAME && \
    make && \
    make install && \
    cd ~ && \
    rm -rf /tmp/src /tmp/NuGetScratch ~/.nuget ~/.config ~/.local "$GNUPGHOME" && \
    apt-get purge -y make gnupg dirmngr && \
    apt-get clean

WORKDIR /root
ENV FrameworkPathOverride /usr/lib/mono/4.7.1-api/

RUN mkdir /usr/local/bin/fake \
    && cd /usr/local/bin/fake \
    && wget -q -O ./fake.zip 'https://github.com/fsharp/FAKE/releases/download/5.11.1/fake-dotnetcore-linux-x64.zip' \
    && unzip ./fake.zip \
    && chmod +x /usr/local/bin/fake/fake

RUN wget https://github.com/fsprojects/Paket/releases/download/5.194.3/paket.exe \
    && chmod a+r paket.exe && mv paket.exe /usr/local/lib/ \
    && printf '#!/bin/sh\nexec /usr/bin/mono /usr/local/lib/paket.exe "$@"' >> /usr/local/bin/paket \
    && chmod u+x /usr/local/bin/paket

ENTRYPOINT ["paket"]
