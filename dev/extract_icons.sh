command -v pngcrush > /dev/null || brew install pngcrush
command -v npm > /dev/null || brew install npm
cd extract_icons
[ ! -d "./node_modules" ] && npm install
echo "Getting icons from Figma..."
node index.js
if [ -f "./Rive App.zip" ]; then
    unzip -o "Rive App.zip" -d ../../packages/editor/assets/images/icons
    rm -fR "./Rive App.zip"
    cd ../../packages/editor
    flutter packages pub run image_res:main
    # Cleanup unwanted icons...
    rm "assets/images/icons/Rive App.png"
    rm "assets/images/icons/2.0x/Rive App.png"
    rm "assets/images/icons/3.0x/Rive App.png"

    # We no longer png crush here as the images get packed into an atlas.
    # for png in `find assets/images/icons -name "*.png"`;
    # do
    #     echo "crushing $png"	
    #     pngcrush -reduce -brute "$png" temp.png
    #     mv -f temp.png $png
    # done;
    cd ../../dev
    echo "Packing Atlas..."
    ./pack_icons.sh
    # Crush the atlases
    for png in `find ../packages/editor/assets/images/icon_atlases -name "*.png"`;
    do
        echo "crushing $png"	
        pngcrush -reduce -brute "$png" temp.png
        mv -f temp.png $png
    done;
    
    # rm -fr ../../packages/editor/assets/images/icons
    
    echo 'Success!'
else 
    echo "Failed to download 'Rive App.zip'"
fi
