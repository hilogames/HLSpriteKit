#!/bin/sh

set -e -o pipefail

#xcodebuild clean build test \
#           -workspace Example/HLSpriteKit.xcworkspace \
#           -scheme macOS \
#           -sdk macosx10.12 \
#           -destination 'platform=macOS' \
#           ONLY_ACTIVE_ARCH=NO CODE_SIGN_IDENTITY='' CODE_SIGNING_REQUIRED=NO

# note: Would like to do test of OS=8.4, but xcodebuild hangs after simulator launch.
# Just build it.
xcodebuild clean build \
           -workspace Example/HLSpriteKit.xcworkspace \
           -scheme iOS \
           -sdk iphonesimulator10.0 \
           -destination 'platform=iOS Simulator,OS=8.4,name=iPhone 5s' \
           ONLY_ACTIVE_ARCH=NO

xcodebuild clean build test \
           -workspace Example/HLSpriteKit.xcworkspace \
           -scheme iOS \
           -sdk iphonesimulator10.0 \
           -destination 'platform=iOS Simulator,OS=9.0,name=iPad 2' \
           -destination 'platform=iOS Simulator,OS=latest,name=iPhone 6' \
           ONLY_ACTIVE_ARCH=NO
