#!/bin/sh

set -e 

for file in ./assets/custom/*
do
    clean_file=${file//.svg/.clean.svg}
    clean_path=${clean_file//assets\/custom/assets/custom_clean}
    svgcleaner --remove-nonsvg-elements=false --ungroup-groups=false --group-by-style=false --merge-gradients=false --remove-nonsvg-attributes=false --remove-unreferenced-ids=false --trim-ids=false --indent=4 --allow-bigger-file  "$file" "$clean_path"
done