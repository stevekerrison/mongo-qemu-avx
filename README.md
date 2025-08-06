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

### How to use

If you just want to use prebuilt packages, then you can get them from GHCR:

```
docker pull ghcr.io/stevekerrison/mongo-qemu-avx:{main_or_semver}-mongo{mongo_version}
```

Examples:

```
docker pull ghcr.io/stevekerrison/mongo-qemu-avx:v0.0.1-mongo8
docker pull ghcr.io/stevekerrison/mongo-qemu-avx:main-mongo6
```

### How to build

If you want to build for yourself, here's how...

The Dockerfile uses Debian's `qemu-user-static` package to source
`qemu-x86_64-static` and drop it into the modified `mongo` image. You don't
need `qemu` installed on your host system when building.

Building is simple. To create the image `mongo-qemu:latest`:

```
docker build -t mongo-qemu:latest .
```

You can then use it locally, or push it to a registry.

#### Mongo versions

The default `mongo` version is `7.0` but you can specify the build arg
`mongo_tag` to select another, e.g.:

```
docker build -t mongo-qemu:latest --build-arg mongo_tag=6.0 .
```

### How to use

Refer to the newly built container by tag, or incorporate it into your
`docker-compose.yml` file.

### Notes

As barely anything is changed from the official container, the entrypoint
script will still warn you about lack of AVX support. However, the script
doesn't error at this point, instead leaving it to the `mongod` binary to crash
with a `SIGILL` illegal instruction. Of course, thanks to QEMU, that doesn't
happen.
