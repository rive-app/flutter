if [[ ! -f "./bin/runtime_analyzer" || "$1" == "build" ]]; then
    mkdir -p ./bin
    dart2native ../packages/runtime_analyzer/lib/main.dart -o ./bin/runtime_analyzer
fi
./bin/runtime_analyzer --definitions-folder=./defs/ $@
