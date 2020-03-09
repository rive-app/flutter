#!/bin/bash

# A script for bootstrapping your dev environment
# NOTE: This script should be run in the root dir,
# e.g. `./dev/dev_bootstrap.sh`

# Add the following to your .bashrc, .bash_profile
# or .zshrc depending on your env:
# `export RIVE_ROOT=$HOME/<rive root dir>`

if [$RIVE_ROOT = '']
then
    echo "You haven't got RIVE_ROOT set! Do that before proceeding."
    exit 1
else
    echo "RIVE_ROOT is set to $RIVE_ROOT."
    echo "Make sure this is correct, or strange things will happen." #demigorgon
fi

# Set up git hooks for running tests on commit
git config core.hooksPath .githooks/