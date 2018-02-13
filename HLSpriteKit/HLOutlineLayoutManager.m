//
//  HLOutlineLayoutManager.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 7/9/15.
//  Copyright (c) 2015 Hilo Games. All rights reserved.
//

#import "HLOutlineLayoutManager.h"

#import <TargetConditionals.h>

const CGFloat HLOutlineLayoutManagerEpsilon = 0.001f;

@implementation HLOutlineLayoutManager

- (instancetype)init
{
  self = [super init];
  if (self) {
    _anchorPointY = 0.5f;
    _outlinePosition = CGPointZero;
  }
  return self;
}

- (instancetype)initWithNodeLevels:(NSArray *)nodeLevels
                      levelIndents:(NSArray *)levelIndents
                  levelNodeHeights:(NSArray *)levelNodeHeights
                levelAnchorPointYs:(NSArray *)levelAnchorPointYs
{
  self = [super init];
  if (self) {
    _anchorPointY = 0.5f;
    _outlinePosition = CGPointZero;
    _nodeLevels = nodeLevels;
    _levelIndents = levelIndents;
    _levelNodeHeights = levelNodeHeights;
    _levelAnchorPointYs = levelAnchorPointYs;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super init];
  if (self) {
    _anchorPointY = (CGFloat)[aDecoder decodeDoubleForKey:@"anchorPointY"];
#if TARGET_OS_IPHONE
    _outlinePosition = [aDecoder decodeCGPointForKey:@"outlinePosition"];
#else
    _outlinePosition = [aDecoder decodePointForKey:@"outlinePosition"];
#endif
    _height = (CGFloat)[aDecoder decodeDoubleForKey:@"height"];
    _nodeLevels = [aDecoder decodeObjectForKey:@"nodeLevels"];
    _levelIndents = [aDecoder decodeObjectForKey:@"levelIndents"];
    _levelNodeHeights = [aDecoder decodeObjectForKey:@"levelNodeHeights"];
    _levelAnchorPointYs = [aDecoder decodeObjectForKey:@"levelAnchorPointYs"];
    _levelSeparatorBeforeHeights = [aDecoder decodeObjectForKey:@"levelSeparatorBeforeHeights"];
    _levelSeparatorAfterHeights = [aDecoder decodeObjectForKey:@"levelSeparatorAfterHeights"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [aCoder encodeDouble:_anchorPointY forKey:@"anchorPointY"];
#if TARGET_OS_IPHONE
  [aCoder encodeCGPoint:_outlinePosition forKey:@"outlinePosition"];
#else
  [aCoder encodePoint:_outlinePosition forKey:@"outlinePosition"];
#endif
  [aCoder encodeDouble:_height forKey:@"height"];
  [aCoder encodeObject:_nodeLevels forKey:@"nodeLevels"];
  [aCoder encodeObject:_levelIndents forKey:@"levelIndents"];
  [aCoder encodeObject:_levelNodeHeights forKey:@"levelNodeHeights"];
  [aCoder encodeObject:_levelAnchorPointYs forKey:@"levelAnchorPointYs"];
  [aCoder encodeObject:_levelSeparatorBeforeHeights forKey:@"levelSeparatorBeforeHeights"];
  [aCoder encodeObject:_levelSeparatorAfterHeights forKey:@"levelSeparatorAfterHeights"];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  HLOutlineLayoutManager *copy = [[[self class] allocWithZone:zone] init];
  if (copy) {
    copy->_anchorPointY = _anchorPointY;
    copy->_outlinePosition = _outlinePosition;
    copy->_height = _height;
    copy->_nodeLevels = [_nodeLevels copyWithZone:zone];
    copy->_levelIndents = [_levelIndents copyWithZone:zone];
    copy->_levelNodeHeights = [_levelNodeHeights copyWithZone:zone];
    copy->_levelAnchorPointYs = [_levelAnchorPointYs copyWithZone:zone];
    copy->_levelSeparatorBeforeHeights = [_levelSeparatorBeforeHeights copyWithZone:zone];
    copy->_levelSeparatorAfterHeights = [_levelSeparatorAfterHeights copyWithZone:zone];
  }
  return copy;
}

- (void)layout:(NSArray *)nodes
{
  [self GL_layout:nodes animated:NO duration:0.0 delay:0.0];
}

- (void)layout:(NSArray *)nodes animatedDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay
{
  [self GL_layout:nodes animated:YES duration:duration delay:delay];
}

- (void)GL_layout:(NSArray *)nodes animated:(BOOL)animated duration:(NSTimeInterval)duration delay:(NSTimeInterval)delay
{
  NSUInteger nodeLevelsCount = [_nodeLevels count];
  if (nodeLevelsCount == 0) {
    return;
  }
  NSUInteger nodesCount = [nodes count];
  if (nodesCount == 0) {
    return;
  }
  NSUInteger layoutCount = MIN(nodeLevelsCount, nodesCount);
  NSUInteger levelIndentsCount = [_levelIndents count];
  NSUInteger levelNodeHeightsCount = [_levelNodeHeights count];
  NSUInteger levelAnchorPointYsCount = [_levelAnchorPointYs count];
  if (levelIndentsCount == 0 || levelNodeHeightsCount == 0 || levelAnchorPointYsCount == 0) {
    return;
  }

  CGFloat *levelIndentsAccumulated = (CGFloat *)malloc(levelIndentsCount * sizeof(CGFloat));
  CGFloat levelIndentAccumulated = 0.0f;
  for (NSUInteger levelIndex = 0; levelIndex < levelIndentsCount; ++levelIndex) {
    levelIndentAccumulated += (CGFloat)[_levelIndents[levelIndex] doubleValue];
    levelIndentsAccumulated[levelIndex] = levelIndentAccumulated;
  }

  // note: Assume it's faster to copy and interpret NSValues out of their NSArrays into local
  // C variables, rather than do multiple NSArray accesses for each node.  Untested,
  // though; maybe premature optimization.  And if we're really all that concerned, shouldn't
  // we be putting the NSArray values into C arrays when they are set, at the object level,
  // rather than at each layout?
  CGFloat lastLevelIndent = (CGFloat)[_levelIndents[levelIndentsCount - 1] doubleValue];
  CGFloat *levelNodeHeights = (CGFloat *)malloc(levelNodeHeightsCount * sizeof(CGFloat));
  for (NSUInteger levelIndex = 0; levelIndex < levelNodeHeightsCount; ++levelIndex) {
    levelNodeHeights[levelIndex] = (CGFloat)[_levelNodeHeights[levelIndex] doubleValue];
  }
  CGFloat *levelAnchorPointYs = (CGFloat *)malloc(levelAnchorPointYsCount * sizeof(CGFloat));
  for (NSUInteger levelIndex = 0; levelIndex < levelAnchorPointYsCount; ++levelIndex) {
    levelAnchorPointYs[levelIndex] = (CGFloat)[_levelAnchorPointYs[levelIndex] doubleValue];
  }
  NSUInteger levelSeparatorBeforeHeightsCount = [_levelSeparatorBeforeHeights count];
  CGFloat *levelSeparatorBeforeHeights = (CGFloat *)malloc(levelSeparatorBeforeHeightsCount * sizeof(CGFloat));
  for (NSUInteger levelIndex = 0; levelIndex < levelSeparatorBeforeHeightsCount; ++levelIndex) {
    levelSeparatorBeforeHeights[levelIndex] = (CGFloat)[_levelSeparatorBeforeHeights[levelIndex] doubleValue];
  }
  NSUInteger levelSeparatorAfterHeightsCount = [_levelSeparatorAfterHeights count];
  CGFloat *levelSeparatorAfterHeights = (CGFloat *)malloc(levelSeparatorAfterHeightsCount * sizeof(CGFloat));
  for (NSUInteger levelIndex = 0; levelIndex < levelSeparatorAfterHeightsCount; ++levelIndex) {
    levelSeparatorAfterHeights[levelIndex] = (CGFloat)[_levelSeparatorAfterHeights[levelIndex] doubleValue];
  }

  // note: Is anchorPointY used enough with a value other than 1.0 to make this second
  // loop worthwhile?  Leave it for now; optimize later.
  CGFloat outlineHeight = 0.0f;
  for (NSUInteger nodeIndex = 0; nodeIndex < layoutCount; ++nodeIndex) {

    NSUInteger nodeLevel = [_nodeLevels[nodeIndex] unsignedIntegerValue];

    CGFloat nodeHeight = 0.0f;
    if (nodeLevel < levelNodeHeightsCount) {
      nodeHeight = levelNodeHeights[nodeLevel];
    } else {
      nodeHeight = levelNodeHeights[levelNodeHeightsCount - 1];
    }
    if (nodeHeight < HLOutlineLayoutManagerEpsilon) {
      SKNode *node = nodes[nodeIndex];
      nodeHeight = HLLayoutManagerGetNodeHeight(node);
    }
    outlineHeight += nodeHeight;
  
    if (nodeIndex > 0) {
      CGFloat nodeSeparatorBefore = 0.0f;
      if (nodeLevel < levelSeparatorBeforeHeightsCount) {
        nodeSeparatorBefore = levelSeparatorBeforeHeights[nodeLevel];
      } else if (levelSeparatorBeforeHeightsCount > 0) {
        nodeSeparatorBefore = levelSeparatorBeforeHeights[levelSeparatorBeforeHeightsCount - 1];
      }
      outlineHeight += nodeSeparatorBefore;
    }
  
    if (nodeIndex + 1 < layoutCount) {
      CGFloat nodeSeparatorAfter = 0.0f;
      if (nodeLevel < levelSeparatorAfterHeightsCount) {
        nodeSeparatorAfter = levelSeparatorAfterHeights[nodeLevel];
      } else if (levelSeparatorAfterHeightsCount > 0) {
        nodeSeparatorAfter = levelSeparatorAfterHeights[levelSeparatorAfterHeightsCount - 1];
      }
      outlineHeight += nodeSeparatorAfter;
    }
  }
  _height = outlineHeight;

  CGFloat y = outlineHeight * (1.0f - _anchorPointY);
  for (NSUInteger nodeIndex = 0; nodeIndex < layoutCount; ++nodeIndex) {

    NSUInteger nodeLevel = [_nodeLevels[nodeIndex] unsignedIntegerValue];
    SKNode *node = nodes[nodeIndex];

    CGFloat nodeIndent = 0.0f;
    if (nodeLevel < levelIndentsCount) {
      nodeIndent = levelIndentsAccumulated[nodeLevel];
    } else {
      nodeIndent = levelIndentsAccumulated[levelIndentsCount - 1] + lastLevelIndent * (nodeLevel - levelIndentsCount);
    }

    CGFloat nodeHeight = 0.0f;
    if (nodeLevel < levelNodeHeightsCount) {
      nodeHeight = levelNodeHeights[nodeLevel];
    } else {
      nodeHeight = levelNodeHeights[levelNodeHeightsCount - 1];
    }
    if (nodeHeight < HLOutlineLayoutManagerEpsilon) {
      nodeHeight = HLLayoutManagerGetNodeHeight(node);
    }

    CGFloat nodeAnchorPointY = 0.0f;
    if (nodeLevel < levelAnchorPointYsCount) {
      nodeAnchorPointY = levelAnchorPointYs[nodeLevel];
    } else {
      nodeAnchorPointY = levelAnchorPointYs[levelAnchorPointYsCount - 1];
    }

    if (nodeIndex > 0) {
      CGFloat nodeSeparatorBefore = 0.0f;
      if (nodeLevel < levelSeparatorBeforeHeightsCount) {
        nodeSeparatorBefore = levelSeparatorBeforeHeights[nodeLevel];
      } else if (levelSeparatorBeforeHeightsCount > 0) {
        nodeSeparatorBefore = levelSeparatorBeforeHeights[levelSeparatorBeforeHeightsCount - 1];
      }
      y -= nodeSeparatorBefore;
    }

    y -= nodeHeight;
    CGPoint position = CGPointMake(_outlinePosition.x + nodeIndent,
                                   _outlinePosition.y + y + nodeHeight * nodeAnchorPointY);
    if (!animated) {
      node.position = position;
    } else {
      SKAction *moveAction = [SKAction moveTo:position duration:duration];
      moveAction.timingMode = SKActionTimingEaseInEaseOut;
      if (delay > 0.0) {
        [node runAction:[SKAction sequence:@[ [SKAction waitForDuration:delay], moveAction ]]];
      } else {
        [node runAction:moveAction];
      }
    }

    if (nodeIndex + 1 < layoutCount) {
      CGFloat nodeSeparatorAfter = 0.0f;
      if (nodeLevel < levelSeparatorAfterHeightsCount) {
        nodeSeparatorAfter = levelSeparatorAfterHeights[nodeLevel];
      } else if (levelSeparatorAfterHeightsCount > 0) {
        nodeSeparatorAfter = levelSeparatorAfterHeights[levelSeparatorAfterHeightsCount - 1];
      }
      y -= nodeSeparatorAfter;
    }
  }

  free(levelIndentsAccumulated);
  free(levelNodeHeights);
  free(levelAnchorPointYs);
  free(levelSeparatorBeforeHeights);
  free(levelSeparatorAfterHeights);
}

@end

NSUInteger
HLOutlineLayoutManagerNodeContainingPointY(NSArray *nodes, CGFloat pointY,
                                           NSArray *nodeLevels,
                                           NSArray *levelNodeHeights, NSArray *levelAnchorPointYs)
{
  NSUInteger layoutCount = MIN([nodes count], [nodeLevels count]);
  SKNode *pointYNode = [SKNode node];
  pointYNode.position = CGPointMake(0.0f, pointY);
  NSUInteger greaterNodeIndex = [nodes indexOfObject:pointYNode
                                       inSortedRange:NSMakeRange(0, layoutCount)
                                             options:NSBinarySearchingInsertionIndex
                                     usingComparator:^NSComparisonResult(SKNode *node1, SKNode *node2){
    // note: Array of nodes is sorted according to position.y, largest to smallest.  NSArray considers "ascending"
    // direction to be from the first element of the sorted array to the last element of the sorted array, so, though
    // it might seem strange, a descending position.y is considered to be "ascending".
    if (node1.position.y > node2.position.y) {
      return NSOrderedAscending;
    } else if (node1.position.y < node2.position.y) {
      return NSOrderedDescending;
    } else {
      return NSOrderedSame;
    }
  }];

  NSUInteger levelNodeHeightsCount = [levelNodeHeights count];
  NSUInteger levelAnchorPointYsCount = [levelAnchorPointYs count];

  // note: greaterNodeIndex is the node with array position greater than pointYNode, which means the node
  // with a y-position smaller than pointY.  The node that contains the pointY is either that node,
  // the one with next-larger y-position (that is, with the next-lower array index).  Here, the range to
  // check is [begin, end).
  NSUInteger checkNodeIndexBegin = (greaterNodeIndex > 0 ? greaterNodeIndex - 1 : greaterNodeIndex);
  NSUInteger checkNodeIndexEnd = (greaterNodeIndex < layoutCount ? greaterNodeIndex + 1 : greaterNodeIndex);
  for (NSUInteger nodeIndex = checkNodeIndexBegin; nodeIndex < checkNodeIndexEnd; ++nodeIndex) {

    SKNode *node = nodes[nodeIndex];
    CGFloat nodePositionY = node.position.y;

    NSUInteger nodeLevel = [nodeLevels[nodeIndex] unsignedIntegerValue];

    CGFloat nodeHeight = 0.0f;
    if (nodeLevel < levelNodeHeightsCount) {
      nodeHeight = [levelNodeHeights[nodeLevel] doubleValue];
    } else {
      nodeHeight = [levelNodeHeights[levelNodeHeightsCount - 1] doubleValue];
    }
    if (nodeHeight < HLOutlineLayoutManagerEpsilon) {
      nodeHeight = HLLayoutManagerGetNodeHeight(node);
    }

    CGFloat nodeAnchorPointY = 0.0f;
    if (nodeLevel < levelAnchorPointYsCount) {
      nodeAnchorPointY = [levelAnchorPointYs[nodeLevel] doubleValue];
    } else {
      nodeAnchorPointY = [levelAnchorPointYs[levelAnchorPointYsCount - 1] doubleValue];
    }

    if (pointY <= nodePositionY + nodeHeight * (1.0f - nodeAnchorPointY)
        && pointY >= nodePositionY - nodeHeight * nodeAnchorPointY) {
      return nodeIndex;
    }
  }

  return NSNotFound;
}
