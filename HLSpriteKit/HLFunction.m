//
//  HLFunction.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 7/18/19.
//  Copyright © 2019 Hilo Games. All rights reserved.
//

#import "HLFunction.h"

@implementation HLCubicBezier
{
  CGPoint _p0;
  CGFloat _coefficientsX[3];
  CGFloat _coefficientsY[3];
}

- (instancetype)initWithP0:(CGPoint)p0 p1:(CGPoint)p1 p2:(CGPoint)p2 p3:(CGPoint)p3
{
  self = [super init];
  if (self) {
    _p0 = p0;
    _coefficientsX[0] = p3.x - 3.0f * p2.x + 3.0f * p1.x - p0.x;
    _coefficientsY[0] = p3.y - 3.0f * p2.y + 3.0f * p1.y - p0.y;
    _coefficientsX[1] = 3.0f * p2.x - 6.0f * p1.x + 3.0f * p0.x;
    _coefficientsY[1] = 3.0f * p2.y - 6.0f * p1.y + 3.0f * p0.y;
    _coefficientsX[2] = 3.0f * p1.x - 3.0f * p0.x;
    _coefficientsY[2] = 3.0f * p1.y - 3.0f * p0.y;
  }
  return self;
}

- (CGPoint)pointForT:(CGFloat)t
{
  CGFloat tSquared = t * t;
  CGFloat tCubed = tSquared * t;
  return CGPointMake(_coefficientsX[0] * tCubed + _coefficientsX[1] * tSquared + _coefficientsX[2] * t + _p0.x,
                     _coefficientsY[0] * tCubed + _coefficientsY[1] * tSquared + _coefficientsY[2] * t + _p0.y);
}

@end

@implementation HLTrajectoryBezier
{
  HLCubicBezier *_bezier;
}

- (instancetype)initWithStart:(CGPoint)startLocation
                       finish:(CGPoint)finishLocation
                      shapeP1:(CGPoint)shapeP1
                      shapeP2:(CGPoint)shapeP2
                       height:(CGFloat)height
{
  self = [super init];
  if (self) {

    // note: Translate and scale and skew the Bezier into the right shape.  For control
    // points P1 and P2, the X dimension is pretty easy: translate from unit coordinates
    // into the startLocation/finishLocation range.  The Y dimension is a little trickier:
    // Draw a straight line between startLocation and finishLocation, and find our Y
    // starting point along that line (using the control point X coordinate).  Then go up
    // from there, scaling our control point Y by the owner-provided height.
    CGFloat deltaX = finishLocation.x - startLocation.x;
    CGFloat deltaY = finishLocation.y - startLocation.y;
    _bezier = [[HLCubicBezier alloc] initWithP0:startLocation
                                             p1:CGPointMake(startLocation.x + shapeP1.x * deltaX,
                                                            startLocation.y + shapeP1.x * deltaY + shapeP1.y * height)
                                             p2:CGPointMake(startLocation.x + shapeP2.x * deltaX,
                                                            startLocation.y + shapeP2.x * deltaY + shapeP2.y * height)
                                             p3:finishLocation];
  }
  return self;
}

- (CGPoint)pointForT:(CGFloat)t
{
  return [_bezier pointForT:t];
}

@end

@implementation HLPiecewiseLinearFunction
{
  CGFloat *_knotXValues;
  CGFloat *_knotYValues;
  NSUInteger _knotCount;
}

- (instancetype)initWithKnotXValues:(NSArray *)knotXValues
                        knotYValues:(NSArray *)knotYValues
{
  self = [super init];
  if (self) {
    _knotCount = [knotXValues count];
    if (_knotCount < 1) {
      [NSException raise:@"HLFunctionInvalid"
                  format:@"HLPiecewiseLinearFunction must have at least one knot."];
    }
    if ([knotYValues count] != _knotCount) {
      [NSException raise:@"HLFunctionInvalid"
                  format:@"HLPiecewiseLinearFunction must be given the same number of knot X and Y values."];
    }
    _knotXValues = (CGFloat *)malloc(sizeof(CGFloat) * _knotCount);
    _knotYValues = (CGFloat *)malloc(sizeof(CGFloat) * _knotCount);
    for (NSUInteger k = 0; k < _knotCount; ++k) {
      _knotXValues[k] = (CGFloat)[knotXValues[k] doubleValue];
      _knotYValues[k] = (CGFloat)[knotYValues[k] doubleValue];
      if (k > 0 && _knotXValues[k] <= _knotXValues[k - 1]) {
        [NSException raise:@"HLFunctionInvalid"
                    format:@"HLPiecewiseLinearFunction must have monotonically-increasing knot X values."];
      }
    }
  }
  return self;
}

- (void)dealloc
{
  free(_knotXValues);
  free(_knotYValues);
}

- (CGFloat)yForX:(CGFloat)x
{
  if (x <= _knotXValues[0]) {
    return _knotYValues[0];
  } else if (x >= _knotXValues[_knotCount - 1]) {
    return _knotYValues[_knotCount - 1];
  } else {
    NSUInteger k = 0;
    while (x > _knotXValues[k + 1]) {
      ++k;
    }
    return (x - _knotXValues[k]) / (_knotXValues[k + 1] - _knotXValues[k]) * (_knotYValues[k + 1] - _knotYValues[k]) + _knotYValues[k];
  }
}

@end
