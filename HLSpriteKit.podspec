
Pod::Spec.new do |s|
  s.name         = "HLSpriteKit"
  s.version      = "2.1.0"
  s.summary      = "SpriteKit scene and node subclasses, plus various utilities."
  s.description  = <<-DESC
                   `HLSpriteKit` is yet another companion library to Apple's `SpriteKit` with the goal of abstracting reusable code.
                   `HLSpriteKit`, in its current form, should probably be used in one of two ways:
                   - Non-committally: As a supply of useful utilities and custom `SKNode` subclasses.
                   - Full committment: As a system for designing an interactive scene, inheriting from `HLScene` and using gesture recognizers via `HLGestureTarget`.
                   DESC
  s.homepage     = "https://github.com/hilogames/HLSpriteKit"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Karl Voskuil" => "karl@hilogames.com" }
  s.source       = { :git => "https://github.com/hilogames/HLSpriteKit.git", :tag => s.version.to_s }
  s.source_files = "HLSpriteKit/*"
  s.requires_arc = true

  s.ios.deployment_target = "12.0"
  s.ios.frameworks        = "Foundation", "UIKit", "SpriteKit"

  s.osx.deployment_target = "10.13"
  s.osx.frameworks        = "Foundation", "SpriteKit"
end
