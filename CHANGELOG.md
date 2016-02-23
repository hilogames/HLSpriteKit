
# Change Log

## Master

### Breaking

- Move the class category methods in
  `SKSpriteNode+HLSpriteNodeAdditions` to a category on `SKNode`, now
  in the file `SKNode+HLNodeVisuals`.  
  [Karl Voskuil](https://github.com/karlvoskuil)

### Added

- Implement in `HLAction.h` a number of encodable alternatives to
  block-related `SKAction`s like `runBlock:`.  These allow running
  custom animations through application state preservation and
  restoration.  
  [Karl Voskuil](https://github.com/karlvoskuil)

## 0.9.9

### Breaking

- Move the class category methods in
  `SKSpriteNode+HLSpriteNodeAdditions` to a category on `SKNode`, now
  in the file `SKNode+HLNodeVisuals`.  
  [Karl Voskuil](https://github.com/karlvoskuil)

### Added

- Make `HLMenuNode` accept different types of nodes as buttons : now,
  any node can be used if it responds to the correct selectors
  (currently `size`, and `setAnchorPoint:`).  
  [Karl Voskuil](https://github.com/karlvoskuil)

- Add content clipping to `HLScrollNode`, so that content outside the
  scroll node's overall size is cropped out (using an `SKCropNode`).
  See property `contentClipped`.  
  [Karl Voskuil](https://github.com/karlvoskuil)

- Implement in `HLAction.h` a number of encodable alternatives to
  block-related `SKAction`s like `runBlock:`.  These allow running
  custom animations through application state preservation and
  restoration.  
  [Karl Voskuil](https://github.com/karlvoskuil)
