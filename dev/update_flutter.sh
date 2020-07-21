#!/bin/bash

# exit on error
set -e

# FLUTTER_ROOT must be set
if [[ -z ${FLUTTER_ROOT+x} ]]; then
    echo "FLUTTER_ROOT is unset"
    exit 1
fi

# RIVE_ROOT must be set
if [[ -z ${RIVE_ROOT+x} ]]; then
    echo "RIVE_ROOT is unset"
    exit 1
fi

VERSION_FILE=".flutter_version"

# .flutter_version must exist
if [[ ! -f "$RIVE_ROOT/$VERSION_FILE" ]]; then
    echo "$VERSION_FILE doesn't exist"
    exit 1
fi

# read the flutter version from the file
TAG=$(<$RIVE_ROOT/$VERSION_FILE)
echo $TAG

pushd $FLUTTER_ROOT

# update the local repository with new info from github
git fetch

# set the correct tag
git checkout tags/$TAG

# trigger Flutter to sort itself out
flutter doctor

popd
echo "Flutter set to $TAG"