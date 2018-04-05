This script builds FFmpeg for Android x86 and ARM.

Currently working with FFmpeg v. 3.4.2 using NDK r16b

Prerequisites:
This script assumes that you have built the NDK standalone toolchains and that they are in a common directory. You can specify the toolchain root location with the `--toolchain` parameter. The expected format is `{TOOLCHAIN_ROOT}/android-19/{ARCH}`. If you set your toolchain directory structure up differently you will need to change that value in the `CROSS_PREFIX` variable assignment.

Example standalone toolchain directory structure:
```
- /shared/dev/toolchains/android/darwin-x86_64/ndk-r16/
  - android-19
    - x86
    - arm
```

It is expected that the directory names for each toolchain match the architectures used in the script ("arm", "x86").

You can build the standalone toolchains using the `make_standalone_toolchain.py` script provided in the NDK under the `build/tools` directory.

I used the following commands to create the standalone toolchains:

```
python make_standalone_toolchain.py --api 19 --install-dir /shared/dev/toolchain/android/darwin-x86_64/ndk-r16/android-19/x86 --arch x86 --stl libc++ --force
python make_standalone_toolchain.py --api 19 --install-dir /shared/dev/toolchain/android/darwin-x86_64/ndk-r16/android-19/arm --arch arm --stl libc++ --force
```

The script will place the build artifacts in the current working directory under the `output` directory:
```
- ./output/ffmpeg-{FFMPEG_VERSION}/
  - x86
  - arm
```

Note:
This script is specifically configured to build FFmpeg as it is needed for my particular project, but my hope was to help anyone else having trouble getting it to build. Modifying the script so it builds as you need it should be fairly straight forward. You can modify the `CONFIG_OPTS` variable to enable or disable things, or add / remove things from the various codec / parser / muxer / whatever vairables. The only part that really needs to stay the same is the parameters directly configured in the `configCmd` variable. I plan on adding more configuration options in the future as I have time, but I'm happy to merge any PRs from people who want to add things on their own. Specifically I'm thinking things like which codecs, encoders, decoders, muxers, demuxers, whether or not to build shared or static libraries, and other available options to enable & disable. (You can find a list of all the available configure options by running `./configure --help` from the extracted FFmpeg source, or looking at the configure [script directly](https://github.com/FFmpeg/FFmpeg/blob/master/configure))
