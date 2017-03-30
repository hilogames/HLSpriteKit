#!/bin/sh

travis=0
if [ "$1" = travis ]; then
    travis=1
fi

set -e -o pipefail

if (( $travis )); then

    # note: Couldn't get this to run on TravisCI, but builds fine
    # locally.
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
# note: TravisCI seems to need a verison-specified SDK.  Match it to
# the osx_image in .travis.yml.  Reference:
#   https://docs.travis-ci.com/user/osx-ci-environment
if (( $travis )); then
    sdk_iphonesimulator=iphonesimulator10.3
fi

# note: Would like to do test of iOS8, but xcodebuild hangs after
# simulator launch.  Just build it.
xcodebuild clean build \
           -workspace Example/HLSpriteKit.xcworkspace \
           -scheme iOS \
           -sdk $sdk_iphonesimulator \
           -destination 'platform=iOS Simulator,OS=8.4,name=iPhone 5s' \
           ONLY_ACTIVE_ARCH=NO \
    | xcpretty

xcodebuild clean build test \
           -workspace Example/HLSpriteKit.xcworkspace \
           -scheme iOS \
           -sdk $sdk_iphonesimulator \
           -destination 'platform=iOS Simulator,OS=9.3,name=iPad 2' \
           -destination 'platform=iOS Simulator,OS=latest,name=iPhone 6' \
           ONLY_ACTIVE_ARCH=NO \
    | xcpretty

# note: Framework project (for Carthage) not currently configured for
# testing; just build.
xcodebuild clean build \
           -project HLSpriteKit.xcodeproj \
           -scheme HLSpriteKit \
           -sdk $sdk_iphonesimulator \
           ONLY_ACTIVE_ARCH=NO \
    | xcpretty
