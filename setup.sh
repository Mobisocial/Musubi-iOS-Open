#!/bin/bash

#this script initializes a clean checkout of musubi and builds the libraries
#that are bundled in source code form.  after you checkout for the first time


echo FETCHING DEPENDENCIES
git submodule update --init

echo GENERATING GMP SOURCE
pushd Libraries/GMP
xcodebuild -project gmpbuild.xcodeproj/ -target gen-src
popd

echo BUILDING IBE LIBRARY
xcodebuild -scheme IBE -sdk iphone archive
xcodebuild -scheme IBE -sdk iphone build
xcodebuild -scheme IBE -sdk iphonesimulator build

echo BUILDING 320 LIBRARY
xcodebuild -scheme Three20 -sdk iphoneos archive
xcodebuild -scheme Three20 -sdk iphoneos build
xcodebuild -scheme Three20 -sdk iphonesimulator build
