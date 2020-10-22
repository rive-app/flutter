#!/bin/sh
set -e 
mkdir -p $PWD/build
docker build -f Dockerfile.build_peon -t build_peon . && docker run -v $PWD/build:/output build_peon