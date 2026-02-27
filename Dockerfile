# Dockerfile for using mongo with a QEMU user binary
# Author: Steve Kerrison <git [at] stevekerrison.com>
# License: Unlicense

# Specify a different source tag if you want with --build-arg mongo_tag=...
ARG mongo_tag=7.0
ARG qemu_source=debian:stable-slim

# Mongo <= 7 builds use Ubuntu Jammy, and its version of qemu is too old to emulate
# AVX. However, the binaries are static, so it doesn't matter if we pull them
# in from somewhere else. We'll use Debian slim in such cases, otherwise we'll
# just re-use the Mongo 8+ image...
FROM ${qemu_source} AS qemu

RUN apt-get update \
    && apt-get -y install --no-install-recommends qemu-user-static

# Select the base image again
FROM mongo:${mongo_tag} AS mongo

# Used for running AVX(2) on incompatible systems.  Ironically, surely even
# slower than just compiling without AVX(2)
COPY --from=qemu /usr/bin/qemu-x86_64-static /usr/bin/

# Rename mongo[ds]
RUN mv /usr/bin/mongod /usr/bin/mongod-native && \
    mv /usr/bin/mongos /usr/bin/mongos-native

# Replace original paths with wrapper scripts that run with qemu
COPY mongod-qemu.sh /usr/bin/mongod
COPY mongos-qemu.sh /usr/bin/mongos

# Everything else in the mongo image remains the same
