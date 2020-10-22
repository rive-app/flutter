#!/bin/sh
set -e 
docker build -f Dockerfile.skia -t skia . && docker run -v $PWD/packages/peon_process/skia:/output skia 