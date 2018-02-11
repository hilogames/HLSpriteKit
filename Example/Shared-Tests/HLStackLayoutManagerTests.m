//
//  HLStackLayoutManagerTests.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 2/10/18.
//  Copyright © 2018 Hilo Games. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import <XCTest/XCTest.h>

#import "HLStackLayoutManager.h"

@interface HLStackLayoutManagerTests : XCTestCase

@end

@implementation HLStackLayoutManagerTests

- (void)testBaselineCellOffsetsFromVisualCenter
{
  const CGFloat HLEpsilon = 0.0001f;

  SKLabelNode *smallLabelNode = [SKLabelNode labelNodeWithText:@"Small Label Node"];
  smallLabelNode.fontSize = 10.0f;

  SKLabelNode *largeLabelNode = [SKLabelNode labelNodeWithText:@"Large Label Node"];
  largeLabelNode.fontSize = 24.0f;

  SKSpriteNode *spriteNode = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor] size:CGSizeMake(20.0f, 20.0f)];

  // Three different offsets for three different nodes.
  {
    NSArray *nodes = @[ spriteNode, smallLabelNode, largeLabelNode ];
    NSArray *cellOffsets = HLStackLayoutManagerBaselineCellOffsetsFromVisualCenter(nodes, HLLabelHeightModeFont, 0.0f);
    XCTAssertEqual([cellOffsets count], 3);
    XCTAssertEqualWithAccuracy([cellOffsets[0] doubleValue], 0.0f, HLEpsilon);
    XCTAssertNotEqualWithAccuracy([cellOffsets[1] doubleValue], 0.0f, HLEpsilon);
    XCTAssertNotEqualWithAccuracy([cellOffsets[2] doubleValue], 0.0f, HLEpsilon);
    XCTAssertNotEqualWithAccuracy([cellOffsets[1] doubleValue], [cellOffsets[2] doubleValue], HLEpsilon);
  }

  // No need to repeat same offset three times.
  {
    NSArray *nodes = @[ smallLabelNode, smallLabelNode, smallLabelNode ];
    NSArray *cellOffsets = HLStackLayoutManagerBaselineCellOffsetsFromVisualCenter(nodes, HLLabelHeightModeFont, 0.0f);
    XCTAssertEqual([cellOffsets count], 1);
  }

  // In particular, no need to repeat at the end of the list.
  {
    NSArray *nodes = @[ largeLabelNode, smallLabelNode, smallLabelNode, smallLabelNode ];
    NSArray *cellOffsets = HLStackLayoutManagerBaselineCellOffsetsFromVisualCenter(nodes, HLLabelHeightModeFont, 0.0f);
    XCTAssertEqual([cellOffsets count], 2);
  }

  // But the same offset does need to be repeated if in the middle of the list.
  {
    NSArray *nodes = @[ smallLabelNode, smallLabelNode, smallLabelNode, largeLabelNode ];
    NSArray *cellOffsets = HLStackLayoutManagerBaselineCellOffsetsFromVisualCenter(nodes, HLLabelHeightModeFont, 0.0f);
    XCTAssertEqual([cellOffsets count], 4);
  }

  // Don't need offsets at all if there aren't any label nodes.
  {
    NSArray *nodes = @[ spriteNode, spriteNode ];
    NSArray *cellOffsets = HLStackLayoutManagerBaselineCellOffsetsFromVisualCenter(nodes, HLLabelHeightModeFont, 0.0f);
    XCTAssertEqual([cellOffsets count], 0);
  }
}

@end
