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

#if TARGET_OS_IPHONE
  if ([node respondsToSelector:@selector(size)]) {
    return [node size];
  }
#else
  // note: Careful handling of size selector is required when building for macOS,
  // for which the compiler sees multiple definitions with different return types.
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
#endif
  
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

#if TARGET_OS_IPHONE
  if ([node respondsToSelector:@selector(size)]) {
    return [node size].width;
  }
#else
  // note: Careful handling of size selector is required when building for macOS,
  // for which the compiler sees multiple definitions with different return types.
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
#endif
  
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

#if TARGET_OS_IPHONE
  if ([node respondsToSelector:@selector(size)]) {
    return [node size].height;
  }
#else
  // note: Careful handling of size selector is required when building for macOS,
  // for which the compiler sees multiple definitions with different return types.
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
#endif

  return 0.0f;
}
