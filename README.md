## MongoDB in Docker, running with QEMU for AVX(2) support anywhere

[Some
applications](https://docs.linuxserver.io/images/docker-unifi-network-application/)
require MongoDB, and MongoDB builds since v5 require AVX extensions on x86-64
systems. One solution is to [rebuild Mongo without
AVX](https://github.com/GermanAizek/mongodb-without-avx) but as the workflow of
authors of Mongo doesn't cater to turning this off, the [maintenance
burden](https://github.com/GermanAizek/mongodb-without-avx/issues/16) of
disabling AVX increases. Also, it takes forever to build on older systems, so
if you're building it _on_ the system that doesn't have AVX, chances are it'll
take hours to build as well.

So, I present to you an _even worse, but simpler_ solution: Use the official
builds, but run them through `qemu-x86_64-static`, because since December
2022's version 7.2 of QEMU, [AVX(2) instructions can be
emulated](https://www.qemu.org/2022/12/14/qemu-7-2-0/).

This will be **really slow** in certain use cases, because QEMU is being used
as a full emulator, not with an accellerated hypervisor. You'll be emulating
x86-64 on x86-64. I don't know if that affords any speedup over doing the same
on, say, ARM64, but I doubt it as it's a niche case.

However, for _light workloads_ (like a tiny wireless deployment that uses a
controller that needs Mongo), it should be fine.

### How it works

All this image does is move the old mongo binaries from the official image to
new files, and replace their original names with scripts that wrap them in
`qemu-x86_64-static`.

### How to build

You'll need to provide `qemu-x86_64-static`, which on Debian, for example, is available through the `qemu-user-static` package. The [`multiarch/qemu-user-static` images on Docker Hub](https://hub.docker.com/r/multiarch/qemu-user-static/) don't include their own architecture's emulator (i.e. x86-64 isn't added on x86-64 systems), else I would use that.

To build, provide the path to the QEMU binaries, for example:

```
docker build -t mongo-qemu:latest --build-context qemu=/usr/bin .
```

These are static binaries, so the host OS distribution should be irrelevant.

#### Docker Compose

If using compose, you can omit an image name, specify a build context against
this project directory, and provide an [additional
context](https://docs.docker.com/reference/compose-file/build/#additional_contexts)
to source the QEMU binary from.

### How to use

Refer to the newly built container by tag, or incorporate it into your
`docker-compose.yml` file.

### Notes

As barely anything is changed from the official container, the entrypoint
script will still warn you about lack of AVX support. However, the script
doesn't error at this point, instead leaving to the `mongod` binary to crash
with a `SIGILL` illegal instruction. Of course, thanks to QEMU, that doesn't
happen.
