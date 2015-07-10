//
//  HLLayoutManager.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 10/27/14.
//  Copyright (c) 2014 Hilo Games. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import "HLLayoutManager.h"

CGSize
HLLayoutManagerGetNodeSize(id node)
{
  if ([node respondsToSelector:@selector(size)]) {
    return [node size];
  }
  if ([node isKindOfClass:[SKLabelNode class]]) {
    return [(SKLabelNode *)node frame].size;
  }
  return CGSizeZero;
}

CGFloat
HLLayoutManagerGetNodeWidth(id node)
{
  if ([node respondsToSelector:@selector(size)]) {
    return [node size].width;
  }
  if ([node isKindOfClass:[SKLabelNode class]]) {
    return [(SKLabelNode *)node frame].size.width;
  }
  return 0.0f;
}

CGFloat
HLLayoutManagerGetNodeHeight(id node)
{
  if ([node respondsToSelector:@selector(size)]) {
    return [node size].height;
  }
  if ([node isKindOfClass:[SKLabelNode class]]) {
    return [(SKLabelNode *)node frame].size.height;
  }
  return 0.0f;
}
