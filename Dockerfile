# Smallest base image, latests stable image
# Alpine would be nice, but it's linked again musl and breaks the bitcoin core download binary
#FROM alpine:latest

FROM ubuntu:latest AS builder
ARG TARGETARCH

FROM builder AS builder_amd64
ENV ARCH=x86_64
FROM builder AS builder_arm64
ENV ARCH=aarch64
FROM builder AS builder_riscv64
ENV ARCH=riscv64

FROM builder_${TARGETARCH} AS build

# Testing: gosu
#RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing/" >> /etc/apk/repositories \
#    && apk add --update --no-cache gnupg gosu gcompat libgcc
RUN apt update \
    && apt install -y --no-install-recommends \
    ca-certificates \
    gnupg \
    libatomic1 \
    wget \
    && apt clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# --------------------------------------------------------------------

# This is how Bitcoin Core gets downloaded and verified.
# It would be good to use the equivalent verification for the DigiByte binary, if possible.

# ARG VERSION=24.0.1
# ARG BITCOIN_CORE_SIGNATURE=71A3B16735405025D447E8F274810B012346C9A6

# Don't use base image's bitcoin package for a few reasons:
# 1. Would need to use ppa/latest repo for the latest release.
# 2. Some package generates /etc/bitcoin.conf on install and that's dangerous to bake in with Docker Hub.
# 3. Verifying pkg signature from main website should inspire confidence and reduce chance of surprises.
# Instead fetch, verify, and extract to Docker image
# RUN cd /tmp \
#     && gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys ${BITCOIN_CORE_SIGNATURE} \
#     && wget https://bitcoincore.org/bin/bitcoin-core-${VERSION}/SHA256SUMS.asc \
#     https://bitcoincore.org/bin/bitcoin-core-${VERSION}/SHA256SUMS \
#     https://bitcoincore.org/bin/bitcoin-core-${VERSION}/bitcoin-${VERSION}-${ARCH}-linux-gnu.tar.gz \
#     && gpg --verify --status-fd 1 --verify SHA256SUMS.asc SHA256SUMS 2>/dev/null | grep "^\[GNUPG:\] VALIDSIG.*${BITCOIN_CORE_SIGNATURE}\$" \
#     && sha256sum --ignore-missing --check SHA256SUMS \
#     && tar -xzvf bitcoin-${VERSION}-${ARCH}-linux-gnu.tar.gz -C /opt \
#     && ln -sv bitcoin-${VERSION} /opt/bitcoin \
#     && /opt/bitcoin/bin/test_bitcoin --show_progress \
#     && rm -v /opt/bitcoin/bin/test_bitcoin /opt/bitcoin/bin/bitcoin-qt

# --------------------------------------------------------------------

# Get the latest DigiByte Core and test it. The downloaded binary is not currently verified.

ARG VERSION=7.17.3

RUN cd /tmp \
    && wget \
    https://github.com/DigiByte-Core/digibyte/releases/download/v${VERSION}/digibyte-${VERSION}-${ARCH}-linux-gnu.tar.gz \
    && tar -xzvf digibyte-${VERSION}-${ARCH}-linux-gnu.tar.gz -C /opt \
    && ln -sv digibyte-${VERSION} /opt/digibyte \
    && /opt/digibyte/bin/test_digibyte --show_progress \
    && rm -v /opt/digibyte/bin/test_digibyte /opt/bitcoin/bin/digibyte-qt

# --------------------------------------------------------------------

FROM ubuntu:latest
LABEL maintainer="Olly Stedall <olly@digibyte.help>"

ENTRYPOINT ["docker-entrypoint.sh"]
ENV HOME /digibyte
EXPOSE 12024 14022
VOLUME ["/digibyte/.digibyte"]
WORKDIR /digibyte

ARG GROUP_ID=1000
ARG USER_ID=1000
RUN groupadd -g ${GROUP_ID} digibyte \
    && useradd -u ${USER_ID} -g digibyte -d /digibyte digibyte

COPY --from=build /opt/ /opt/

RUN apt update \
    && apt install -y --no-install-recommends gosu libatomic1 \
    && apt clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && ln -sv /opt/digibyte/bin/* /usr/local/bin

COPY ./bin ./docker-entrypoint.sh /usr/local/bin/

CMD ["dgb_oneshot"]
