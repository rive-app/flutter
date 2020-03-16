#!/bin/bash

# Takes a folder of Figma-exported icons, sorts and renames them,
# them moves them to the editor assets folder

# Directory of this script
SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
EDITOR_ROOT_DIR=$SCRIPTPATH/../packages/editor
ICON_DIR=$EDITOR_ROOT_DIR/assets/images/icons

# Takes a folder containing the Figma icons
if [[ $# -ne 1 ]]; then
    echo Path to the exported Figma icons folder required
    return
fi

# Check the directory exists
if [[ ! -d $1 ]]
then
    echo Directory $1 does not exist
    return
fi

# Copy all the icons to the editor's asset folder
cp $1/*.png $ICON_DIR

# Use the flutter package to rename and move the icons
pushd $EDITOR_ROOT_DIR
flutter packages pub run image_res:main
popd

echo Import complete