
if [[ ! -f "./pack_icons_bin" || "$1" == "build" ]]; then
    dart2native ../packages/pack_icons/lib/main.dart -o pack_icons_bin
fi
rm -fr ../packages/editor/assets/images/icon_atlases
./pack_icons_bin ../packages/editor/assets/images/icons  ../packages/editor/assets/images/icon_atlases ../packages/editor/lib/packed_icon.dart
#./pack_icons_bin ../packages/editor/assets/images/icons/2.0x  ../packages/editor/assets/images/icon_atlases/2x
#./pack_icons_bin ../packages/editor/assets/images/icons/3.0x  ../packages/editor/assets/images/icon_atlases/3x