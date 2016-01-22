#
#  Be sure to run `pod spec lint HLSpriteKit.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|
  s.name         = "HLSpriteKit"
  s.version      = "0.9.9"
  s.summary      = "SpriteKit scene and node subclasses, plus various utilities."
  s.description  = <<-DESC
                   `HLSpriteKit` is yet another companion library to Apple's `SpriteKit` with the goal of abstracting reusable code.
                   `HLSpriteKit`, in its current form, should probably be used in one of two ways:
                   - Non-committally: As a supply of useful custom `SKNode` subclasses, for example `HLMenuNode` (a hierarchical button menu) or `HLToolbarNode` (a simple button toolbar).
                   - Full committment: As a system for designing an interactive scene, inheriting from `HLScene` and using `UIGestureRecognizers` via `HLGestureTarget`.
                   DESC
  s.homepage     = "https://github.com/hilogames/HLSpriteKit"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Karl Voskuil" => "karl@hilogames.com" }
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/hilogames/HLSpriteKit.git", :tag => "0.9.9" }
  s.source_files = "HLSpriteKit/*"
  s.frameworks   = "Foundation", "UIKit", "SpriteKit"
  s.requires_arc = true
end
