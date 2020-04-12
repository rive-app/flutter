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
    echo 'Success!'
else 
    echo "Failed to download 'Rive App.zip'"
fi
