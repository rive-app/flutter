#!/bin/sh

set -e 

for file in ./assets/homefail/*
do
    clean_file=${file//.svg/.clean.svg}
    clean_path=${clean_file//assets\/homefail/assets/homefail_clean}
    svgcleaner --remove-nonsvg-elements=false --ungroup-groups=false --group-by-style=false --merge-gradients=false --remove-nonsvg-attributes=false --remove-unreferenced-ids=false --trim-ids=false --indent=4 --allow-bigger-file  "$file" "$clean_path"
done

for file in ./assets/custom/*
do
    clean_file=${file//.svg/.clean.svg}
    clean_path=${clean_file//assets\/custom/assets/custom_clean}
    svgcleaner --remove-nonsvg-elements=false --ungroup-groups=false --group-by-style=false --merge-gradients=false --remove-nonsvg-attributes=false --remove-unreferenced-ids=false --trim-ids=false --indent=4 --allow-bigger-file  "$file" "$clean_path"
done

for file in ./assets/jc/*
do
    clean_file=${file//.svg/.clean.svg}
    clean_path=${clean_file//assets\/jc/assets/jc_clean}
    svgcleaner --remove-nonsvg-elements=false --ungroup-groups=false --group-by-style=false --merge-gradients=false --remove-nonsvg-attributes=false --remove-unreferenced-ids=false --trim-ids=false --indent=4 --allow-bigger-file  "$file" "$clean_path"
done