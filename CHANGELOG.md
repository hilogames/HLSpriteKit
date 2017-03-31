
# Change Log

## 1.5.0 [2017-03-30]

## Breaking

- Came to the painful realization that I'm developing two separate
  `SKAction` alternatives, and I need to name them differently.  I
  think the new system deserves the name `HLAction`, and so I'm naming
  the old one `HLHacktion`.  This is possibly the worst name I've ever
  given anything.  
  [Karl Voskuil](https://github.com/karlvoskuil)

## Added

- Improved `HLHacktion` (formerly `HLAction`) interface and expanded
  its use-cases.  The old thing was to provide encodable actions; the
  new thing is to provide perform-selector actions that don't retain
  their target strongly.  At the same time I finally realized that the
  correct interface for these things is an class method interface
  parallel to the `SKAction` class method interface (for creating
  actions).  
  [Karl Voskuil](https://github.com/karlvoskuil)

- Added new `HLAction` system as a stateful alternative to `SKAction`.
  The main goals are statefulness during encoding, loose coupling with
  the node, and extensibility.  
  [Karl Voskuil](https://github.com/karlvoskuil)

## 1.4.0 [2016-10-28]

## Added

- Lower deployment target minimum for iOS to 8.0.  
  [Karl Voskuil](https://github.com/karlvoskuil)

## 1.3.0 [2016-10-18]

## Breaking

- To register a node to receive gestures from the scene, call
  `needsSharedGestureRecognizersForNode:` rather than
  `registerDescendant:withOptions:`.  (Option
  `HLSceneChildGestureTarget` has been removed.)  This is because
  gesture-aware nodes can be automatically detected by the scene; the
  only thing the scene needs to do is to make sure it has the proper
  gesture recognizers added to the view.  Hence, we're not
  *registering*; we're *needing gesture recognizers*.  
  [Karl Voskuil](https://github.com/karlvoskuil)

- Remove `HLToolbarNode` show and hide functionality. Such code blongs
  in the controller, not in the node. You heard me, that's where it
  blongs.  
  [Karl Voskuil](https://github.com/karlvoskuil)

## Added

- Port gesture target forwarding to macOS and `NSGestureRecognizer`.  
  [Brent Traut](https://github.com/btraut)

- Implement basic `UIResponder` and `NSResponder` user interaction
  for major components.  
  [Karl Voskuil](https://github.com/karlvoskuil)

- New `HLGridLayoutManager` for fixed-space grid layouts.  
  [Karl Voskuil](https://github.com/karlvoskuil)

## 1.2.0 [2016-09-21]

## Breaking

- Rename `HLMenuNode` property `menu` to `topMenu`. The old name
  conflicts under macOS with an inherited `NSResponder` property.  
  [Karl Voskuil](https://github.com/karlvoskuil)

## Added

- Conditional compilation for macOS / OS X.  
  [Karl Voskuil](https://github.com/karlvoskuil)

## 1.1.1 [2016-09-13]

### Fixed

- Ensure umbrella header file contains all project headers. (This
  silences a warning from Carthage, which makes everyone happy.)  
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
