
if [[ ! -f "./core_generator_bin" || "$1" == "build" ]]; then
    dart2native ../packages/core_generator/lib/main.dart -o core_generator_bin
fi
./core_generator_bin  --definitions-folder=./defs/ --core-context=RiveCoreContext --output-folder=../packages/rive_flutter_runtime/ --package=rive --runtime --runtime-core-folder=../packages/rive_core/
