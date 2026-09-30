#!/bin/sh
# usage: android/build.sh [4.2|4.3]  (the Spine line, default 4.2: libplugin.spine42 or libplugin.spine43)
# ANDROID_NDK in the environment overrides the per-host default NDK path below.

# This option is used to exit the script as
# soon as a command returns a non-zero value.
set -o errexit

path=`dirname $0`

SPINE_LINE=${1:-4.2}
TARGET_NAME=spine$(echo "$SPINE_LINE" | tr -d .)
CONFIG=Release
DEVICE_TYPE=all
BUILD_TYPE=clean

# // windows mac and linux
if [ $OS == Windows_NT ]
then
	ANDROID_NDK="${ANDROID_NDK:-D:/android-ndk-r29c}"
	LIBS_SRC_DIR="$CORONA_ROOT/Corona/android/lib/gradle/Corona.aar"
	CMD="cmd //c "

elif [ "$(uname)" == "Linux" ]
then
    ANDROID_NDK="${ANDROID_NDK:-/Applications/android-ndk-r29c}"
    LIBS_SRC_DIR="$HOME/Library/Application Support/Corona/Native/Corona/android/lib/gradle/Corona.aar"
    CMD=

else
	ANDROID_NDK="${ANDROID_NDK:-/Applications/android-ndk-r29c.app/Contents/NDK}"
	LIBS_SRC_DIR="$HOME/Library/Application Support/Corona/Native/Corona/android/lib/gradle/Corona.aar"
	CMD=

fi
#
# Checks exit value for error
# 
if [ -z "$ANDROID_NDK" ]
then
	echo "ERROR: ANDROID_NDK environment variable must be defined"
	exit 0
fi

# Canonicalize paths
pushd $path > /dev/null
dir=`pwd`
path=$dir
popd > /dev/null
if [ ! -d "$path/../runtime/spine-$SPINE_LINE/spine" ] || [ ! -f "$path/metadata-$SPINE_LINE.lua" ]
then
	echo "ERROR: unknown Spine line '$SPINE_LINE' (no runtime/spine-$SPINE_LINE or android/metadata-$SPINE_LINE.lua)"
	exit 1
fi
# Every output (unpacked Corona libraries, objects, jniLibs, data.tgz) goes under BUILD_DIR, never a tracked path
BUILD_DIR=${BUILD_DIR:-$path/build/$TARGET_NAME}
mkdir -p "$BUILD_DIR"

######################
# Build .so          #
######################

pushd $path/jni > /dev/null

if [ "Release" == "$CONFIG" ]
then
	echo "Building RELEASE"
	OPTIM_FLAGS="release"
else
	echo "Building DEBUG"
	OPTIM_FLAGS="debug"
fi

if [ "clean" == "$BUILD_TYPE" ]
then
	echo "== Clean build =="
	rm -rf "$BUILD_DIR/obj" "$BUILD_DIR/libs" "$BUILD_DIR/data.tgz"
	FLAGS="-B"
else
	echo "== Incremental build =="
	FLAGS=""
fi

CFLAGS=

if [ "$OPTIM_FLAGS" = "debug" ]
then
	CFLAGS="${CFLAGS} -DRtt_DEBUG -g"
	FLAGS="$FLAGS NDK_DEBUG=1"
fi
FLAGS="$FLAGS NDK_OUT=$BUILD_DIR/obj NDK_LIBS_OUT=$BUILD_DIR/libs CORONA_LIBS=$BUILD_DIR/corona-libs SPINE_LINE=$SPINE_LINE"

# Copy .so files
LIBS_DST_DIR="$BUILD_DIR/corona-libs"
mkdir -p "$LIBS_DST_DIR"

unzip -u "$LIBS_SRC_DIR" "jni/*/*.so" -d "$LIBS_DST_DIR"

if [ -z "$CFLAGS" ]
then
	echo "----------------------------------------------------------------------------"
	echo "$ANDROID_NDK/ndk-build $FLAGS V=1 APP_OPTIM=$OPTIM_FLAGS"
	echo "----------------------------------------------------------------------------"

	$CMD $ANDROID_NDK/ndk-build $FLAGS V=1 APP_OPTIM=$OPTIM_FLAGS
else
	echo "----------------------------------------------------------------------------"
	echo "$ANDROID_NDK/ndk-build $FLAGS V=1 MY_CFLAGS="$CFLAGS" APP_OPTIM=$OPTIM_FLAGS"
	echo "----------------------------------------------------------------------------"

	$CMD $ANDROID_NDK/ndk-build $FLAGS V=1 MY_CFLAGS="$CFLAGS" APP_OPTIM=$OPTIM_FLAGS
fi

find "$BUILD_DIR/libs" \( -name liblua.so -or -name libcorona.so \)  -delete
echo "$BUILD_DIR/libs"
rm -rf "$BUILD_DIR/jniLibs"
mv "$BUILD_DIR/libs" "$BUILD_DIR/jniLibs"

popd > /dev/null

######################
# Post-compile Steps #
######################

echo Done.
echo $BUILD_DIR/jniLibs/armeabi-v7a/libplugin.$TARGET_NAME.so


echo Packing binaries...
OUTPUT_DIR=$BUILD_DIR
# Package metadata and ABI-specific libraries under jniLibs only.
# Do not include a duplicate top-level libplugin.$TARGET_NAME.so to avoid
# triggering ELF alignment checks for 32-bit copies.
cp "$path/metadata-$SPINE_LINE.lua" "$BUILD_DIR/metadata.lua"
# Every entry's mtime is the committer time of the last commit outside plugin/, so the archive is reproducible
MTIME=$(git -C "$path/.." log -1 --format=%ct HEAD -- . ':(exclude)plugin')
"$path/../tools/release/pack.sh" --mtime "$MTIME" "$BUILD_DIR" "$OUTPUT_DIR/data.tgz" metadata.lua jniLibs
echo $OUTPUT_DIR/data.tgz
