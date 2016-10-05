
# Change Log

## Master

## Breaking

- Remove `HLToolbarNode` show and hide functionality. Such code blongs
  in the controller, not in the node.  
  [Karl Voskuil](https://github.com/karlvoskuil)

## Added

- Implement basic `UIResponder` and `NSResponder` user interaction
  for major components.  
  [Karl Voskuil](https://github.com/karlvoskuil)

## 1.2.0 [2016-09-21]

## Breaking

- Rename `HLMenuNode` property `menu` to `topMenu`. The old name
  conflicts under OS X with an inherited `NSResponder` property.  
  [Karl Voskuil](https://github.com/karlvoskuil)

## Added

- Conditional compilation for OS X / MacOS.  
  [Karl Voskuil](https://github.com/karlvoskuil)

## 1.1.1 [2016-09-13]

### Fixed

- Ensure umbrella header file contains all project headers. (This silences
  a warning from Carthage, which makes everyone happy.)  
  [Brent Traut](https://github.com/btraut)

## 1.1.0

### Breaking

- Add `contentClipped` option to `HLToolbarNode`. As in
  `HLScrollNode`, the result of clipping content is to add an
  `SKCropNode` to the internal node tree. The breaking change is the
  default: `NO`, which means the setting-tools animations in
  `HLToolbarNode` will look silly by default. However, keeping
  `SKCropNode` out of the node tree prevents a seeming multitude of
  problems when another crop node or `SKEffectNode` exist in the same
  scene as a toolbar.  
  [Karl Voskuil](https://github.com/karlvoskuil)

- Remove `HLTextureStore`. It has proven not general enough for
  reuse. In the unlikely case you are upset by this, I will buy you a
  beer and code up a replacement.  
  [Karl Voskuil](https://github.com/karlvoskuil)

- Drop support for iOS 7.  
  [Karl Voskuil](https://github.com/karlvoskuil)

### Added

- Add support for Carthage.  
  [Brent Traut](https://github.com/btraut)

- Add `HLMultilineLabelNode`. I know, I know, there are other
  implementations already freely available. But this one is mine.  
  [Karl Voskuil](https://github.com/karlvoskuil)

## 1.0.0

### Breaking

- Move the class category methods in
  `SKSpriteNode+HLSpriteNodeAdditions` to a category on `SKNode`, now
  in the file `SKNode+HLNodeVisuals`.  
  [Karl Voskuil](https://github.com/karlvoskuil)

### Added

- Implement in `HLAction.h` a number of encodable alternatives to
  block-related `SKAction`s like `runBlock:` and
  `customActionWithDuration:actionBlock:`.  These allow running custom
  animations through application state preservation and
  restoration.  
  [Karl Voskuil](https://github.com/karlvoskuil)

- Conform a few more classes to `NSCoding`.  Also, by convention
  encode delegates (for any class that has a delegate) using
  `encodeConditionalObject:forKey:`.  
  [Karl Voskuil](https://github.com/karlvoskuil)

## 0.9.9

### Added

- Make `HLMenuNode` accept different types of nodes as buttons: now,
  any node can be used if it responds to the correct selectors
  (currently `size` and `setAnchorPoint:`).  
  [Karl Voskuil](https://github.com/karlvoskuil)

- Add content clipping to `HLScrollNode`, so that content outside the
  scroll node's overall size is cropped out (using an `SKCropNode`).
  See property `contentClipped`.  
  [Karl Voskuil](https://github.com/karlvoskuil)
