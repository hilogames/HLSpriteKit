//
//  HLOutlineLayoutManagerTests.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 2/28/18.
//  Copyright © 2018 Hilo Games. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import <XCTest/XCTest.h>

#import "HLOutlineLayoutManager.h"

@interface HLOutlineLayoutManagerTests : XCTestCase

@end

@implementation HLOutlineLayoutManagerTests

- (void)testMissingConfiguration
{
  const CGFloat HLEpsilon = 0.0001f;

  SKLabelNode *itemANode = [SKLabelNode labelNodeWithText:@"A"];
  SKLabelNode *itemA1Node = [SKLabelNode labelNodeWithText:@"1"];
  SKLabelNode *itemA2Node = [SKLabelNode labelNodeWithText:@"2"];
  SKLabelNode *itemBNode = [SKLabelNode labelNodeWithText:@"B"];
  SKLabelNode *itemB1Node = [SKLabelNode labelNodeWithText:@"1"];
  SKLabelNode *itemB2Node = [SKLabelNode labelNodeWithText:@"2"];
  NSArray *nodes = @[ itemANode, itemA1Node, itemA2Node, itemBNode, itemB1Node, itemB2Node ];
  NSArray *nodeLevels = @[ @0, @1, @1, @0, @1, @1 ];

  // Missing nodes.
  {
    HLOutlineLayoutManager *layoutManager = [[HLOutlineLayoutManager alloc] init];
    XCTAssertNoThrow([layoutManager layout:nil]);
  }

  // Missing node levels.
  {
    HLOutlineLayoutManager *layoutManager = [[HLOutlineLayoutManager alloc] init];
    layoutManager.outlinePosition = CGPointMake(100.0f, 100.0f);
    [layoutManager layout:nodes];
    // note: This is intended to assert the layout had no effect.
    XCTAssertEqualWithAccuracy(itemANode.position.y, 0.0f, HLEpsilon);
  }

  // Missing indents.
  {
    HLOutlineLayoutManager *layoutManager = [[HLOutlineLayoutManager alloc] initWithNodeLevels:nodeLevels levelIndents:nil];
    layoutManager.outlinePosition = CGPointMake(100.0f, 100.0f);
    [layoutManager layout:nodes];
    // note: This is intended to assert the layout had no effect.
    XCTAssertEqualWithAccuracy(itemANode.position.y, 0.0f, HLEpsilon);
  }
}

- (void)testBasic
{
  const CGFloat HLEpsilon = 0.0001f;

  SKLabelNode *itemANode = [SKLabelNode labelNodeWithText:@"A"];
  SKLabelNode *itemA1Node = [SKLabelNode labelNodeWithText:@"A1"];
  SKLabelNode *itemA2Node = [SKLabelNode labelNodeWithText:@"A2"];
  SKLabelNode *itemBNode = [SKLabelNode labelNodeWithText:@"B"];
  SKLabelNode *itemB1Node = [SKLabelNode labelNodeWithText:@"B1"];
  SKLabelNode *itemB2Node = [SKLabelNode labelNodeWithText:@"B2"];
  NSArray *nodes = @[ itemANode, itemA1Node, itemA2Node, itemBNode, itemB1Node, itemB2Node ];
  NSArray *nodeLevels = @[ @0, @1, @1, @0, @1, @1 ];

  // Basic layout with common configuration options.
  {
    HLOutlineLayoutManager *layoutManager = [[HLOutlineLayoutManager alloc] initWithNodeLevels:nodeLevels levelIndents:@[ @10.0f ]];
    layoutManager.anchorPointY = 1.0f;
    layoutManager.levelLineHeights = @[ @24.0f, @16.0f ];
    layoutManager.levelAnchorPointYs = @[ @0.0f ];
    layoutManager.outlinePosition = CGPointMake(3.0f, -100.0f);
    [layoutManager layout:nodes];
    XCTAssertEqualWithAccuracy(itemANode.position.y, -124.0f, HLEpsilon);
    XCTAssertEqualWithAccuracy(itemA1Node.position.y, -140.0f, HLEpsilon);
    XCTAssertEqualWithAccuracy(itemA2Node.position.y, -156.0f, HLEpsilon);
    XCTAssertEqualWithAccuracy(itemBNode.position.y, -180.0f, HLEpsilon);
    XCTAssertEqualWithAccuracy(itemB1Node.position.y, -196.0f, HLEpsilon);
    XCTAssertEqualWithAccuracy(itemB2Node.position.y, -212.0f, HLEpsilon);
    XCTAssertEqualWithAccuracy(layoutManager.height, 112.0f, HLEpsilon);
    XCTAssertEqualWithAccuracy(itemANode.position.x, 13.0f, HLEpsilon);
    XCTAssertEqualWithAccuracy(itemA1Node.position.x, 23.0f, HLEpsilon);
    XCTAssertEqualWithAccuracy(itemA2Node.position.x, 23.0f, HLEpsilon);
    XCTAssertEqualWithAccuracy(itemBNode.position.x, 13.0f, HLEpsilon);
    XCTAssertEqualWithAccuracy(itemB1Node.position.x, 23.0f, HLEpsilon);
    XCTAssertEqualWithAccuracy(itemB2Node.position.x, 23.0f, HLEpsilon);
  }

  // Separators.
  {
    HLOutlineLayoutManager *layoutManager = [[HLOutlineLayoutManager alloc] initWithNodeLevels:nodeLevels levelIndents:@[ @10.0f ]];
    layoutManager.anchorPointY = 1.0f;
    layoutManager.levelLineHeights = @[ @24.0f, @16.0f ];
    layoutManager.levelAnchorPointYs = @[ @0.0f ];
    layoutManager.levelLineBeforeSeparators = @[ @4.0f, @0.0f ];
    [layoutManager layout:nodes];
    XCTAssertEqualWithAccuracy(itemANode.position.y, -24.0f, HLEpsilon);
    XCTAssertEqualWithAccuracy(itemA1Node.position.y, -40.0f, HLEpsilon);
    XCTAssertEqualWithAccuracy(itemA2Node.position.y, -56.0f, HLEpsilon);
    XCTAssertEqualWithAccuracy(itemBNode.position.y, -84.0f, HLEpsilon);
    XCTAssertEqualWithAccuracy(itemB1Node.position.y, -100.0f, HLEpsilon);
    XCTAssertEqualWithAccuracy(itemB2Node.position.y, -116.0f, HLEpsilon);
    XCTAssertEqualWithAccuracy(layoutManager.height, 116.0f, HLEpsilon);
    layoutManager.levelLineAfterSeparators = @[ @2.0f, @0.0f ];
    [layoutManager layout:nodes];
    XCTAssertEqualWithAccuracy(itemANode.position.y, -24.0f, HLEpsilon);
    XCTAssertEqualWithAccuracy(itemA1Node.position.y, -42.0f, HLEpsilon);
    XCTAssertEqualWithAccuracy(itemA2Node.position.y, -58.0f, HLEpsilon);
    XCTAssertEqualWithAccuracy(itemBNode.position.y, -86.0f, HLEpsilon);
    XCTAssertEqualWithAccuracy(itemB1Node.position.y, -104.0f, HLEpsilon);
    XCTAssertEqualWithAccuracy(itemB2Node.position.y, -120.0f, HLEpsilon);
    XCTAssertEqualWithAccuracy(layoutManager.height, 120.0f, HLEpsilon);
  }
}

- (void)testLineHeightFit
{
  const CGFloat HLEpsilon = 0.0001f;

  SKSpriteNode *mediumNode = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor] size:CGSizeMake(20.0f, 20.0f)];
  SKSpriteNode *bigNode = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor] size:CGSizeMake(30.0f, 30.0f)];
  SKSpriteNode *smallNode = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor] size:CGSizeMake(10.0f, 10.0f)];

  NSArray *nodes = @[ mediumNode, bigNode, smallNode ];
  NSArray *nodeLevels = @[ @0, @0, @0 ];

  // Basic layout with automatic line height for nodes.
  {
    HLOutlineLayoutManager *layoutManager = [[HLOutlineLayoutManager alloc] initWithNodeLevels:nodeLevels levelIndents:@[ @10.0f ]];
    layoutManager.anchorPointY = 1.0f;
    layoutManager.levelAnchorPointYs = @[ @0.0f ];
    [layoutManager layout:nodes];
    XCTAssertEqualWithAccuracy(mediumNode.position.y, -20.0f, HLEpsilon);
    XCTAssertEqualWithAccuracy(bigNode.position.y, -50.0f, HLEpsilon);
    XCTAssertEqualWithAccuracy(smallNode.position.y, -60.0f, HLEpsilon);
    XCTAssertEqualWithAccuracy(layoutManager.height, 60.0f, HLEpsilon);
  }
}

- (void)testLineContainingPoint
{
  SKSpriteNode *mediumNode = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor] size:CGSizeMake(20.0f, 20.0f)];
  SKLabelNode *labelNode = [SKLabelNode labelNodeWithText:@"Hello I Am A Label!"];  // height 20.0 set later
  SKSpriteNode *bigNode = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor] size:CGSizeMake(30.0f, 30.0f)];
  SKSpriteNode *smallNode = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor] size:CGSizeMake(10.0f, 10.0f)];

  NSArray *nodes = @[ mediumNode, labelNode, bigNode, smallNode ];
  NSArray *nodeLevels = @[ @0, @1, @0, @0 ];
  // note: Specify fixed height for the label to keep things simple.
  NSArray *levelLineHeights = @[ @0.0f, @20.0f, @0.0f ];

  // Basic.
  {
    HLOutlineLayoutManager *layoutManager = [[HLOutlineLayoutManager alloc] initWithNodeLevels:nodeLevels levelIndents:@[ @10.0f ]];
    layoutManager.levelLineHeights = levelLineHeights;
    layoutManager.anchorPointY = 1.0f;
    [layoutManager layout:nodes];
    XCTAssertEqual(NSNotFound, HLOutlineLayoutManagerLineContainingPointY(nodes, 0.01f, nodeLevels, levelLineHeights, nil, nil));
    XCTAssertEqual(0, HLOutlineLayoutManagerLineContainingPointY(nodes, -0.01f, nodeLevels, levelLineHeights, nil, nil));
    XCTAssertEqual(0, HLOutlineLayoutManagerLineContainingPointY(nodes, -19.99f, nodeLevels, levelLineHeights, nil, nil));
    XCTAssertEqual(1, HLOutlineLayoutManagerLineContainingPointY(nodes, -20.01f, nodeLevels, levelLineHeights, nil, nil));
    XCTAssertEqual(1, HLOutlineLayoutManagerLineContainingPointY(nodes, -39.99f, nodeLevels, levelLineHeights, nil, nil));
    XCTAssertEqual(2, HLOutlineLayoutManagerLineContainingPointY(nodes, -40.01f, nodeLevels, levelLineHeights, nil, nil));
    XCTAssertEqual(2, HLOutlineLayoutManagerLineContainingPointY(nodes, -69.99f, nodeLevels, levelLineHeights, nil, nil));
    XCTAssertEqual(3, HLOutlineLayoutManagerLineContainingPointY(nodes, -70.01f, nodeLevels, levelLineHeights, nil, nil));
    XCTAssertEqual(3, HLOutlineLayoutManagerLineContainingPointY(nodes, -79.99f, nodeLevels, levelLineHeights, nil, nil));
    XCTAssertEqual(NSNotFound, HLOutlineLayoutManagerLineContainingPointY(nodes, -81.0f, nodeLevels, levelLineHeights, nil, nil));
    // Line anchor points and label offsets shouldn't affect anything.
    NSArray *levelAnchorPointYs = @[ @0.31415f ];
    layoutManager.levelAnchorPointYs = levelAnchorPointYs;
    NSArray *levelLabelOffsetYs = @[ @1.14142f ];
    layoutManager.levelLabelOffsetYs = levelLabelOffsetYs;
    [layoutManager layout:nodes];
    XCTAssertEqual(NSNotFound, HLOutlineLayoutManagerLineContainingPointY(nodes, 0.01f, nodeLevels, levelLineHeights, levelAnchorPointYs, levelLabelOffsetYs));
    XCTAssertEqual(0, HLOutlineLayoutManagerLineContainingPointY(nodes, -0.01f, nodeLevels, levelLineHeights, levelAnchorPointYs, levelLabelOffsetYs));
    XCTAssertEqual(0, HLOutlineLayoutManagerLineContainingPointY(nodes, -19.99f, nodeLevels, levelLineHeights, levelAnchorPointYs, levelLabelOffsetYs));
    XCTAssertEqual(1, HLOutlineLayoutManagerLineContainingPointY(nodes, -20.01f, nodeLevels, levelLineHeights, levelAnchorPointYs, levelLabelOffsetYs));
    XCTAssertEqual(1, HLOutlineLayoutManagerLineContainingPointY(nodes, -39.99f, nodeLevels, levelLineHeights, levelAnchorPointYs, levelLabelOffsetYs));
    XCTAssertEqual(2, HLOutlineLayoutManagerLineContainingPointY(nodes, -40.01f, nodeLevels, levelLineHeights, levelAnchorPointYs, levelLabelOffsetYs));
    XCTAssertEqual(2, HLOutlineLayoutManagerLineContainingPointY(nodes, -69.99f, nodeLevels, levelLineHeights, levelAnchorPointYs, levelLabelOffsetYs));
    XCTAssertEqual(3, HLOutlineLayoutManagerLineContainingPointY(nodes, -70.01f, nodeLevels, levelLineHeights, levelAnchorPointYs, levelLabelOffsetYs));
    XCTAssertEqual(3, HLOutlineLayoutManagerLineContainingPointY(nodes, -79.99f, nodeLevels, levelLineHeights, levelAnchorPointYs, levelLabelOffsetYs));
    XCTAssertEqual(NSNotFound, HLOutlineLayoutManagerLineContainingPointY(nodes, -80.01f, nodeLevels, levelLineHeights, levelAnchorPointYs, levelLabelOffsetYs));
  }

  // Before-separators.
  {
    HLOutlineLayoutManager *layoutManager = [[HLOutlineLayoutManager alloc] initWithNodeLevels:nodeLevels levelIndents:@[ @10.0f ]];
    layoutManager.levelLineHeights = levelLineHeights;
    layoutManager.anchorPointY = 1.0f;
    layoutManager.levelLineBeforeSeparators = @[ @3.0f, @5.0f ];
    [layoutManager layout:nodes];
    XCTAssertEqual(NSNotFound, HLOutlineLayoutManagerLineContainingPointY(nodes, 0.01f, nodeLevels, levelLineHeights, nil, nil));
    XCTAssertEqual(0, HLOutlineLayoutManagerLineContainingPointY(nodes, -0.01f, nodeLevels, levelLineHeights, nil, nil));
    XCTAssertEqual(0, HLOutlineLayoutManagerLineContainingPointY(nodes, -19.99f, nodeLevels, levelLineHeights, nil, nil));
    XCTAssertEqual(NSNotFound, HLOutlineLayoutManagerLineContainingPointY(nodes, -20.01f, nodeLevels, levelLineHeights, nil, nil));
    XCTAssertEqual(NSNotFound, HLOutlineLayoutManagerLineContainingPointY(nodes, -24.99f, nodeLevels, levelLineHeights, nil, nil));
    XCTAssertEqual(1, HLOutlineLayoutManagerLineContainingPointY(nodes, -25.01f, nodeLevels, levelLineHeights, nil, nil));
    XCTAssertEqual(1, HLOutlineLayoutManagerLineContainingPointY(nodes, -44.99f, nodeLevels, levelLineHeights, nil, nil));
    XCTAssertEqual(NSNotFound, HLOutlineLayoutManagerLineContainingPointY(nodes, -45.01f, nodeLevels, levelLineHeights, nil, nil));
    XCTAssertEqual(NSNotFound, HLOutlineLayoutManagerLineContainingPointY(nodes, -47.99f, nodeLevels, levelLineHeights, nil, nil));
    XCTAssertEqual(2, HLOutlineLayoutManagerLineContainingPointY(nodes, -48.01f, nodeLevels, levelLineHeights, nil, nil));
    XCTAssertEqual(2, HLOutlineLayoutManagerLineContainingPointY(nodes, -77.99f, nodeLevels, levelLineHeights, nil, nil));
    XCTAssertEqual(NSNotFound, HLOutlineLayoutManagerLineContainingPointY(nodes, -78.01f, nodeLevels, levelLineHeights, nil, nil));
    XCTAssertEqual(NSNotFound, HLOutlineLayoutManagerLineContainingPointY(nodes, -80.99f, nodeLevels, levelLineHeights, nil, nil));
    XCTAssertEqual(3, HLOutlineLayoutManagerLineContainingPointY(nodes, -81.01f, nodeLevels, levelLineHeights, nil, nil));
    XCTAssertEqual(3, HLOutlineLayoutManagerLineContainingPointY(nodes, -90.99f, nodeLevels, levelLineHeights, nil, nil));
    XCTAssertEqual(NSNotFound, HLOutlineLayoutManagerLineContainingPointY(nodes, -91.01f, nodeLevels, levelLineHeights, nil, nil));
    // Line anchor points and label offsets shouldn't affect anything.
    NSArray *levelAnchorPointYs = @[ @0.31415f ];
    layoutManager.levelAnchorPointYs = levelAnchorPointYs;
    NSArray *levelLabelOffsetYs = @[ @1.14142f ];
    layoutManager.levelLabelOffsetYs = levelLabelOffsetYs;
    [layoutManager layout:nodes];
    XCTAssertEqual(NSNotFound, HLOutlineLayoutManagerLineContainingPointY(nodes, 0.01f, nodeLevels, levelLineHeights, levelAnchorPointYs, levelLabelOffsetYs));
    XCTAssertEqual(0, HLOutlineLayoutManagerLineContainingPointY(nodes, -0.01f, nodeLevels, levelLineHeights, levelAnchorPointYs, levelLabelOffsetYs));
    XCTAssertEqual(0, HLOutlineLayoutManagerLineContainingPointY(nodes, -19.99f, nodeLevels, levelLineHeights, levelAnchorPointYs, levelLabelOffsetYs));
    XCTAssertEqual(NSNotFound, HLOutlineLayoutManagerLineContainingPointY(nodes, -20.01f, nodeLevels, levelLineHeights, levelAnchorPointYs, levelLabelOffsetYs));
    XCTAssertEqual(NSNotFound, HLOutlineLayoutManagerLineContainingPointY(nodes, -24.99f, nodeLevels, levelLineHeights, levelAnchorPointYs, levelLabelOffsetYs));
    XCTAssertEqual(1, HLOutlineLayoutManagerLineContainingPointY(nodes, -25.01f, nodeLevels, levelLineHeights, levelAnchorPointYs, levelLabelOffsetYs));
    XCTAssertEqual(1, HLOutlineLayoutManagerLineContainingPointY(nodes, -44.99f, nodeLevels, levelLineHeights, levelAnchorPointYs, levelLabelOffsetYs));
    XCTAssertEqual(NSNotFound, HLOutlineLayoutManagerLineContainingPointY(nodes, -45.01f, nodeLevels, levelLineHeights, levelAnchorPointYs, levelLabelOffsetYs));
    XCTAssertEqual(NSNotFound, HLOutlineLayoutManagerLineContainingPointY(nodes, -47.99f, nodeLevels, levelLineHeights, levelAnchorPointYs, levelLabelOffsetYs));
    XCTAssertEqual(2, HLOutlineLayoutManagerLineContainingPointY(nodes, -48.01f, nodeLevels, levelLineHeights, levelAnchorPointYs, levelLabelOffsetYs));
    XCTAssertEqual(2, HLOutlineLayoutManagerLineContainingPointY(nodes, -77.99f, nodeLevels, levelLineHeights, levelAnchorPointYs, levelLabelOffsetYs));
    XCTAssertEqual(NSNotFound, HLOutlineLayoutManagerLineContainingPointY(nodes, -78.01f, nodeLevels, levelLineHeights, levelAnchorPointYs, levelLabelOffsetYs));
    XCTAssertEqual(NSNotFound, HLOutlineLayoutManagerLineContainingPointY(nodes, -80.99f, nodeLevels, levelLineHeights, levelAnchorPointYs, levelLabelOffsetYs));
    XCTAssertEqual(3, HLOutlineLayoutManagerLineContainingPointY(nodes, -81.01f, nodeLevels, levelLineHeights, levelAnchorPointYs, levelLabelOffsetYs));
    XCTAssertEqual(3, HLOutlineLayoutManagerLineContainingPointY(nodes, -90.99f, nodeLevels, levelLineHeights, levelAnchorPointYs, levelLabelOffsetYs));
    XCTAssertEqual(NSNotFound, HLOutlineLayoutManagerLineContainingPointY(nodes, -91.01f, nodeLevels, levelLineHeights, levelAnchorPointYs, levelLabelOffsetYs));
  }

  // Before- and after-separators.
  {
    HLOutlineLayoutManager *layoutManager = [[HLOutlineLayoutManager alloc] initWithNodeLevels:nodeLevels levelIndents:@[ @10.0f ]];
    layoutManager.levelLineHeights = levelLineHeights;
    layoutManager.anchorPointY = 1.0f;
    layoutManager.levelLineBeforeSeparators = @[ @3.0f, @5.0f ];
    layoutManager.levelLineAfterSeparators = @[ @1.0f, @0.0 ];
    [layoutManager layout:nodes];
    XCTAssertEqual(NSNotFound, HLOutlineLayoutManagerLineContainingPointY(nodes, 0.01f, nodeLevels, levelLineHeights, nil, nil));
    XCTAssertEqual(0, HLOutlineLayoutManagerLineContainingPointY(nodes, -0.01f, nodeLevels, levelLineHeights, nil, nil));
    XCTAssertEqual(0, HLOutlineLayoutManagerLineContainingPointY(nodes, -19.99f, nodeLevels, levelLineHeights, nil, nil));
    XCTAssertEqual(NSNotFound, HLOutlineLayoutManagerLineContainingPointY(nodes, -20.01f, nodeLevels, levelLineHeights, nil, nil));
    XCTAssertEqual(NSNotFound, HLOutlineLayoutManagerLineContainingPointY(nodes, -25.99f, nodeLevels, levelLineHeights, nil, nil));
    XCTAssertEqual(1, HLOutlineLayoutManagerLineContainingPointY(nodes, -26.01f, nodeLevels, levelLineHeights, nil, nil));
    XCTAssertEqual(1, HLOutlineLayoutManagerLineContainingPointY(nodes, -45.99f, nodeLevels, levelLineHeights, nil, nil));
    XCTAssertEqual(NSNotFound, HLOutlineLayoutManagerLineContainingPointY(nodes, -46.01f, nodeLevels, levelLineHeights, nil, nil));
    XCTAssertEqual(NSNotFound, HLOutlineLayoutManagerLineContainingPointY(nodes, -48.99f, nodeLevels, levelLineHeights, nil, nil));
    XCTAssertEqual(2, HLOutlineLayoutManagerLineContainingPointY(nodes, -49.01f, nodeLevels, levelLineHeights, nil, nil));
    XCTAssertEqual(2, HLOutlineLayoutManagerLineContainingPointY(nodes, -78.99f, nodeLevels, levelLineHeights, nil, nil));
    XCTAssertEqual(NSNotFound, HLOutlineLayoutManagerLineContainingPointY(nodes, -79.01f, nodeLevels, levelLineHeights, nil, nil));
    XCTAssertEqual(NSNotFound, HLOutlineLayoutManagerLineContainingPointY(nodes, -82.99f, nodeLevels, levelLineHeights, nil, nil));
    XCTAssertEqual(3, HLOutlineLayoutManagerLineContainingPointY(nodes, -83.01f, nodeLevels, levelLineHeights, nil, nil));
    XCTAssertEqual(3, HLOutlineLayoutManagerLineContainingPointY(nodes, -92.99f, nodeLevels, levelLineHeights, nil, nil));
    XCTAssertEqual(NSNotFound, HLOutlineLayoutManagerLineContainingPointY(nodes, -93.01f, nodeLevels, levelLineHeights, nil, nil));
    // Line anchor points and label offsets shouldn't affect anything.
    NSArray *levelAnchorPointYs = @[ @0.31415f ];
    layoutManager.levelAnchorPointYs = levelAnchorPointYs;
    NSArray *levelLabelOffsetYs = @[ @1.14142f ];
    layoutManager.levelLabelOffsetYs = levelLabelOffsetYs;
    [layoutManager layout:nodes];
    XCTAssertEqual(NSNotFound, HLOutlineLayoutManagerLineContainingPointY(nodes, 0.01f, nodeLevels, levelLineHeights, levelAnchorPointYs, levelLabelOffsetYs));
    XCTAssertEqual(0, HLOutlineLayoutManagerLineContainingPointY(nodes, -0.01f, nodeLevels, levelLineHeights, levelAnchorPointYs, levelLabelOffsetYs));
    XCTAssertEqual(0, HLOutlineLayoutManagerLineContainingPointY(nodes, -19.99f, nodeLevels, levelLineHeights, levelAnchorPointYs, levelLabelOffsetYs));
    XCTAssertEqual(NSNotFound, HLOutlineLayoutManagerLineContainingPointY(nodes, -20.01f, nodeLevels, levelLineHeights, levelAnchorPointYs, levelLabelOffsetYs));
    XCTAssertEqual(NSNotFound, HLOutlineLayoutManagerLineContainingPointY(nodes, -25.99f, nodeLevels, levelLineHeights, levelAnchorPointYs, levelLabelOffsetYs));
    XCTAssertEqual(1, HLOutlineLayoutManagerLineContainingPointY(nodes, -26.01f, nodeLevels, levelLineHeights, levelAnchorPointYs, levelLabelOffsetYs));
    XCTAssertEqual(1, HLOutlineLayoutManagerLineContainingPointY(nodes, -45.99f, nodeLevels, levelLineHeights, levelAnchorPointYs, levelLabelOffsetYs));
    XCTAssertEqual(NSNotFound, HLOutlineLayoutManagerLineContainingPointY(nodes, -46.01f, nodeLevels, levelLineHeights, levelAnchorPointYs, levelLabelOffsetYs));
    XCTAssertEqual(NSNotFound, HLOutlineLayoutManagerLineContainingPointY(nodes, -48.99f, nodeLevels, levelLineHeights, levelAnchorPointYs, levelLabelOffsetYs));
    XCTAssertEqual(2, HLOutlineLayoutManagerLineContainingPointY(nodes, -49.01f, nodeLevels, levelLineHeights, levelAnchorPointYs, levelLabelOffsetYs));
    XCTAssertEqual(2, HLOutlineLayoutManagerLineContainingPointY(nodes, -78.99f, nodeLevels, levelLineHeights, levelAnchorPointYs, levelLabelOffsetYs));
    XCTAssertEqual(NSNotFound, HLOutlineLayoutManagerLineContainingPointY(nodes, -79.01f, nodeLevels, levelLineHeights, levelAnchorPointYs, levelLabelOffsetYs));
    XCTAssertEqual(NSNotFound, HLOutlineLayoutManagerLineContainingPointY(nodes, -82.99f, nodeLevels, levelLineHeights, levelAnchorPointYs, levelLabelOffsetYs));
    XCTAssertEqual(3, HLOutlineLayoutManagerLineContainingPointY(nodes, -83.01f, nodeLevels, levelLineHeights, levelAnchorPointYs, levelLabelOffsetYs));
    XCTAssertEqual(3, HLOutlineLayoutManagerLineContainingPointY(nodes, -92.99f, nodeLevels, levelLineHeights, levelAnchorPointYs, levelLabelOffsetYs));
    XCTAssertEqual(NSNotFound, HLOutlineLayoutManagerLineContainingPointY(nodes, -93.01f, nodeLevels, levelLineHeights, levelAnchorPointYs, levelLabelOffsetYs));
  }
}

@end
