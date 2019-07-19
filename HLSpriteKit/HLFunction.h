//
//  HLFunction.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 7/18/19.
//  Copyright © 2019 Hilo Games. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

/**
 A model of a cubic Bezier function.
*/
@interface HLCubicBezier : NSObject

/**
 Returns an initialized cubic Bezier curve.

 @param p0 The first control point of the cubic Bezier.

 @param p1 The second control point of the cubic Bezier.

 @param p2 The third control point of the cubic Bezier.

 @param p3 The fourth control point of the cubic Bezier.
*/
- (instancetype)initWithP0:(CGPoint)p0 p1:(CGPoint)p1 p2:(CGPoint)p2 p3:(CGPoint)p3;

/**
 Returns a point on the cubic Bezier curve given a `t` value between `0` and `1`.
*/
- (CGPoint)pointForT:(CGFloat)t;

@end

/**
 Defines a "flight" path from one point on the "ground" to another point on the "ground".

 The start and finish points are provided by the owner in the coordinate system of the
 owner's preference.  The shape of the trajectory, however, is imagined as a cubic Bezier
 in unit coordinate space from P0 `(0, 0)` to P3 `(1, 0)`; the owner provides P1 and P2
 control points in unit coordinate space.  That shape is translated, scaled, and skewed to
 fit the owner's original start and finish points, with the help of one more parameter: a
 height to scale the unit Bezier y-dimension.
*/
@interface HLTrajectoryBezier : NSObject

/**
 Returns an initialized trajectory Bezier object.

 @param startLocation The start point of the trajectory, in the owner's coordinate space.

 @param finishLocation The end point of the trajectory, in the owner's coordinate space.

 @param shapeP1 The second control point for the cubic Bezier defining the shape of the
                trajectory, in unit coordinate space.

 @param shapeP2 The third control point for the cubic Bezier defining the shape of the
                trajectory, in unit coordinate space.

 @param height The scaling factor applied to the height of the cubic Bezier in order to
               scale from unit coordinate space to owner coordinate space.
*/
- (instancetype)initWithStart:(CGPoint)startLocation
                       finish:(CGPoint)finishLocation
                      shapeP1:(CGPoint)shapeP1
                      shapeP2:(CGPoint)shapeP2
                       height:(CGFloat)height;

/**
 Returns a point on the trajectory given a `t` value between `0` and `1`.
*/
- (CGPoint)pointForT:(CGFloat)t;

@end

/**
 A model of a piecewise linear function.
*/
@interface HLPiecewiseLinearFunction : NSObject

/**
 Returns an initialized piecewise linear function object.

 @param knotXValues The X values for the function's knots, which are the end points of the
                    rays and line segments constituting the piecewise linear function.

 @param knotYValues The Y values for the function's knots, which are the end points of the
                    rays and line segments constituting the piecewise linear function.
*/
- (instancetype)initWithKnotXValues:(NSArray *)knotXValues
                        knotYValues:(NSArray *)knotYValues;

/**
 Solves Y in the the piecewise linear function for a given X.
*/
- (CGFloat)yForX:(CGFloat)x;

@end
