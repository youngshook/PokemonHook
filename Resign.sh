#/bin/sh

codesign -f -s "iPhone Developer: XXXXXXXXXX (XXXXXXXXXX)" ./Payload/pokemongo.app/PokemonHook.dylib

codesign -f -s "iPhone Developer: XXXXXXXXXX (XXXXXXXXXX)" --entitlements Entitlements.plist ./Payload/pokemongo.app

xcrun -sdk iphoneos PackageApplication -v ./Payload/pokemongo.app -o $PWD/pokemongo_hook.ipa