#!/bin/bash

#this script initializes a clean checkout of musubi and builds the libraries
#that are bundled in source code form.  after you checkout for the first time


echo FETCHING DEPENDENCIES
git submodule update --init

