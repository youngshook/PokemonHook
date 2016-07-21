#/bin/sh

IPA="$PWD/pokemongo_hook.ipa"
if [ -f "$IPA" ]; then
    echo "Delete old file..."
    rm $IPA
fi

ln -f $TARGET_BUILD_DIR/libLocationFaker.dylib Payload/pokemongo.app/libLocationFaker.dylib

codesign -f -s "iPhone Developer: Lin Hong (CH4P9SEPHY)" ./Payload/pokemongo.app/libLocationFaker.dylib

codesign -f -s "iPhone Developer: Lin Hong (CH4P9SEPHY)" --entitlements Entitlements.plist ./Payload/pokemongo.app

xcrun -sdk iphoneos PackageApplication -v ./Payload/pokemongo.app -o $PWD/pokemongo_hook.ipa

command -v ios-deploy >/dev/null 2>&1 || { echo >&2 "Require ios-deploy but it's not installed. brew install ios-deploy.";exit 1;}

ios-deploy -c

ios-deploy -t 8 --justlaunch --no-wifi --bundle $PWD/pokemongo_hook.ipa

echo "Deploy Finish!"

exit 0;