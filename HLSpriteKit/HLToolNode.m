//
//  HLToolNode.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 4/13/15.
//  Copyright (c) 2015 Hilo Games. All rights reserved.
//

#import "HLToolNode.h"

enum {
  HLToolGlowNodeZPositionLayerBackHighlight = 0,
  HLToolGlowNodeZPositionLayerContent,
  HLToolGlowNodeZPositionLayerCount
};

@implementation HLToolBackHighlightNode
{
  SKNode *_contentNode;
  SKNode *_backHighlightNode;
}

- (instancetype)initWithContentNode:(SKNode *)contentNode backHighlightNode:(SKNode *)backHighlightNode
{
  self = [super init];
  if (self) {
    _contentNode = contentNode;
    _backHighlightNode = backHighlightNode;
    [self addChild:contentNode];
    [self HL_layoutZ];
  }
  return self;
}

- (CGSize)size
{
  return [(id)_contentNode size];
}

- (void)setZPositionScale:(CGFloat)zPositionScale
{
  [super setZPositionScale:zPositionScale];
  [self HL_layoutZ];
}

- (void)hlToolSetHighlight:(BOOL)highlight
{
  if (highlight) {
    if (!_backHighlightNode.parent) {
      [self addChild:_backHighlightNode];
    }
  } else {
    if (_backHighlightNode.parent) {
      [_backHighlightNode removeFromParent];
    }
  }
}

- (void)HL_layoutZ
{
  CGFloat zPositionLayerIncrement = self.zPositionScale / HLToolGlowNodeZPositionLayerCount;
  _contentNode.zPosition = HLToolGlowNodeZPositionLayerContent * zPositionLayerIncrement;
  _backHighlightNode.zPosition = HLToolGlowNodeZPositionLayerBackHighlight * zPositionLayerIncrement;
}

@end
