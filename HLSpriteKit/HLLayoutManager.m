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

  SEL selector = @selector(size);
  NSMethodSignature *sizeMethodSignature = [node methodSignatureForSelector:selector];
  if (sizeMethodSignature
      && strcmp(sizeMethodSignature.methodReturnType, @encode(CGSize)) == 0) {
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sizeMethodSignature];
    invocation.selector = selector;
    [invocation invokeWithTarget:node];
    CGSize nodeSize;
    [invocation getReturnValue:&nodeSize];
    return nodeSize;
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

  SEL selector = @selector(size);
  NSMethodSignature *sizeMethodSignature = [node methodSignatureForSelector:selector];
  if (sizeMethodSignature
      && strcmp(sizeMethodSignature.methodReturnType, @encode(CGSize)) == 0) {
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sizeMethodSignature];
    invocation.selector = selector;
    [invocation invokeWithTarget:node];
    CGSize nodeSize;
    [invocation getReturnValue:&nodeSize];
    return nodeSize.width;
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

  SEL selector = @selector(size);
  NSMethodSignature *sizeMethodSignature = [node methodSignatureForSelector:selector];
  if (sizeMethodSignature
      && strcmp(sizeMethodSignature.methodReturnType, @encode(CGSize)) == 0) {
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sizeMethodSignature];
    invocation.selector = selector;
    [invocation invokeWithTarget:node];
    CGSize nodeSize;
    [invocation getReturnValue:&nodeSize];
    return nodeSize.height;
  }

  return 0.0f;
}
