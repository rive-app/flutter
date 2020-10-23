#!/usr/bin/env bash

list=`find $RIVE_ROOT/packages -type f -name 'pubspec.yaml' | sed -E 's|/[^/]+$||'`
echo "$list"
for d in  $list; do
  echo "UPDATING $d"
  if grep -Fq "sdk: flutter" $d/pubspec.yaml
  then
    cd $d && flutter pub get test && cd -
    if [ $? -ne 0 ]; then
      exit 1
    fi
  else 
    cd $d && pub get test && cd -
    if [ $? -ne 0 ]; then
      exit 1
    fi
  fi
done
