FROM debian:jessie

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    shellcheck \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# build sd card image
WORKDIR /workspace
CMD ["/workspace/build.sh"]
