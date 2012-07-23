#!/bin/sh
set | grep ARCH
set -x

## Determine the appropriate openssl source path to use
## Introduced by michaeltyson, adapted to account for OPENSSL_SRC build path

# locate src archive file if present
SRC_ARCHIVE=`ls openssl*tar.gz 2>/dev/null`

# if there is an openssl directory immediately under the openssl.xcode source 
# folder then build there
if [ -d "$SRCROOT/openssl" ]; then
OPENSSL_SRC="$SRCROOT/openssl"
# else, if there is a openssl.tar.gz in the directory, expand it to openssl
# and use it
elif [ -f "$SRC_ARCHIVE" ]; then
OPENSSL_SRC="$PROJECT_TEMP_DIR/openssl"
if [ ! -d "$OPENSSL_SRC" ]; then
echo "extracting $SRC_ARCHIVE..."
mkdir "$OPENSSL_SRC"
tar -C "$OPENSSL_SRC" --strip-components=1 -zxf "$SRC_ARCHIVE" || exit 1
cp -RL "$OPENSSL_SRC/include" "$TARGET_BUILD_DIR"
fi
# else, if $OPENSSL_SRC is not already defined (i.e. by prerequisites for SQLCipher XCode config)
# then assume openssl is in the current directory
elif [ ! -d "$OPENSSL_SRC" ]; then
OPENSSL_SRC="$SRCROOT"
fi

echo "***** using $OPENSSL_SRC for openssl source code  *****"

# check whether libcrypto.a already exists - we'll only build if it does not
if [ -f  "$TARGET_BUILD_DIR/libcrypto.a" ]; then
echo "***** Using previously-built libary $TARGET_BUILD_DIR/libcrypto.a - skipping build *****"
echo "***** To force a rebuild clean project and clean dependencies *****"
exit 0;
else
echo "***** No previously-built libary present at $TARGET_BUILD_DIR/libcrypto.a - performing build *****"
fi

# figure out the right set of build architectures for this run
if [ "$ARCHS_STANDARD_32_64_BIT" != "" ]; then
BUILDARCHS="$ARCHS_STANDARD_32_64_BIT"
elif [ "$ARCHS_STANDARD_32_BIT" != "" ]; then
BUILDARCHS="$ARCHS_STANDARD_32_BIT"
else
BUILDARCHS="$ARCHS"
fi

echo "***** creating universal binary for architectures: $BUILDARCHS *****"

if [ "$SDKROOT" != "" ]; then
ISYSROOT="-isysroot $SDKROOT"
fi

echo "***** using ISYSROOT $ISYSROOT *****"

OPENSSL_OPTIONS="no-krb5 no-gost"

echo "***** using OPENSSL_OPTIONS $OPENSSL_OPTIONS *****"

cd "$OPENSSL_SRC"

for BUILDARCH in $BUILDARCHS
do
echo "***** BUILDING UNIVERSAL ARCH $BUILDARCH ******"
make clean

# if build architecture is i386 AND we are not building in Debug mode, use the assembler enhancements
# otherwise, disable assembler
if [ "$BUILDARCH" = "i386" -a "$BUILD_STYLE" != "Debug" ]; then
echo "***** configuring WITH assembler optimizations based on architecture $BUILDARCH and build style $BUILD_STYLE *****"
./config $OPENSSL_OPTIONS -openssldir="$BUILD_DIR"
ASM_DEF="-DOPENSSL_BN_ASM_PART_WORDS"
else
echo "***** configuring WITHOUT assembler optimizations based on architecture $BUILDARCH and build style $BUILD_STYLE *****"
./config no-asm $OPENSSL_OPTIONS -openssldir="$BUILD_DIR"
ASM_DEF="-UOPENSSL_BN_ASM_PART_WORDS"
fi

make CFLAG="-D_DARWIN_C_SOURCE $ASM_DEF -arch $BUILDARCH $ISYSROOT" SHARED_LDFLAGS="-arch $BUILDARCH -dynamiclib"

echo "***** copying intermediate libraries to $CONFIGURATION_TEMP_DIR/$BUILDARCH-*.a *****"
cp libcrypto.a "$CONFIGURATION_TEMP_DIR"/$BUILDARCH-libcrypto.a
cp libssl.a "$CONFIGURATION_TEMP_DIR"/$BUILDARCH-libssl.a
done

echo "***** creating universallibraries in $TARGET_BUILD_DIR *****"
mkdir -p "$TARGET_BUILD_DIR"
lipo -create "$CONFIGURATION_TEMP_DIR/"*-libcrypto.a -output "$TARGET_BUILD_DIR/libcrypto.a"
lipo -create "$CONFIGURATION_TEMP_DIR/"*-libssl.a -output "$TARGET_BUILD_DIR/libssl.a"
                                       
echo "***** removing temporary files from $CONFIGURATION_TEMP_DIR *****"
rm -f "$CONFIGURATION_TEMP_DIR/"*-libcrypto.a
rm -f "$CONFIGURATION_TEMP_DIR/"*-libssl.a
                                       
echo "***** executing ranlib on libraries in $TARGET_BUILD_DIR *****"
ranlib "$TARGET_BUILD_DIR/libcrypto.a"
ranlib "$TARGET_BUILD_DIR/libssl.a"
                                       

