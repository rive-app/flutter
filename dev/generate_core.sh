
if [[ ! -f "./bin/core_generator" || "$1" == "build" ]]; then
    mkdir -p ./bin
    dart2native ../packages/core_generator/lib/main.dart -o ./bin/core_generator
fi
./bin/core_generator --definitions-folder=./defs/ --core-context=RiveCoreContext --output-folder=../packages/rive_core/ --package=rive_core || exit 1
./remove_unused_imports.sh ../packages/rive_core
# Some core properties would take a bunch of extra code to annotate, so let's just let dartfix do this for us.
if ! [ -x "$(command -v dartfix)" ]; then
  pub global activate dartfix
  exit 1
fi
dartfix --fix=annotate_overrides ../packages/rive_core --overwrite