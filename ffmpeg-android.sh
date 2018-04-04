#!/bin/bash

VERSION=3.4.2
ARCHS="arm x86"
HOST=$(uname -sm | tr 'A-Z' 'a-z' | sed "s/\ /\-/g")
TOOLCHAIN_ROOT="/shared/dev/toolchain/android/$HOST/ndk-r16"
THREADS="-j$(sysctl -n hw.ncpu)"

cd "`dirname \"$0\"`"

########################################

usage()
{
cat << EOF
usage: $0 options
Build FFmpeg for Android

OPTIONS:
    -h | --help
        Display these options and exit.

    --toolchain
        Specify the Android NDK standalone toolchain root. Default: $TOOLCHAIN_ROOT

    -version
        Specify which version of FFmpeg to build. Default: $VERSION

    -debug
        Build without optimizations and without stripping symbols.

    -v | --verbose
        Display more output while running
EOF
}

missingParameter()
{
    echo $1 requires a parameter
    exit 1
}

unknownParameter()
{
    if [[ -n $2 &&  $2 != "" ]]; then
        echo Unknown argument \"$2\" for parameter $1.
    else
        echo Unknown argument $1
    fi
    exit 1
}

parseArgs()
{
    while [ "$1" != "" ]; do
        case $1 in
            -h | --help)
                usage
                exit
                ;;
            --debug)
                DEBUG=1
                ;;
            --toolchain)
                if [[ -n $2 ]]; then
                    TOOLCHAIN_ROOT=$2
                    shift
                else
                    missingParameter $1
                fi
                ;;
            --version)
                if [[ -n $2 ]]; then
                    VERSION=$2
                    shift
                else
                    missingParameter $1
                fi
                ;;
            -v | --verbose)
                VERBOSE=1
                ;;
            *)
                unknownParameter $1
                ;;
        esac
        shift
    done
}

########################################

unpackArchive()
{
    # Exit the script if an error happens
    set -e
    
    if [ ! -e "ffmpeg-$VERSION.tar.bz2" ]; then
        printf "Downloading ffmpeg-$VERSION.tar.bz2\n"
        curl -L -o "$SRCDIR.tar.bz2" http://ffmpeg.org/releases/ffmpeg-$VERSION.tar.bz2
    else
        printf "Using ffmpeg-$VERSION.tar.bz2\n"
    fi

    rm -rf $SRCDIR
    tar zxf ffmpeg-$VERSION.tar.bz2
}

########################################

buildFFmpeg()
{
    cd $SRCDIR

    codecs="aac pcm_alaw pcm_mulaw adpcm_g726 adpcm_ima_wav mjpeg wmav1 wmav2 wmv1 wmv2"
    decoders="aac_fixed aac_latm adpcm_g726le h263 h264 hevc mjpegb mpeg4"
    parsers="aac h263 h264 hevc mjpeg"
    muxdemuxers="asf avi h263 h264 hevc mjpeg pcm_alaw pcm_mulaw wav"
    demuxers="aac"

    CONFIG_OPTS=("--disable-everything"
            "--disable-programs"
            "--disable-doc"
            "--disable-network"
            "--disable-armv5te"
            "--disable-iconv"
            "--enable-shared"
            "--enable-neon"
            "--enable-cross-compile"
            "--enable-pic")

    for x in ${codecs}; do
        CONFIG_OPTS+=("--enable-encoder=$x" "--enable-decoder=$x")
    done

    for x in ${decoders}; do
        CONFIG_OPTS+=("--enable-decoder=$x")
    done

    for x in ${parsers}; do
        CONFIG_OPTS+=("--enable-parser=$x")
    done

    for x in ${muxdemuxers}; do
        CONFIG_OPTS+=("--enable-muxer=$x" "--enable-demuxer=$x")
    done

    for x in ${demuxers}; do
        CONFIG_OPTS+=("--enable-demuxer=$x")
    done

    if [[ -n $DEBUG ]]; then
        CONFIG_OPTS+=("--disable-optimizations" "--disable-stripping")
    fi



    for ARCH in ${ARCHS}; do
        mkdir -p "${OUTPUTDIR}/${ARCH}"

        case $ARCH in
            arm)
                CONFIG_OPTS+=("--disable-asm")
                CROSS_PREFIX="$TOOLCHAIN_ROOT/android-19/arm/bin/arm-linux-androideabi-"
                ;;
            x86)
                CROSS_PREFIX="$TOOLCHAIN_ROOT/android-19/x86/bin/i686-linux-android-"
                ;;
        esac

        configCmd=("./configure"
            "--prefix=${OUTPUTDIR}/${ARCH}"
            "--target-os=android"
            "--arch=$ARCH"
            "--cc=${CROSS_PREFIX}clang"
            "--enable-cross-compile"
            "--cross-prefix=$CROSS_PREFIX"
            "${CONFIG_OPTS[*]}"
            "> $OUTPUTDIR/$ARCH.log")

        if [[ -n $VERBOSE ]]; then
            printf "Configuring for $ARCH with:\n%s\n" "${configCmd[*]}"
        else
            printf "Configuring for $ARCH\n"
        fi

        eval "${configCmd[*]}"

        printf "Building for ${ARCH}\n"
        make clean >> $OUTPUTDIR/$ARCH.log
        make $THREADS install >> $OUTPUTDIR/$ARCH.log

        printf " - Done\n"

    done
}

########################################

parseArgs $@

SRCDIR=$(pwd)/ffmpeg-$VERSION
OUTPUTDIR=$(pwd)/output/ffmpeg-$VERSION

format="%-18s %s\n"
printf "$format" "ARCHS:" $ARCHS
printf "$format" "VERSION:" $VERSION
printf "$format" "TOOLCHAIN_ROOT:" $TOOLCHAIN_ROOT
printf "$format" "DEBUG:" $( [[ -n $DEBUG ]] && printf "YES" || printf "NO")

rm -rf $OUTPUTDIR
mkdir -p $OUTPUTDIR

unpackArchive
buildFFmpeg

printf "Finished Successfully\n"

