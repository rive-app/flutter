if [[ ! -f "./remove_unused_imports_bin" || "$1" == "build" ]]; then
    dart2native ../packages/remove_unused_imports/lib/main.dart -o remove_unused_imports_bin
fi
dart ../packages/remove_unused_imports/lib/main.dart $1