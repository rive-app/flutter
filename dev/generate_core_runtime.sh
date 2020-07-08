
if [[ ! -f "./bin/core_generator" || "$1" == "build" ]]; then
    mkdir -p ./bin
    dart2native ../packages/core_generator/lib/main.dart -o ./bin/core_generator
fi
OUTPUT_FOLDER=../submodules/rive-flutter/
./bin/core_generator               \
  --definitions-folder=./defs/     \
  --core-context=RiveCoreContext   \
  --output-folder=$OUTPUT_FOLDER   \
  --package=rive                   \
  --runtime                        \
  --runtime-core-folder=../packages/rive_core/  \
  --packages-folder=../packages || exit 1
# The core generate can leave behind some dangling imports, use our tool to remove them.
./remove_unused_imports.sh $OUTPUT_FOLDER
# Some core properties would take a bunch of extra code to annotate, so let's just let dartfix do this for us.
if ! [ -x "$(command -v dartfix)" ]; then
  pub global activate dartfix
  exit 1
fi
dartfix --fix=annotate_overrides $OUTPUT_FOLDER --overwrite