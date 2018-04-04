This script builds FFmpeg for Android x86 and ARM.

Currently working with FFmpeg v. 3.4.2 using NDK r16b

Prerequisites:
This script assumes that you have built the NDK standalone toolchains and that they are in a common directory. You can specify the toolchain root location with the `--toolchain` parameter.

Example standalone toolchain directory structure:
```
- /shared/dev/toolchains/android/darwin-x86_64/ndk-r16/
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
