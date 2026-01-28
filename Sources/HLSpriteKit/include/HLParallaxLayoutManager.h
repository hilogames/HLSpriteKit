//
//  HLParallaxLayoutManager.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 6/11/2018.
//  Copyright (c) 2018 Hilo Games. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import "HLLayoutManager.h"

FOUNDATION_EXPORT const CGFloat HLParallaxLayoutManagerEpsilon;

/**
 Provides functionality to lay out (set positions of) nodes using a parallax effect.  This
 manager may be attached to an `SKNode` using `[SKNode+HLLayoutManager
 hlSetLayoutManager]`.

 The manager has a single `offset`, which offsets each node from the overall manager
 `parallaxPosition`.

 However, the `speed` of each node multiplies its offset, increasing or decreasing its
 offset.  When the offset is changed continuously, this leads to a parallax effect, where
 nodes moving more slowly appear to be farther away.

 Speeds for each node may be specified manually using the `speeds` property, or may be
 calculated according to the viewing model.

 ### The Viewing Model

   \-------/  world plane
    \     /
     \---/    image plane
      \ /
      <o>     eye (or viewing point, or virtual camera)

 The speeds calculated are a simple ratio of: 1) the distance from eye to image plane;
 and 2) the distance from eye to world plane.  This information can be parameterized a few
 different ways, according to the caller's convenience; see the various `setSpeeds`
 methods.

 As simple ratios, the speeds can be used as scales for sizing distant objects, too.
*/
@interface HLParallaxLayoutManager : NSObject <HLLayoutManager, NSCopying, NSCoding>

/// @name Creating a Parallax Layout Manager

/**
 Initializes an unconfigured parallax layout manager.
*/
- (instancetype)init;

/**
 Initializes the layout manager with parameters for a customized parallax layout of nodes.
*/
- (instancetype)initWithSpeeds:(NSArray *)speeds;

/**
 Initializes the layout manager with parameters for a customized parallax layout of nodes.

 See `setSpeedsWithNormalDistances:` for details.
*/
- (instancetype)initWithNormalDistances:(NSArray *)normalDistancesFromImagePlane;

/**
 Initializes the layout manager with parameters for a customized parallax layout of nodes.

 See `setSpeedsWithViewingDistance:distances:` for details.
*/
- (instancetype)initWithViewingDistance:(CGFloat)viewingDistance
                              distances:(NSArray *)distancesFromImagePlane;

/**
 Initializes the layout manager with parameters for a customized parallax layout of nodes.

 See `setSpeedsWithFieldOfView:imagePlaneSize:distances:` for details.
*/
- (instancetype)initWithFieldOfView:(CGFloat)fieldOfViewRadians
                     imagePlaneSize:(CGFloat)imagePlaneSize
                          distances:(NSArray *)distancesFromImagePlane;

/**
 Initializes the layout manager with parameters for a customized parallax layout of nodes.

 See `setSpeedsForParallaxPanningWithViewportSize:panningRange:layerSizes:` for details.
*/
- (instancetype)initForParallaxPanningWithViewportSize:(CGFloat)viewportSize
                                          panningRange:(CGFloat)panningRange
                                            layerSizes:(NSArray *)layerSizes;

/**
 Initializes the layout manager with parameters for a customized parallax layout of nodes.

 See `setSpeedsForParallaxPanningWithViewportSize:panningRange:layerSizes:` for details.
*/
- (instancetype)initForParallaxPanningWithViewportSize:(CGFloat)viewportSize
                                          panningRange:(CGFloat)panningRange
                                            layerCount:(NSUInteger)layerCount
                                        firstLayerSize:(CGFloat)firstLayerSize
                                         lastLayerSize:(CGFloat)lastLayerSize;

/// @name Performing a Layout

/**
 Set the positions of all passed nodes according to the layout-affecting parameters.

 The speed of each node multiplies its offset from the layout manager's origin (at the
 `parallaxPosition`).  See `speeds` for details.

 This method must always be called explicitly to realize layout changes.  On one hand,
 it's annoying to have to remember to call it; on the other hand, it allows the owner
 efficiently to make multiple changes (e.g. remove a node, insert another node, change the
 position, etc) and re-layout only exactly once.
*/
- (void)layout:(NSArray *)nodes;

/// @name Getting and Setting Parallax Geometry

/**
 A conceptual position used for the manager during layout, in point coordinate space.

 For example, if the `parallaxPosition` is `(10.0, 0.0)`, all nodes laid out will have ten
 points added to their `position.x`.  Default value is `(0.0, 0.0)`.

 The node offsets calculated by layout use this point as their origin.
*/
@property (nonatomic, assign) CGPoint parallaxPosition;

/**
 The offset (from `parallaxPosition`) applied to all nodes, in point coordinate space.

 Each node has a speed that scales the offset as it is applied.  See `speeds`.
*/
@property (nonatomic, assign) CGPoint offset;

/**
 An array of `CGFloat`s (wrapped in `NSNumber`) specifying the speeds to be used for
 offsetting nodes during layout.

 Nodes in the layout without corresponding speeds in the array will be offset according to
 the last speed in the array.  If the array is `nil` or empty, all nodes will be offset
 with a speed of `1.0`.

 A parallax scrolling effect can be achieved by using different speeds for different
 nodes:

   - A speed of one is used for nodes directly on the image plane (or foreground).

   - Speeds less than one are used for distant nodes.  The slower the node moves, the more
     distant it seems.  A speed of zero would be used for a node infinitely far away.

   - Speeds greater than one are used for nodes that appear to pass between the viewer
     and the image plane.  A speed of infinity would be used for a node directly at the
     viewer's eyeball (so that it cannot be seen unless its offset is zero).

 Use the various `setSpeeds` methods to calculate speeds given various parameters of the
 viewing model.

 Because speeds are simple scaling ratios, they can be used as general-purpose scaling
 for distant objects -- in particular, for sizes as well as speeds.  For that purpose, the
 speeds can be directly accessed from this property after they have been assigned or
 calculated.
*/
@property (nonatomic, strong) NSArray *speeds;

/**
 Convenience method to calculate `speeds` given certain parameters of the viewing model.

 This method allows setting speed ratios using distance ratios.  The calculated speeds are
 simply the inverse of the distances, but this method can nevertheless be slightly more
 intuitive to use.

 The distances provided are the distances from the image plane to the world planes.  The
 normalized distance unit used is carefully chosen: It's the distance from the eye to the
 image plane.

 For example, if the virtual camera in a game world is considered to be 20 feet away from
 Jungle Patricia (as she swings from vine to vine), then 20 feet is the normalized
 distance unit.  Jungle Patricia and her vines are at distance 0.0, on the image plane;
 the next row of kapok trees are at distance 0.5 (in the world, 10 feet); occasionally
 a macaw flies between Patricia and the virtual camera, at distance -0.2 (in the world,
 4 feet).

 (Although normalized distances are used here to calculate speeds, the parallax manager
 `offset` will still be specified in point coordinate space.)
*/
- (void)setSpeedsWithNormalDistances:(NSArray *)normalDistancesFromImagePlane;

/**
 Convenience method to calculate `speeds` given certain parameters of the viewing model.

 In this version, the model is specified by the distance of the eye to the image plane
 (the "viewing distance") and an array of distances of world planes (from image plane).
 The distances must share the same unit, but the choice of unit is left to the discrection
 of the caller.

 For example, if the virtual camera in a game world is considered to be 20 feet away from
 Jungle Patricia (as she swings from vine to vine), then Jungle Patricia and her vines are
 at distance 0.0, on the image plane; the next row of kapok trees are 10 feet behind her,
 so they have a distance of 10.0; occasionally a macaw flies between Patricia and the
 virtual camera, at distance -4.0 feet.

 (Although the distance unit here may be chosen by the caller, the parallax manager
 `offset` will still use point coordinate space.)
*/
- (void)setSpeedsWithViewingDistance:(CGFloat)viewingDistance
                           distances:(NSArray *)distancesFromImagePlane;

/**
 Convenience method to calculate `speeds` given certain parameters of the viewing model.

 In this version, the model is specified by field of view, image plane size, and an array
 of distances of world layers (from image plane).

 The field of view dimension must correpond to the dimension of the image plane size;
 for instance, a horizontal field of view angle should correspond to a image plane width.

 The units used for image plane size and world distances must be the same.  However, the
 choice of unit is left to the discretion of the caller.  For example:

 - If the caller considers the image plane to be 15 feet wide (because it can fit five
   large orcs standing shoulder to shoulder), then distances to world layers should be
   measured in those same world units: Perhaps another row of orcs is standing six feet
   behind the first row.

 - But if the caller considers the image plane to be a viewport 480 points wide (matching
   the screen width of a device), then distances to world layers should be measured in
   points also.

 (Although the distance unit here may be chosen by the caller, the parallax manager
 `offset` will still use point coordinate space.)
*/
- (void)setSpeedsWithFieldOfView:(CGFloat)fieldOfViewRadians
                  imagePlaneSize:(CGFloat)imagePlaneSize
                       distances:(NSArray *)distancesFromImagePlane;

/**
 Convenience method to calculate `speeds` given certain parameters of the viewing model.

 Use this method to do a parallax pan of a set of layers.

 The range of the pan is assumed to be from one edge of the layer set to the other,
 keeping them always within the viewport.  For this reason, the viewport size is required
 (and is subtracted from the layer sizes before calculating speed ratios).  (If a layer is
 smaller than the viewport, it will be assigned a negative speed.  Kinda interesting.)

 The panning range allows the user to choose her own arbitrary range of offsets when
 panning.

 ### Example

 Say the caller wants to parallax pan across three layers of art assets: a foreground
 crowd of people (960 points), a middle-ground row of building facades (720 points), and
 a background skyline (480 points).  Her viewport is 480 points wide.  The layers and
 the parallax layout manager are all anchored by their center points.  She decides, for no
 particular reason, that her panning range will be 100; that is, she will pan from left to
 right by animating the parallax manager offset from `(50, 0)` to `(-50, 0)`.  (She would
 pan from `100` to `0` if the images were right-anchored.)  Here are the calculations:

   - The skyline is the same width as the viewport, and so it will have speed `0.0` and
     stay pinned to the origin no matter what the offset.

   - Edge-to-edge panning of the viewport (480 points) across the building facades asset
     (720 points) means panning from `120` to `-120`.  This must map to the panning range
     of `50` to `-50`, so the proportional speed is `240 / 100 = 2.4`.

   - Similar math for the panning the 960-point crowd image: `(960 - 480) / 100 = 4.8`.
*/
- (void)setSpeedsForParallaxPanningWithViewportSize:(CGFloat)viewportSize
                                       panningRange:(CGFloat)panningRange
                                         layerSizes:(NSArray *)layerSizes;


/**
 Convenience method to calculate `speeds` given certain parameters of the viewing model.

 Use this method to do a parallax pan of a set of layers.

 See `setSpeedsForParallaxPanningWithViewportSize:panningRange:layerSizes:`.  This method
 works the same way, but calculates layer sizes by interpolating within a range.
*/
- (void)setSpeedsForParallaxPanningWithViewportSize:(CGFloat)viewportSize
                                       panningRange:(CGFloat)panningRange
                                         layerCount:(NSUInteger)layerCount
                                     firstLayerSize:(CGFloat)firstLayerSize
                                      lastLayerSize:(CGFloat)lastLayerSize;

@end
