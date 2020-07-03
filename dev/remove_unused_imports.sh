if [[ ! -f "./bin/remove_unused_imports" || "$1" == "build" ]]; then
    mkdir -p ./bin
    dart2native ../packages/remove_unused_imports/lib/main.dart -o ./bin/remove_unused_imports
fi
./bin/remove_unused_imports $1