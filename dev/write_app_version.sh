#!/bin/bash

# Takes the app version from the pubspec
# and writes it into a Dart file that
# the app uses to display the version

# Directory of this script
SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
EDITOR_ROOT_DIR=$SCRIPTPATH/../packages/editor
PUBSPEC_FILE=$EDITOR_ROOT_DIR/pubspec.yaml
DART_VERSION_FILE=$EDITOR_ROOT_DIR/lib/version.dart

# Parse the version from the pubspec file
while IFS= read -r line
do
  LABEL_REGEX='^version:'
  if [[ $line =~ $LABEL_REGEX ]]
  then
    echo "$line"
    #VERSION_REGEX='[0-9]+.[0-9]+.[0-9]+$'
    version=${line:9}
    echo $version
  fi
done < $PUBSPEC_FILE

# Write version to the dart file
echo "const appVersion = '$version';" > $DART_VERSION_FILE