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
xcodebuild -scheme IBE 
xcodebuild -scheme IBE-release 

echo BUILDING 320 LIBRARY
xcodebuild -scheme Three20 
xcodebuild -scheme Three20-Release
