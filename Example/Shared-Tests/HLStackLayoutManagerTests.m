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

- (void)testCellLabelOffsetY
{
  const CGFloat HLEpsilon = 0.0001f;

  SKSpriteNode *spriteNode = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor] size:CGSizeMake(20.0f, 20.0f)];
  SKLabelNode *labelNode = [SKLabelNode labelNodeWithText:@"Label Node"];

  HLStackLayoutManager *layoutManager = [[HLStackLayoutManager alloc] init];
  layoutManager.cellLabelOffsetY = -3.0f;

  // Different offsets for different kinds of nodes.
  {
    [layoutManager layout:@[ spriteNode, labelNode ]];
    XCTAssertEqualWithAccuracy(spriteNode.position.y, labelNode.position.y + 3.0f, HLEpsilon);
  }
}

@end
