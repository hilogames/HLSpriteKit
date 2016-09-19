
Pod::Spec.new do |s|
  s.name         = "HLSpriteKit"
  s.version      = "1.1.1"
  s.summary      = "SpriteKit scene and node subclasses, plus various utilities."
  s.description  = <<-DESC
                   `HLSpriteKit` is yet another companion library to Apple's `SpriteKit` with the goal of abstracting reusable code.
                   `HLSpriteKit`, in its current form, should probably be used in one of two ways:
                   - Non-committally: As a supply of useful custom `SKNode` subclasses, for example `HLScrollNode` (a node equivalent of `UIScrollView`) or `HLToolbarNode` (a simple button toolbar).
                   - Full committment: As a system for designing an interactive scene, inheriting from `HLScene` and using `UIGestureRecognizers` via `HLGestureTarget`.
                   DESC
  s.homepage     = "https://github.com/hilogames/HLSpriteKit"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Karl Voskuil" => "karl@hilogames.com" }
  s.source       = { :git => "https://github.com/hilogames/HLSpriteKit.git", :tag => s.version.to_s }
  s.source_files = "HLSpriteKit/*"
  s.requires_arc = true

  s.ios.deployment_target = "8.4"
  s.ios.frameworks        = "Foundation", "UIKit", "SpriteKit"

  s.osx.deployment_target = "10.10"
  s.osx.frameworks        = "Foundation", "SpriteKit"
end
