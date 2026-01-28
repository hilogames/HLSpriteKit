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
{
  self = [super init];
  if (self) {
    _anchorPointY = 0.5f;
    _outlinePosition = CGPointZero;
    _nodeLevels = nodeLevels;
    _levelIndents = levelIndents;
  }
  return self;
}

- (instancetype)initWithNodeLevels:(NSArray *)nodeLevels
                      levelIndents:(NSArray *)levelIndents
                  levelLineHeights:(NSArray *)levelLineHeights
                levelLabelOffsetYs:(NSArray *)levelLabelOffsetYs
{
  self = [super init];
  if (self) {
    _anchorPointY = 0.5f;
    _outlinePosition = CGPointZero;
    _nodeLevels = nodeLevels;
    _levelIndents = levelIndents;
    _levelLineHeights = levelLineHeights;
    _levelLabelOffsetYs = levelLabelOffsetYs;
  }
  return self;
}

- (instancetype)initWithNodeLevels:(NSArray *)nodeLevels
                      levelIndents:(NSArray *)levelIndents
                  levelLineHeights:(NSArray *)levelLineHeights
                levelAnchorPointYs:(NSArray *)levelAnchorPointYs
{
  self = [super init];
  if (self) {
    _anchorPointY = 0.5f;
    _outlinePosition = CGPointZero;
    _nodeLevels = nodeLevels;
    _levelIndents = levelIndents;
    _levelLineHeights = levelLineHeights;
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
    _levelLineHeights = [aDecoder decodeObjectForKey:@"levelLineHeights"];
    _levelAnchorPointYs = [aDecoder decodeObjectForKey:@"levelAnchorPointYs"];
    _levelLabelOffsetYs = [aDecoder decodeObjectForKey:@"levelLabelOffsetYs"];
    _levelLineBeforeSeparators = [aDecoder decodeObjectForKey:@"levelLineBeforeSeparators"];
    _levelLineAfterSeparators = [aDecoder decodeObjectForKey:@"levelLineAfterSeparators"];
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
  [aCoder encodeObject:_levelLineHeights forKey:@"levelLineHeights"];
  [aCoder encodeObject:_levelAnchorPointYs forKey:@"levelAnchorPointYs"];
  [aCoder encodeObject:_levelLabelOffsetYs forKey:@"levelLabelOffsetYs"];
  [aCoder encodeObject:_levelLineBeforeSeparators forKey:@"levelLineBeforeSeparators"];
  [aCoder encodeObject:_levelLineAfterSeparators forKey:@"levelLineAfterSeparators"];
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
    copy->_levelLineHeights = [_levelLineHeights copyWithZone:zone];
    copy->_levelAnchorPointYs = [_levelAnchorPointYs copyWithZone:zone];
    copy->_levelLabelOffsetYs = [_levelLabelOffsetYs copyWithZone:zone];
    copy->_levelLineBeforeSeparators = [_levelLineBeforeSeparators copyWithZone:zone];
    copy->_levelLineAfterSeparators = [_levelLineAfterSeparators copyWithZone:zone];
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
  if (levelIndentsCount == 0) {
    return;
  }
  NSUInteger levelLineHeightsCount = (_levelLineHeights ? [_levelLineHeights count] : 0);
  NSUInteger levelAnchorPointYsCount = (_levelAnchorPointYs ? [_levelAnchorPointYs count] : 0);
  NSUInteger levelLabelOffsetYsCount = (_levelLabelOffsetYs ? [_levelLabelOffsetYs count] : 0);
  NSUInteger levelLineBeforeSeparatorsCount = (_levelLineBeforeSeparators ? [_levelLineBeforeSeparators count] : 0);
  NSUInteger levelLineAfterSeparatorsCount = (_levelLineAfterSeparators ? [_levelLineAfterSeparators count] : 0);

  // note: Assume it's faster to copy and interpret NSValues out of their NSArrays into
  // stack C arrays, rather than do multiple NSArray accesses for each node.  Untested,
  // though; maybe premature optimization.  And if we're really all that concerned,
  // shouldn't we be putting the NSArray values into C arrays when they are set, at the
  // object level, rather than at each layout?
  CGFloat *levelIndentsAccumulated = (CGFloat *)malloc(levelIndentsCount * sizeof(CGFloat));
  CGFloat levelIndentAccumulated = 0.0f;
  for (NSUInteger levelIndex = 0; levelIndex < levelIndentsCount; ++levelIndex) {
    levelIndentAccumulated += (CGFloat)[_levelIndents[levelIndex] doubleValue];
    levelIndentsAccumulated[levelIndex] = levelIndentAccumulated;
  }
  CGFloat lastLevelIndent = (CGFloat)[_levelIndents[levelIndentsCount - 1] doubleValue];
  CGFloat *levelLineHeights = NULL;
  if (levelLineHeightsCount > 0) {
    levelLineHeights = (CGFloat *)malloc(levelLineHeightsCount * sizeof(CGFloat));
    for (NSUInteger levelIndex = 0; levelIndex < levelLineHeightsCount; ++levelIndex) {
      levelLineHeights[levelIndex] = (CGFloat)[_levelLineHeights[levelIndex] doubleValue];
    }
  }
  CGFloat *levelAnchorPointYs = NULL;
  if (levelAnchorPointYsCount > 0) {
    levelAnchorPointYs = (CGFloat *)malloc(levelAnchorPointYsCount * sizeof(CGFloat));
    for (NSUInteger levelIndex = 0; levelIndex < levelAnchorPointYsCount; ++levelIndex) {
      levelAnchorPointYs[levelIndex] = (CGFloat)[_levelAnchorPointYs[levelIndex] doubleValue];
    }
  }
  CGFloat *levelLabelOffsetYs = NULL;
  if (levelLabelOffsetYsCount > 0) {
    levelLabelOffsetYs = (CGFloat *)malloc(levelLabelOffsetYsCount * sizeof(CGFloat));
    for (NSUInteger levelIndex = 0; levelIndex < levelLabelOffsetYsCount; ++levelIndex) {
      levelLabelOffsetYs[levelIndex] = (CGFloat)[_levelLabelOffsetYs[levelIndex] doubleValue];
    }
  }
  CGFloat *levelLineBeforeSeparators = NULL;
  if (levelLineBeforeSeparatorsCount > 0) {
    levelLineBeforeSeparators = (CGFloat *)malloc(levelLineBeforeSeparatorsCount * sizeof(CGFloat));
    for (NSUInteger levelIndex = 0; levelIndex < levelLineBeforeSeparatorsCount; ++levelIndex) {
      levelLineBeforeSeparators[levelIndex] = (CGFloat)[_levelLineBeforeSeparators[levelIndex] doubleValue];
    }
  }
  CGFloat *levelLineAfterSeparators = NULL;
  if (levelLineAfterSeparatorsCount > 0) {
    levelLineAfterSeparators = (CGFloat *)malloc(levelLineAfterSeparatorsCount * sizeof(CGFloat));
    for (NSUInteger levelIndex = 0; levelIndex < levelLineAfterSeparatorsCount; ++levelIndex) {
      levelLineAfterSeparators[levelIndex] = (CGFloat)[_levelLineAfterSeparators[levelIndex] doubleValue];
    }
  }

  // note: If the overall outline anchor point Y is not 1.0, then we need to know the
  // total outline height before we can finalize node Y positions.  That probably means
  // two passes: Even if all line heights are fixed, we still need to know how many nodes
  // are assigned to each outline level.  This is one way to do the two passes, but there
  // might be better ways.

  // First pass: Calculate the relative Y-position of each node in the outline, and sum
  // total outline height.
  CGFloat *nodeOffsetYs = (CGFloat *)malloc(layoutCount * sizeof(CGFloat));
  CGFloat offsetY = 0.0f;
  for (NSUInteger nodeIndex = 0; nodeIndex < layoutCount; ++nodeIndex) {

    NSUInteger nodeLevel = [_nodeLevels[nodeIndex] unsignedIntegerValue];
    SKNode *node = nodes[nodeIndex];

    if (nodeIndex > 0) {
      CGFloat lineBeforeSeparator = 0.0f;
      if (nodeLevel < levelLineBeforeSeparatorsCount) {
        lineBeforeSeparator = levelLineBeforeSeparators[nodeLevel];
      } else if (levelLineBeforeSeparatorsCount > 0) {
        lineBeforeSeparator = levelLineBeforeSeparators[levelLineBeforeSeparatorsCount - 1];
      }
      offsetY -= lineBeforeSeparator;
    }

    CGFloat lineHeight = 0.0f;
    if (nodeLevel < levelLineHeightsCount) {
      lineHeight = levelLineHeights[nodeLevel];
    } else if (levelLineHeightsCount > 0) {
      lineHeight = levelLineHeights[levelLineHeightsCount - 1];
    }
    if (lineHeight < HLOutlineLayoutManagerEpsilon) {
      lineHeight = HLLayoutManagerGetNodeHeight(node);
    }

    CGFloat anchorPointY = 0.5f;
    if (nodeLevel < levelAnchorPointYsCount) {
      anchorPointY = levelAnchorPointYs[nodeLevel];
    } else if (levelAnchorPointYsCount > 0) {
      anchorPointY = levelAnchorPointYs[levelAnchorPointYsCount - 1];
    }

    CGFloat nodeOffsetY = 0.0f;
    if ([node isKindOfClass:[SKLabelNode class]]) {
      if (nodeLevel < levelLabelOffsetYsCount) {
        nodeOffsetY = levelLabelOffsetYs[nodeLevel];
      } else if (levelLabelOffsetYsCount > 0) {
        nodeOffsetY = levelLabelOffsetYs[levelLabelOffsetYsCount - 1];
      }
    }

    offsetY -= lineHeight;
    nodeOffsetYs[nodeIndex] = offsetY + nodeOffsetY + lineHeight * anchorPointY;

    if (nodeIndex + 1 < layoutCount) {
      CGFloat lineAfterSeparator = 0.0f;
      if (nodeLevel < levelLineAfterSeparatorsCount) {
        lineAfterSeparator = levelLineAfterSeparators[nodeLevel];
      } else if (levelLineAfterSeparatorsCount > 0) {
        lineAfterSeparator = levelLineAfterSeparators[levelLineAfterSeparatorsCount - 1];
      }
      offsetY -= lineAfterSeparator;
    }
  }
  CGFloat outlineHeight = -offsetY;

  _height = outlineHeight;

  // Second pass: Calculate starting Y and each node indent X, and position nodes.
  CGFloat outlineYTop = _outlinePosition.y + outlineHeight * (1.0f - _anchorPointY);
  for (NSUInteger nodeIndex = 0; nodeIndex < layoutCount; ++nodeIndex) {

    NSUInteger nodeLevel = [_nodeLevels[nodeIndex] unsignedIntegerValue];
    SKNode *node = nodes[nodeIndex];

    CGFloat nodeIndent = 0.0f;
    if (nodeLevel < levelIndentsCount) {
      nodeIndent = levelIndentsAccumulated[nodeLevel];
    } else {
      nodeIndent = levelIndentsAccumulated[levelIndentsCount - 1] + lastLevelIndent * (nodeLevel - levelIndentsCount + 1);
    }

    CGPoint position = CGPointMake(_outlinePosition.x + nodeIndent,
                                   outlineYTop + nodeOffsetYs[nodeIndex]);
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
  }

  free(levelIndentsAccumulated);
  free(levelLineHeights);
  free(levelAnchorPointYs);
  free(levelLabelOffsetYs);
  free(levelLineBeforeSeparators);
  free(levelLineAfterSeparators);
  free(nodeOffsetYs);
}

@end

NSUInteger
HLOutlineLayoutManagerLineContainingPointY(NSArray *nodes,
                                           CGFloat pointY,
                                           NSArray *nodeLevels,
                                           NSArray *levelLineHeights,
                                           NSArray *levelAnchorPointYs,
                                           NSArray *levelLabelOffsetYs)
{
  NSUInteger layoutCount = MIN([nodes count], [nodeLevels count]);
  SKNode *pointYNode = [SKNode node];
  pointYNode.position = CGPointMake(0.0f, pointY);
  NSUInteger nextNodeIndex = [nodes indexOfObject:pointYNode
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

  NSUInteger levelLineHeightsCount = (levelLineHeights ? [levelLineHeights count] : 0);
  NSUInteger levelAnchorPointYsCount = (levelAnchorPointYs ? [levelAnchorPointYs count] : 0);
  NSUInteger levelLabelOffsetYsCount = (levelLabelOffsetYs ? [levelLabelOffsetYs count] : 0);

  // note: nextNodeIndex is the node with array position greater than pointYNode, which means the node
  // with a y-position smaller than pointY.  The node that contains the pointY is either that node,
  // or the one with next-larger y-position (that is, with the next-lower array index).  Using [begin, end)
  // range terminology.
  NSUInteger checkNodeIndexBegin = (nextNodeIndex > 0 ? nextNodeIndex - 1 : nextNodeIndex);
  NSUInteger checkNodeIndexEnd = (nextNodeIndex < layoutCount ? nextNodeIndex + 1 : nextNodeIndex);
  for (NSUInteger nodeIndex = checkNodeIndexBegin; nodeIndex < checkNodeIndexEnd; ++nodeIndex) {

    SKNode *node = nodes[nodeIndex];
    CGFloat nodePositionY = node.position.y;

    NSUInteger nodeLevel = [nodeLevels[nodeIndex] unsignedIntegerValue];

    CGFloat lineHeight = 0.0f;
    if (nodeLevel < levelLineHeightsCount) {
      lineHeight = [levelLineHeights[nodeLevel] doubleValue];
    } else if (levelLineHeightsCount > 0) {
      lineHeight = [levelLineHeights[levelLineHeightsCount - 1] doubleValue];
    }
    if (lineHeight < HLOutlineLayoutManagerEpsilon) {
      lineHeight = HLLayoutManagerGetNodeHeight(node);
    }

    CGFloat anchorPointY = 0.5f;
    if (nodeLevel < levelAnchorPointYsCount) {
      anchorPointY = [levelAnchorPointYs[nodeLevel] doubleValue];
    } else if (levelAnchorPointYsCount > 0) {
      anchorPointY = [levelAnchorPointYs[levelAnchorPointYsCount - 1] doubleValue];
    }

    CGFloat nodeOffsetY = 0.0f;
    if ([node isKindOfClass:[SKLabelNode class]]) {
      if (nodeLevel < levelLabelOffsetYsCount) {
        nodeOffsetY = [levelLabelOffsetYs[nodeLevel] doubleValue];
      } else if (levelLabelOffsetYsCount > 0) {
        nodeOffsetY = [levelLabelOffsetYs[levelLabelOffsetYsCount - 1] doubleValue];
      }
    }

    if (pointY <= nodePositionY - nodeOffsetY + lineHeight * (1.0f - anchorPointY)
        && pointY >= nodePositionY - nodeOffsetY - lineHeight * anchorPointY) {
      return nodeIndex;
    }
  }

  return NSNotFound;
}
