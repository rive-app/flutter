
if [[ ! -f "./core_generator_bin" || "$1" == "build" ]]; then
    dart2native ../packages/core_generator/lib/main.dart -o core_generator_bin
fi
./core_generator_bin  --definitions-folder=./defs/ --core-context=RiveCoreContext --output-folder=../packages/rive_flutter_runtime/ --package=rive --runtime --runtime-core-folder=../packages/rive_core/
# The core generate can leave behind some dangling imports, use our tool to remove them.
./remove_unused_imports.sh ../packages/rive_flutter_runtime
# Some core properties would take a bunch of extra code to annotate, so let's just let dartfix do this for us.
if ! [ -x "$(command -v dartfix)" ]; then
  pub global activate dartfix
  exit 1
fi
dartfix --fix=annotate_overrides ../packages/rive_flutter_runtime --overwrite