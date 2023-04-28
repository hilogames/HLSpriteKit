#!/bin/sh

set -e -o pipefail

xcodebuild clean build test \
           -workspace Example/HLSpriteKit.xcworkspace \
           -scheme macOS \
    | xcpretty

# note: xcpretty has a hard time handling output from multiple
# (concurrent) destinations (see
# https://github.com/supermarin/xcpretty/issues/295).  So it's just an
# aesthetic issue, but -disable-concurrent-destination-testing.
xcode_build_options=-disable-concurrent-destination-testing
xcodebuild clean build test \
           -workspace Example/HLSpriteKit.xcworkspace \
           -scheme iOS \
           -sdk iphonesimulator \
           $xcode_build_options \
           -destination 'platform=iOS Simulator,OS=16.4,name=iPhone SE (3rd generation)' \
           -destination 'platform=iOS Simulator,OS=16.4,name=iPad (10th generation)' \
           -destination 'platform=iOS Simulator,OS=16.4,name=iPhone 14' \
           ONLY_ACTIVE_ARCH=NO \
    | xcpretty

# note: Framework project (for Carthage) not currently configured for
# testing; just build.
xcodebuild clean build \
           -project HLSpriteKit.xcodeproj \
           -scheme HLSpriteKit \
           -sdk iphonesimulator \
           ONLY_ACTIVE_ARCH=NO \
    | xcpretty
