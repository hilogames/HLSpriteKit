#!/bin/sh

set -e -o pipefail

xcodebuild clean build test \
           CODE_SIGN_IDENTITY='' CODE_SIGNING_REQUIRED=NO \
           -workspace Example/HLSpriteKit.xcworkspace \
           -scheme macOS \
           -destination 'platform=macOS' \
    | xcpretty

# note: Would like to do test of OS=8.4, but xcodebuild hangs after simulator launch.
# Just build it.
xcodebuild clean build \
           -workspace Example/HLSpriteKit.xcworkspace \
           -scheme iOS \
           -sdk iphonesimulator10.0 \
           -destination 'platform=iOS Simulator,OS=8.4,name=iPhone 5s' \
    | xcpretty

xcodebuild clean build test \
           -workspace Example/HLSpriteKit.xcworkspace \
           -scheme iOS \
           -sdk iphonesimulator10.0 \
           -destination 'platform=iOS Simulator,OS=9.0,name=iPad 2' \
           -destination 'platform=iOS Simulator,OS=latest,name=iPhone 6' \
    | xcpretty
