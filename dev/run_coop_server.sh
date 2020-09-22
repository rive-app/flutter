if [[ ! -f "./bin/coop_server_process" || "$1" == "build" ]]; then
    mkdir -p ./bin
    dart2native ../packages/coop_server_process/lib/main.dart -o ./bin/coop_server_process
fi

./bin/coop_server_process --data-folder=./dat

#dart --observe ../packages/coop_server_process/lib/main.dart --data-folder=./dat
