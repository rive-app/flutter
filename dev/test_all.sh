#!/usr/bin/env bash

list=`find ../packages -type f -name 'pubspec.yaml' | sed -E 's|/[^/]+$||'`
for d in  $list; do
  folder=`basename $d`
  if grep -Fq "test:" $d/pubspec.yaml && [ -d "$d/test" ]
  then
    if grep -Fq "sdk: flutter" $d/pubspec.yaml
    then 
        echo "Running Flutter tests for ${d:12}."
        cd $d && flutter test && cd -
        if [ $? -ne 0 ]; then
        exit 1
        fi
    else 
        echo "Running Dart tests for ${d:12}."
        cd $d && pub run test && cd -
        if [ $? -ne 0 ]; then
        exit 1
        fi
    fi
  else
   echo "Not running tests for ${d:12}."
  fi
  
done
