#!/bin/sh

travis=0
if [ "$1" = travis ]; then
    travis=1
fi

set -e -o pipefail

if (( $travis )); then

    # note: Couldn't get this to test on TravisCI, but builds, anyway.
    #
    #  Assertion failed: (*shader), function xglCompileShader, file /BuildRoot/Library/Caches/com.apple.xbs/Sources/Jet/Jet-2.6.1/Jet/xgl_utils.mm, line 24.
    #  2016-09-21 17:13:00.353 xcodebuild[1406:4641] Error Domain=IDETestOperationsObserverErrorDomain Code=5 "Early unexpected exit, operation never finished bootstrapping - no restart will be attempted" UserInfo={NSLocalizedDescription=Early unexpected exit, operation never finished bootstrapping - no restart will be attempted}
    #  Test target macOS-Tests encountered an error (Early unexpected exit, operation never finished bootstrapping - no restart will be attempted)
    #  The command "./test.sh" exited with 65.
    #
    # The failed assertion seems to have something to do with trying
    # to run SpriteKit on a virtual machine.  This makes me hope it's
    # a problem that will be fixed in the next release of the SDK.
    #
    # Here are some things I tried before giving up:
    #
    #     -sdk macosx10.12 \
    #     -destination 'platform=macOS' \
    #     ONLY_ACTIVE_ARCH=NO CODE_SIGN_IDENTITY='' CODE_SIGNING_REQUIRED=NO \
    #
    xcodebuild clean build \
               -workspace Example/HLSpriteKit.xcworkspace \
               -scheme macOS \
        | xcpretty

else

    xcodebuild clean build test \
               -workspace Example/HLSpriteKit.xcworkspace \
               -scheme macOS \
        | xcpretty

fi

sdk_iphonesimulator=iphonesimulator
# note: TravisCI sometimes seems to need a version-specified SDK.
# Match it to the osx_image in .travis.yml.  Reference:
#   https://docs.travis-ci.com/user/reference/osx/
# But the TravisCI failure was just the generic "Test target iOS-Tests
# encountered an error", on a day with operational troubles, so it
# might be a transient thing.
if (( $travis )); then
    sdk_iphonesimulator=iphonesimulator16.2
fi

# note: xcpretty has a hard time handling output from multiple
# (concurrent) destinations (see
# https://github.com/supermarin/xcpretty/issues/295).  So it's just an
# aesthetic issue, but -disable-concurrent-destination-testing.
xcode_build_options=-disable-concurrent-destination-testing
# The option doesn't exist until Xcode 10.0, so if using osx_image9.4
# in Travis CI, then can't use it.
#if (( $travis )); then
#    xcode_build_options=""
#fi

# note: Travis osx_image sometimes provides different destinations
# than my current osx, even though I generally use the latest
# available in Travis and locally.  See:
#   https://docs.travis-ci.com/user/reference/osx/
# Note that "OS=latest" refers to the latest OS, and not the latest
# available for a certain name, so when using "latest" must choose a
# destination that actually has the latest OS available.
if (( $travis )); then
    xcodebuild clean build test \
               -workspace Example/HLSpriteKit.xcworkspace \
               -scheme iOS \
               -sdk $sdk_iphonesimulator \
               $xcode_build_options \
               -destination 'platform=iOS Simulator,OS=16.2,name=iPhone 14' \
               ONLY_ACTIVE_ARCH=NO \
        | xcpretty
else
    xcodebuild clean build test \
               -workspace Example/HLSpriteKit.xcworkspace \
               -scheme iOS \
               -sdk $sdk_iphonesimulator \
               $xcode_build_options \
               -destination 'platform=iOS Simulator,OS=16.4,name=iPhone SE (3rd generation)' \
               -destination 'platform=iOS Simulator,OS=16.4,name=iPad (10th generation)' \
               -destination 'platform=iOS Simulator,OS=16.4,name=iPhone 14' \
               ONLY_ACTIVE_ARCH=NO \
        | xcpretty
fi

# note: Framework project (for Carthage) not currently configured for
# testing; just build.
xcodebuild clean build \
           -project HLSpriteKit.xcodeproj \
           -scheme HLSpriteKit \
           -sdk $sdk_iphonesimulator \
           ONLY_ACTIVE_ARCH=NO \
    | xcpretty
