//
//  SKNode+HLNodeVisuals.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 4/3/15.
//  Copyright (c) 2015 Hilo Games. All rights reserved.
//

#import <CoreImage/CIFilter.h>

#import "SKNode+HLNodeVisuals.h"

static const CGFloat HLBlurEpsilon = 0.001f;

@implementation SKNode (HLNodeVisuals)

- (SKNode *)shadowWithColor:(SKColor *)color blur:(CGFloat)blur
{
  SKNode *shapeNode = [self copy];

  // commented out: This approach works well, but SKCropNode and SKEffectNode often cause
  // trouble for me in combination with each other (in various iOS version).  Two SKEffectNodes
  // seem safer.  Still, keep this version around in case someone ever feels like comparing
  // performance, or reverting to this technique.
  //
  //  CGSize selfSize = [self calculateAccumulatedFrame].size;
  //  CGSize shadowSize = CGSizeMake(selfSize.width + 2.0f * blur,
  //                                 selfSize.height + 2.0f * blur);
  //  SKSpriteNode *colorMatteNode = [SKSpriteNode spriteNodeWithColor:color size:shadowSize];
  //  SKCropNode *colorizedShapeNode = [SKCropNode node];
  //  [colorizedShapeNode addChild:colorMatteNode];
  //  colorizedShapeNode.maskNode = shapeNode;

  CGFloat colorRedComponent;
  CGFloat colorGreenComponent;
  CGFloat colorBlueComponent;
  CGFloat colorAlphaComponent;
  [color getRed:&colorRedComponent green:&colorGreenComponent blue:&colorBlueComponent alpha:&colorAlphaComponent];
  CIVector *inputMinComponents = [CIVector vectorWithX:colorRedComponent Y:colorGreenComponent Z:colorBlueComponent W:0.0f];
  CIVector *inputMaxComponents = [CIVector vectorWithX:colorRedComponent Y:colorGreenComponent Z:colorBlueComponent W:colorAlphaComponent];
  CIFilter *clampFilter = [CIFilter filterWithName:@"CIColorClamp"
                               withInputParameters:@{ @"inputMinComponents" : inputMinComponents,
                                                      @"inputMaxComponents" : inputMaxComponents }];

  SKEffectNode *clampEffectNode = [SKEffectNode node];
  [clampEffectNode addChild:shapeNode];
  clampEffectNode.shouldRasterize = YES;
  clampEffectNode.shouldEnableEffects = YES;
  clampEffectNode.filter = clampFilter;

  if (blur < HLBlurEpsilon) {
    return clampEffectNode;
  }

  CIFilter *blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
  [blurFilter setDefaults];
  [blurFilter setValue:[NSNumber numberWithFloat:blur] forKey:@"inputRadius"];

  SKEffectNode *blurNode = [SKEffectNode node];
  [blurNode addChild:clampEffectNode];
  blurNode.shouldRasterize = YES;
  blurNode.shouldEnableEffects = YES;
  blurNode.filter = blurFilter;

  return blurNode;
}

- (SKNode *)multiShadowWithOffset:(CGFloat)offset
                      shadowCount:(int)shadowCount
                     initialTheta:(CGFloat)initialTheta
                            color:(SKColor *)color
                             blur:(CGFloat)blur
{
  SKNode *shapeNode = [SKNode node];
  CGFloat theta = initialTheta;
  CGFloat thetaIncrement = 2.0f * (CGFloat)M_PI / shadowCount;
  for (int s = 0; s < shadowCount; ++s) {
    SKNode *shadowNode = [self copy];
    shadowNode.position = CGPointMake(self.position.x + offset * (CGFloat)cos(theta),
                                      self.position.y + offset * (CGFloat)sin(theta));
    [shapeNode addChild:shadowNode];
    theta += thetaIncrement;
  }

  // commented out: This approach works well, but SKCropNode and SKEffectNode often cause
  // trouble for me in combination with each other (in various iOS version).  Two SKEffectNodes
  // seem safer.  Still, keep this version around in case someone ever feels like comparing
  // performance, or reverting to this technique.
  //
  //  CGSize selfSize = [self calculateAccumulatedFrame].size;
  //  CGSize multiShadowSize = CGSizeMake(selfSize.width + 2.0f * (offset + blur),
  //                                      selfSize.height + 2.0f * (offset + blur));
  //  SKSpriteNode *colorMatteNode = [SKSpriteNode spriteNodeWithColor:color size:multiShadowSize];
  //  // note: Position the color matte to cover the entire multi-shadow texture.  This
  //  // isn't bullet-proof, though: What if this node is a sprite node running an animate textures
  //  // SKAction with resize:YES and one of the textures is bigger than the current texture?
  //  colorMatteNode.position = self.position;
  //  if ([self isKindOfClass:[SKSpriteNode class]]) {
  //    colorMatteNode.anchorPoint = ((SKSpriteNode *)self).anchorPoint;
  //  }
  //  colorMatteNode.zRotation = self.zRotation;
  //  SKCropNode *colorizedOutlineNode = [SKCropNode node];
  //  [colorizedOutlineNode addChild:colorMatteNode];
  //  colorizedOutlineNode.maskNode = shapeNode;

  CGFloat colorRedComponent;
  CGFloat colorGreenComponent;
  CGFloat colorBlueComponent;
  CGFloat colorAlphaComponent;
  [color getRed:&colorRedComponent green:&colorGreenComponent blue:&colorBlueComponent alpha:&colorAlphaComponent];
  CIVector *inputMinComponents = [CIVector vectorWithX:colorRedComponent Y:colorGreenComponent Z:colorBlueComponent W:0.0f];
  CIVector *inputMaxComponents = [CIVector vectorWithX:colorRedComponent Y:colorGreenComponent Z:colorBlueComponent W:colorAlphaComponent];
  CIFilter *clampFilter = [CIFilter filterWithName:@"CIColorClamp"
                               withInputParameters:@{ @"inputMinComponents" : inputMinComponents,
                                                      @"inputMaxComponents" : inputMaxComponents }];

  SKEffectNode *clampEffectNode = [SKEffectNode node];
  [clampEffectNode addChild:shapeNode];
  clampEffectNode.shouldRasterize = YES;
  clampEffectNode.shouldEnableEffects = YES;
  clampEffectNode.filter = clampFilter;

  if (blur < HLBlurEpsilon) {
    return clampEffectNode;
  }

  CIFilter *blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
  [blurFilter setDefaults];
  [blurFilter setValue:[NSNumber numberWithFloat:blur] forKey:@"inputRadius"];

  SKEffectNode *blurNode = [SKEffectNode node];
  [blurNode addChild:clampEffectNode];
  blurNode.shouldRasterize = YES;
  blurNode.shouldEnableEffects = YES;
  blurNode.filter = blurFilter;

  return blurNode;
}

@end
