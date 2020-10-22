#!/bin/sh
set -e 
cp -r /app/packages/peon_process/build/linux/release/ /output/release
cp /usr/local/bin/rive_thumbnail_generator /output/rive_thumbnail_generator