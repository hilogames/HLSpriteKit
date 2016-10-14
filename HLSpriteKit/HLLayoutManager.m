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
  // note: As of iOS 10, SKNode exposes an undocumented `size` selector.  For SKLabelNode
  // it returns zero.
  if ([node isKindOfClass:[SKLabelNode class]]) {
    return [(SKLabelNode *)node frame].size;
  }
  if ([node respondsToSelector:@selector(size)]) {
    return [node size];
  }
  return CGSizeZero;
}

CGFloat
HLLayoutManagerGetNodeWidth(id node)
{
  // note: As of iOS 10, SKNode exposes an undocumented `size` selector.  For SKLabelNode
  // it returns zero.
  if ([node isKindOfClass:[SKLabelNode class]]) {
    return [(SKLabelNode *)node frame].size.width;
  }
  if ([node respondsToSelector:@selector(size)]) {
    return [node size].width;
  }
  return 0.0f;
}

CGFloat
HLLayoutManagerGetNodeHeight(id node)
{
  // note: As of iOS 10, SKNode exposes an undocumented `size` selector.  For SKLabelNode
  // it returns zero.
  if ([node isKindOfClass:[SKLabelNode class]]) {
    return [(SKLabelNode *)node frame].size.height;
  }
  if ([node respondsToSelector:@selector(size)]) {
    return [node size].height;
  }
  return 0.0f;
}
