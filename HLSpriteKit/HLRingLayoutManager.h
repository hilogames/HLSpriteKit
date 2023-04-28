//
//  HLRingLayoutManager.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 10/27/14.
//  Copyright (c) 2014 Hilo Games. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import "HLLayoutManager.h"

FOUNDATION_EXPORT const CGFloat HLRingLayoutManagerEpsilon;

/**
 Provides functionality to lay out (set positions of) nodes in a ring.  This manager may
 be attached to an `SKNode` using `[SKNode+HLLayoutManager hlSetLayoutManager]`.
*/
@interface HLRingLayoutManager : NSObject <HLLayoutManager, NSCopying, NSCoding>

/// @name Creating a Ring Layout Manager

/**
 Initializes an unconfigured ring layout manager.
*/
- (instancetype)init;

/// @name Performing a Layout

/**
 Set the positions of all passed nodes according to the layout-affecting parameters.

 For layout to have an effect: `radii` must have at least one element, and one of the
 `setThetas*` methods must have been called with non-empty parameters.

 The order of the passed nodes determines position in the ring.  A ring position is
 skipped if the corresponding element in the array is not a kind of `SKNode` class.  (It
 is suggested to pass `[NSNull null]` or `[SKNode node]` to intentionally leave positions
 empty.)

 Some configurations of a ring layout manager only make sense for a fixed number of
 nodes (see, for example, `setThetas:`).  In that case, only as many nodes will be laid
 out as the configuration can support.

 This method must always be called explicitly to realize layout changes.  On one hand,
 it's annoying to have to remember to call it; on the other hand, it allows the owner
 efficiently to make multiple changes (e.g. remove a node, insert another node, change the
 `radius`, etc) and re-layout only exactly once.
*/
- (void)layout:(NSArray *)nodes;

/**
 Layout and (optionally) return calculated final thetas.

 See `layout:` for details.

 Also see "Accessing Last-Layout State" notes in `HLLayoutManager`.
*/
- (void)layout:(NSArray *)nodes getThetas:(NSArray * __autoreleasing *)thetas;

/// @name Getting and Setting Ring Geometry

/**
 A conceptual position used for the ring during layout, in point coordinate space.

 For example, if the `ringPosition` is `(10.0, 0.0)`, all nodes laid out will have ten
 points added to their `position.x`.  Default value is `(0.0, 0.0)`.

 The ring calculated by layout uses this point as its center.
*/
@property (nonatomic, assign) CGPoint ringPosition;

/**
 An array of `CGFloat`s (wrapped in `NSNumber`) specifying the radial coordinates for each
 node laid out in the ring.

 Nodes in the ring without a corresponding radius in the array will be positioned
 according to the last radius in the array.  Thus, passing a single value in the array
 sets the radius for all laid-out nodes.
*/
@property (nonatomic, strong) NSArray *radii;

/**
 Specifies angular coordinates for each node laid out in the ring.

 If more nodes are passed to `layout:` than have corresponding values in the array, those
 nodes will not be laid out.

 @param thetasRadians The angular coordinates (represented by `NSNumber`-wrapped
                      `CGFloat`s) of each node (measured in radians, where 0 points right,
                      and increasing counter-clockwise).
*/
- (void)setThetas:(NSArray *)thetasRadians;

/**
 Specifies angular coordinates for laid-out nodes as follows: The nodes will be spread out
 at regular intervals around the ring from a starting angular coordinate ("theta").

 @param initialThetaRadians The angular coordinate of the first node on the ring (measured
                            in radians, where 0 points right, and increasing
                            counter-clockwise).
*/
- (void)setThetasWithInitialTheta:(CGFloat)initialThetaRadians;

/**
 Specifies angular coordinates for laid-out nodes as follows: The nodes will be spaced out
 incrementally around the ring from a starting angular coordinate ("theta").

 @param initialThetaRadians The angular coordinate of the first node on the ring (measured
                            in radians, where 0 points right, and increasing
                            counter-clockwise).

 @param thetaIncrementRadians The angular distance between successive nodes on the ring
                              (measured in radians, where positive values indicate the
                              counter-clockwise direction).
*/
- (void)setThetasWithInitialTheta:(CGFloat)initialThetaRadians
                   thetaIncrement:(CGFloat)thetaIncrementRadians;

/**
 Specifies angular coordinates for laid-out nodes as follows: The nodes will be spaced out
 incrementally around the ring in a cluster centered on a given angular coordinate
 ("theta").

 @param centerThetaRadians The angular coordinate of the center of the cluster of laid-out
                           nodes (measured in radians, where 0 points right, and
                           increasing counter-clockwise).

 @param thetaIncrementRadians The angular distance between successive nodes on the ring
                              (measured in radians, where positive values indicate the
                              counter-clockwise direction).  (Accordingly, a negative
                              value means the nodes will be laid out in order clockwise.)
*/
- (void)setThetasWithCenterTheta:(CGFloat)centerThetaRadians
                  thetaIncrement:(CGFloat)thetaIncrementRadians;

@end
