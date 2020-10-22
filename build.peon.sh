#!/bin/sh
set -e 
docker build -f Dockerfile.build_peon -t build_peon . && docker run -v $PWD/build:/output build_peon