#!/usr/bin/env bash

for d in $RIVE_ROOT/packages/*/ ; do
  folder=`basename $d`
  echo "UPDATING $d"
  echo "$RIVE_ROOT/packages/$folder/pubspec.yaml"
  if grep -Fq "sdk: flutter" $RIVE_ROOT/packages/$folder/pubspec.yaml
  then 
    cd $RIVE_ROOT/packages/$folder && flutter pub get test && cd -
    if [ $? -ne 0 ]; then
      exit 1
    fi
  else 
    cd $RIVE_ROOT/packages/$folder && pub get test && cd -
    if [ $? -ne 0 ]; then
      exit 1
    fi
  fi
  
done
