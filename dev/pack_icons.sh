
if [[ ! -f "./bin/pack_icons" || "$1" == "build" ]]; then
    mkdir -p ./bin
    dart2native ../packages/pack_icons/lib/main.dart -o ./bin/pack_icons
fi
rm -fr ../packages/editor/assets/images/icon_atlases
./bin/pack_icons ../packages/editor/assets/images/icons  ../packages/editor/assets/images/icon_atlases ../packages/editor/lib/packed_icon.dart