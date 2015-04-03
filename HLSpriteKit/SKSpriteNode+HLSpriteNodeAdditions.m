//
//  SKSpriteNode+HLSpriteNodeAdditions.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 4/3/15.
//
//

#import "SKSpriteNode+HLSpriteNodeAdditions.h"

static const CGFloat HLBlurEpsilon = 0.001f;

@implementation SKSpriteNode (HLSpriteNodeAdditions)

- (SKNode *)shadowWithColor:(UIColor *)color blur:(CGFloat)blur
{
  SKSpriteNode *shapeNode = [SKSpriteNode spriteNodeWithTexture:self.texture];

  CGSize shadowSize = CGSizeMake(self.texture.size.width + 2.0f * blur,
                                 self.texture.size.height + 2.0f * blur);
  SKSpriteNode *colorMatteNode = [SKSpriteNode spriteNodeWithColor:color size:shadowSize];
  SKCropNode *colorizedShapeNode = [SKCropNode node];
  [colorizedShapeNode addChild:colorMatteNode];
  colorizedShapeNode.maskNode = shapeNode;

  if (blur < HLBlurEpsilon) {
    return colorizedShapeNode;
  }
  
  // note: Since we're using CIFilter for the blur, could/should we use it to create the
  // colorized outline, too?
  CIFilter *blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
  [blurFilter setDefaults];
  [blurFilter setValue:[NSNumber numberWithFloat:blur] forKey:@"inputRadius"];
  
  SKEffectNode *blurNode = [SKEffectNode node];
  blurNode.shouldRasterize = YES;
  blurNode.shouldEnableEffects = YES;
  blurNode.filter = blurFilter;
  [blurNode addChild:colorizedShapeNode];
  
  return blurNode;
}

- (SKNode *)multiShadowWithOffset:(CGFloat)offset
                      shadowCount:(int)shadowCount
                     initialTheta:(CGFloat)initialTheta
                            color:(UIColor *)color
                             blur:(CGFloat)blur
{
  SKNode *shapeNode = [SKNode node];
  CGFloat theta = initialTheta;
  CGFloat thetaIncrement = 2.0f * (CGFloat)M_PI / shadowCount;
  for (int s = 0; s < shadowCount; ++s) {
    SKSpriteNode *shadowNode = [SKSpriteNode spriteNodeWithTexture:self.texture];
    shadowNode.position = CGPointMake(offset * (CGFloat)cos(theta),
                                      offset * (CGFloat)sin(theta));
    [shapeNode addChild:shadowNode];
    theta += thetaIncrement;
  }

  CGSize multiShadowSize = CGSizeMake(self.texture.size.width + 2.0f * (offset + blur),
                                      self.texture.size.height + 2.0f * (offset + blur));
  SKSpriteNode *colorMatteNode = [SKSpriteNode spriteNodeWithColor:color size:multiShadowSize];
  SKCropNode *colorizedOutlineNode = [SKCropNode node];
  [colorizedOutlineNode addChild:colorMatteNode];
  colorizedOutlineNode.maskNode = shapeNode;
  
  if (blur < HLBlurEpsilon) {
    return colorizedOutlineNode;
  }
  
  // note: Since we're using CIFilter for the blur, could/should we use it to create the
  // colorized outline, too?
  CIFilter *blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
  [blurFilter setDefaults];
  [blurFilter setValue:[NSNumber numberWithFloat:blur] forKey:@"inputRadius"];
  
  SKEffectNode *blurNode = [SKEffectNode node];
  blurNode.shouldRasterize = YES;
  blurNode.shouldEnableEffects = YES;
  blurNode.filter = blurFilter;
  [blurNode addChild:colorizedOutlineNode];
    
  return blurNode;
}

@end
