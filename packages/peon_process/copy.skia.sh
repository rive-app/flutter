#!/bin/sh
set -e 
cd /app/submodules/rive-cpp/skia/dependencies/skia/out/
ls 
tar -czvf /output/static.tar.gz Static
cd /app/submodules/rive-cpp/skia/dependencies/skia/
tar -czvf /output/include.tar.gz include 