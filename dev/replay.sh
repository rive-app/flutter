if [[ ! -f "./bin/replay" || "$1" == "build" ]]; then
    mkdir -p ./bin
    dart2native ../packages/coop_replay/lib/main.dart -o ./bin/replay
fi
./bin/replay --definitions-folder=./defs/ $@
