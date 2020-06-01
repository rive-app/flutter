
if [[ ! -f "./pack_icons_bin" || "$1" == "build" ]]; then
    dart2native ../packages/pack_icons/lib/main.dart -o pack_icons_bin
fi
rm -fr ../packages/editor/assets/images/icon_atlases
./pack_icons_bin ../packages/editor/assets/images/icons  ../packages/editor/assets/images/icon_atlases ../packages/editor/lib/packed_icon.dart