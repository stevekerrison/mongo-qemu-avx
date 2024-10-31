FROM mongo:7.0 AS mongo

# Used for running AVX(2) on incompatible systems
# Ironically, surely even slower than just compiling without AVX(2)
# The `qemu` context should be somewhere that contains qemu-x86_64-static 
COPY --from=qemu ./qemu-x86_64-static /usr/local/bin/
# Rename mongo[ds]
RUN mv /usr/bin/mongod /usr/bin/mongod-native && \
    mv /usr/bin/mongos /usr/bin/mongos-native
# Replace original paths with wrapper scripts that run with qemu
ADD mongod-qemu.sh /usr/bin/mongod
ADD mongos-qemu.sh /usr/bin/mongos

# Everything else in the mongo image remains the same
