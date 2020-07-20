#!/bin/bash

# FLUTTER_ROOT must be set
if [[ -z ${FLUTTER_ROOT+x} ]]; then
    echo "FLUTTER_ROOT is unset"
    return
fi

# RIVE_ROOT must be set
if [[ -z ${RIVE_ROOT+x} ]]; then
    echo "RIVE_ROOT is unset"
    return
fi

VERSION_FILE=".flutter_version"

# .flutter_version must exist
if [[ ! -f "$RIVE_ROOT/$VERSION_FILE" ]]; then
    echo "$VERSION_FILE doesn't exist"
    return
fi

# read the flutter version from the file
TAG=$(<$RIVE_ROOT/$VERSION_FILE)
echo $TAG

cd $FLUTTER_ROOT

# set the correct tag
git checkout tags/$TAG

# trigger Flutter to sort itself out
flutter doctor

popd
echo "Flutter set to $TAG"