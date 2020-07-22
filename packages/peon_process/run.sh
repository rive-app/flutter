#!/bin/bash
echo "starting xvfb session"
/usr/bin/Xvfb :99 &
export DISPLAY=:99

echo "starting flutter"
flutter run -d linux