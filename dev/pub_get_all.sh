#!/usr/bin/env bash

echo UPDATING utilities
cd $RIVE_ROOT/packages/utilities && pub get test && cd -
if [ $? -ne 0 ]; then
  exit 1
fi

echo UPDATING coop server
cd $RIVE_ROOT/packages/coop_server && pub get test && cd -
if [ $? -ne 0 ]; then
  exit 1
fi

echo UPDATING core
cd $RIVE_ROOT/packages/core && pub get test && cd -
if [ $? -ne 0 ]; then
  exit 1
fi

echo UPDATING editor
cd $RIVE_ROOT/packages/editor && flutter pub get test && cd -
if [ $? -ne 0 ]; then
  exit 1
fi

echo UPDATING fractional
cd $RIVE_ROOT/packages/fractional && pub get test && cd -
if [ $? -ne 0 ]; then
  exit 1
fi

echo UPDATING Rive API
cd $RIVE_ROOT/packages/rive_api && flutter pub get test && cd -
if [ $? -ne 0 ]; then
  exit 1
fi

echo UPDATING Rive core
cd $RIVE_ROOT/packages/rive_core && flutter pub get test && cd -
if [ $? -ne 0 ]; then
  exit 1
fi

echo UPDATING tree widget
cd $RIVE_ROOT/packages/tree_widget && flutter pub get test && cd -
if [ $? -ne 0 ]; then
  exit 1
fi