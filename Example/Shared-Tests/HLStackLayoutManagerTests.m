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

- (void)testBasic
{
  const CGFloat HLEpsilon = 0.0001f;

  SKSpriteNode *mediumNode = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor] size:CGSizeMake(20.0f, 20.0f)];
  SKSpriteNode *bigNode = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor] size:CGSizeMake(30.0f, 30.0f)];
  SKSpriteNode *smallNode = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor] size:CGSizeMake(10.0f, 10.0f)];

  NSArray *nodes = @[ mediumNode, bigNode, smallNode ];

  // Basic layout with automatic length.
  {
    HLStackLayoutManager *layoutManager = [[HLStackLayoutManager alloc] initWithStackDirection:HLStackLayoutManagerStackRight];
    layoutManager.anchorPoint = 0.0f;
    layoutManager.cellAnchorPoints = @[ @1.0f ];
    [layoutManager layout:nodes];
    XCTAssertEqualWithAccuracy(mediumNode.position.x, 20.0f, HLEpsilon);
    XCTAssertEqualWithAccuracy(bigNode.position.x, 50.0f, HLEpsilon);
    XCTAssertEqualWithAccuracy(smallNode.position.x, 60.0f, HLEpsilon);
    XCTAssertEqualWithAccuracy(layoutManager.length, 60.0f, HLEpsilon);
    layoutManager.stackDirection = HLStackLayoutManagerStackUp;
    [layoutManager layout:nodes];
    XCTAssertEqualWithAccuracy(mediumNode.position.y, 20.0f, HLEpsilon);
    XCTAssertEqualWithAccuracy(bigNode.position.y, 50.0f, HLEpsilon);
    XCTAssertEqualWithAccuracy(smallNode.position.y, 60.0f, HLEpsilon);
    XCTAssertEqualWithAccuracy(layoutManager.length, 60.0f, HLEpsilon);
  }

  // With cell separator and border.
  {
    HLStackLayoutManager *layoutManager = [[HLStackLayoutManager alloc] initWithStackDirection:HLStackLayoutManagerStackRight];
    layoutManager.anchorPoint = 0.0f;
    layoutManager.cellAnchorPoints = @[ @1.0f ];
    layoutManager.stackBorder = 1.0f;
    layoutManager.cellSeparator = 3.0f;
    [layoutManager layout:nodes];
    XCTAssertEqualWithAccuracy(mediumNode.position.x, 21.0f, HLEpsilon);
    XCTAssertEqualWithAccuracy(bigNode.position.x, 54.0f, HLEpsilon);
    XCTAssertEqualWithAccuracy(smallNode.position.x, 67.0f, HLEpsilon);
    XCTAssertEqualWithAccuracy(layoutManager.length, 68.0f, HLEpsilon);
    layoutManager.stackDirection = HLStackLayoutManagerStackUp;
    [layoutManager layout:nodes];
    XCTAssertEqualWithAccuracy(mediumNode.position.y, 21.0f, HLEpsilon);
    XCTAssertEqualWithAccuracy(bigNode.position.y, 54.0f, HLEpsilon);
    XCTAssertEqualWithAccuracy(smallNode.position.y, 67.0f, HLEpsilon);
    XCTAssertEqualWithAccuracy(layoutManager.length, 68.0f, HLEpsilon);
  }
}

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

- (void)testCellContainingPoint
{
  SKSpriteNode *mediumNode = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor] size:CGSizeMake(20.0f, 20.0f)];
  SKLabelNode *labelNode = [SKLabelNode labelNodeWithText:@"Hello I Am A Label!"];  // length 2.0 set later
  SKSpriteNode *bigNode = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor] size:CGSizeMake(30.0f, 30.0f)];
  SKSpriteNode *smallNode = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor] size:CGSizeMake(10.0f, 10.0f)];

  NSArray *nodes = @[ mediumNode, labelNode, bigNode, smallNode ];
  // note: Specify fixed length for the label to keep things simple.
  NSArray *cellLengths = @[ @0.0f, @20.0f, @0.0f ];

  // Basic.
  {
    HLStackLayoutManager *layoutManager = [[HLStackLayoutManager alloc] initWithStackDirection:HLStackLayoutManagerStackRight
                                                                                   cellLengths:cellLengths];
    layoutManager.anchorPoint = 0.0f;
    [layoutManager layout:nodes];
    XCTAssertEqual(NSNotFound, HLStackLayoutManagerCellContainingPoint(nodes, -0.01f, HLStackLayoutManagerStackRight, cellLengths, nil, 0.0f));
    XCTAssertEqual(0, HLStackLayoutManagerCellContainingPoint(nodes, 0.01f, HLStackLayoutManagerStackRight, cellLengths, nil, 0.0f));
    XCTAssertEqual(0, HLStackLayoutManagerCellContainingPoint(nodes, 19.99f, HLStackLayoutManagerStackRight, cellLengths, nil, 0.0f));
    XCTAssertEqual(1, HLStackLayoutManagerCellContainingPoint(nodes, 20.01f, HLStackLayoutManagerStackRight, cellLengths, nil, 0.0f));
    XCTAssertEqual(1, HLStackLayoutManagerCellContainingPoint(nodes, 39.99f, HLStackLayoutManagerStackRight, cellLengths, nil, 0.0f));
    XCTAssertEqual(2, HLStackLayoutManagerCellContainingPoint(nodes, 40.01f, HLStackLayoutManagerStackRight, cellLengths, nil, 0.0f));
    XCTAssertEqual(2, HLStackLayoutManagerCellContainingPoint(nodes, 69.99f, HLStackLayoutManagerStackRight, cellLengths, nil, 0.0f));
    XCTAssertEqual(3, HLStackLayoutManagerCellContainingPoint(nodes, 70.01f, HLStackLayoutManagerStackRight, cellLengths, nil, 0.0f));
    XCTAssertEqual(3, HLStackLayoutManagerCellContainingPoint(nodes, 79.99f, HLStackLayoutManagerStackRight, cellLengths, nil, 0.0f));
    XCTAssertEqual(NSNotFound, HLStackLayoutManagerCellContainingPoint(nodes, 81.0f, HLStackLayoutManagerStackRight, cellLengths, nil, 0.0f));
    // Stacking dimension shouldn't affect anything.
    layoutManager.stackDirection = HLStackLayoutManagerStackUp;
    [layoutManager layout:nodes];
    XCTAssertEqual(NSNotFound, HLStackLayoutManagerCellContainingPoint(nodes, -0.01f, HLStackLayoutManagerStackUp, cellLengths, nil, 0.0f));
    XCTAssertEqual(0, HLStackLayoutManagerCellContainingPoint(nodes, 0.01f, HLStackLayoutManagerStackUp, cellLengths, nil, 0.0f));
    XCTAssertEqual(0, HLStackLayoutManagerCellContainingPoint(nodes, 19.99f, HLStackLayoutManagerStackUp, cellLengths, nil, 0.0f));
    XCTAssertEqual(1, HLStackLayoutManagerCellContainingPoint(nodes, 20.01f, HLStackLayoutManagerStackUp, cellLengths, nil, 0.0f));
    XCTAssertEqual(1, HLStackLayoutManagerCellContainingPoint(nodes, 39.99f, HLStackLayoutManagerStackUp, cellLengths, nil, 0.0f));
    XCTAssertEqual(2, HLStackLayoutManagerCellContainingPoint(nodes, 40.01f, HLStackLayoutManagerStackUp, cellLengths, nil, 0.0f));
    XCTAssertEqual(2, HLStackLayoutManagerCellContainingPoint(nodes, 69.99f, HLStackLayoutManagerStackUp, cellLengths, nil, 0.0f));
    XCTAssertEqual(3, HLStackLayoutManagerCellContainingPoint(nodes, 70.01f, HLStackLayoutManagerStackUp, cellLengths, nil, 0.0f));
    XCTAssertEqual(3, HLStackLayoutManagerCellContainingPoint(nodes, 79.99f, HLStackLayoutManagerStackUp, cellLengths, nil, 0.0f));
    XCTAssertEqual(NSNotFound, HLStackLayoutManagerCellContainingPoint(nodes, 81.0f, HLStackLayoutManagerStackUp, cellLengths, nil, 0.0f));
    // Cell anchor points and label offsets shouldn't affect anything.
    NSArray *cellAnchorPoints = @[ @0.31415f ];
    layoutManager.cellAnchorPoints = cellAnchorPoints;
    CGFloat cellLabelOffsetY = 1.14142f;
    layoutManager.cellLabelOffsetY = cellLabelOffsetY;
    [layoutManager layout:nodes];
    XCTAssertEqual(NSNotFound, HLStackLayoutManagerCellContainingPoint(nodes, -0.01f, HLStackLayoutManagerStackUp, cellLengths, cellAnchorPoints, cellLabelOffsetY));
    XCTAssertEqual(0, HLStackLayoutManagerCellContainingPoint(nodes, 0.01f, HLStackLayoutManagerStackUp, cellLengths, cellAnchorPoints, cellLabelOffsetY));
    XCTAssertEqual(0, HLStackLayoutManagerCellContainingPoint(nodes, 19.99f, HLStackLayoutManagerStackUp, cellLengths, cellAnchorPoints, cellLabelOffsetY));
    XCTAssertEqual(1, HLStackLayoutManagerCellContainingPoint(nodes, 20.01f, HLStackLayoutManagerStackUp, cellLengths, cellAnchorPoints, cellLabelOffsetY));
    XCTAssertEqual(1, HLStackLayoutManagerCellContainingPoint(nodes, 39.99f, HLStackLayoutManagerStackUp, cellLengths, cellAnchorPoints, cellLabelOffsetY));
    XCTAssertEqual(2, HLStackLayoutManagerCellContainingPoint(nodes, 40.01f, HLStackLayoutManagerStackUp, cellLengths, cellAnchorPoints, cellLabelOffsetY));
    XCTAssertEqual(2, HLStackLayoutManagerCellContainingPoint(nodes, 69.99f, HLStackLayoutManagerStackUp, cellLengths, cellAnchorPoints, cellLabelOffsetY));
    XCTAssertEqual(3, HLStackLayoutManagerCellContainingPoint(nodes, 70.01f, HLStackLayoutManagerStackUp, cellLengths, cellAnchorPoints, cellLabelOffsetY));
    XCTAssertEqual(3, HLStackLayoutManagerCellContainingPoint(nodes, 79.99f, HLStackLayoutManagerStackUp, cellLengths, cellAnchorPoints, cellLabelOffsetY));
    XCTAssertEqual(NSNotFound, HLStackLayoutManagerCellContainingPoint(nodes, 80.01f, HLStackLayoutManagerStackUp, cellLengths, cellAnchorPoints, cellLabelOffsetY));
  }

  // Separator and border.
  {
    HLStackLayoutManager *layoutManager = [[HLStackLayoutManager alloc] initWithStackDirection:HLStackLayoutManagerStackRight
                                                                                   cellLengths:cellLengths];
    layoutManager.anchorPoint = 0.0f;
    layoutManager.stackBorder = 1.0f;
    layoutManager.cellSeparator = 3.0f;
    [layoutManager layout:nodes];
    XCTAssertEqual(NSNotFound, HLStackLayoutManagerCellContainingPoint(nodes, 0.99f, HLStackLayoutManagerStackRight, cellLengths, nil, 0.0f));
    XCTAssertEqual(0, HLStackLayoutManagerCellContainingPoint(nodes, 1.01f, HLStackLayoutManagerStackRight, cellLengths, nil, 0.0f));
    XCTAssertEqual(0, HLStackLayoutManagerCellContainingPoint(nodes, 20.99f, HLStackLayoutManagerStackRight, cellLengths, nil, 0.0f));
    XCTAssertEqual(NSNotFound, HLStackLayoutManagerCellContainingPoint(nodes, 21.01f, HLStackLayoutManagerStackRight, cellLengths, nil, 0.0f));
    XCTAssertEqual(NSNotFound, HLStackLayoutManagerCellContainingPoint(nodes, 23.99f, HLStackLayoutManagerStackRight, cellLengths, nil, 0.0f));
    XCTAssertEqual(1, HLStackLayoutManagerCellContainingPoint(nodes, 24.01f, HLStackLayoutManagerStackRight, cellLengths, nil, 0.0f));
    XCTAssertEqual(1, HLStackLayoutManagerCellContainingPoint(nodes, 43.99f, HLStackLayoutManagerStackRight, cellLengths, nil, 0.0f));
    XCTAssertEqual(NSNotFound, HLStackLayoutManagerCellContainingPoint(nodes, 44.01f, HLStackLayoutManagerStackRight, cellLengths, nil, 0.0f));
    XCTAssertEqual(NSNotFound, HLStackLayoutManagerCellContainingPoint(nodes, 45.99f, HLStackLayoutManagerStackRight, cellLengths, nil, 0.0f));
    XCTAssertEqual(2, HLStackLayoutManagerCellContainingPoint(nodes, 47.01f, HLStackLayoutManagerStackRight, cellLengths, nil, 0.0f));
    XCTAssertEqual(2, HLStackLayoutManagerCellContainingPoint(nodes, 76.99f, HLStackLayoutManagerStackRight, cellLengths, nil, 0.0f));
    XCTAssertEqual(NSNotFound, HLStackLayoutManagerCellContainingPoint(nodes, 77.01f, HLStackLayoutManagerStackRight, cellLengths, nil, 0.0f));
    XCTAssertEqual(NSNotFound, HLStackLayoutManagerCellContainingPoint(nodes, 79.99f, HLStackLayoutManagerStackRight, cellLengths, nil, 0.0f));
    XCTAssertEqual(3, HLStackLayoutManagerCellContainingPoint(nodes, 80.01f, HLStackLayoutManagerStackRight, cellLengths, nil, 0.0f));
    XCTAssertEqual(3, HLStackLayoutManagerCellContainingPoint(nodes, 89.99f, HLStackLayoutManagerStackRight, cellLengths, nil, 0.0f));
    XCTAssertEqual(NSNotFound, HLStackLayoutManagerCellContainingPoint(nodes, 90.01f, HLStackLayoutManagerStackRight, cellLengths, nil, 0.0f));
    // Stacking dimension shouldn't affect anything.
    layoutManager.stackDirection = HLStackLayoutManagerStackUp;
    [layoutManager layout:nodes];
    XCTAssertEqual(NSNotFound, HLStackLayoutManagerCellContainingPoint(nodes, 0.99f, HLStackLayoutManagerStackUp, cellLengths, nil, 0.0f));
    XCTAssertEqual(0, HLStackLayoutManagerCellContainingPoint(nodes, 1.01f, HLStackLayoutManagerStackUp, cellLengths, nil, 0.0f));
    XCTAssertEqual(0, HLStackLayoutManagerCellContainingPoint(nodes, 20.99f, HLStackLayoutManagerStackUp, cellLengths, nil, 0.0f));
    XCTAssertEqual(NSNotFound, HLStackLayoutManagerCellContainingPoint(nodes, 21.01f, HLStackLayoutManagerStackUp, cellLengths, nil, 0.0f));
    XCTAssertEqual(NSNotFound, HLStackLayoutManagerCellContainingPoint(nodes, 23.99f, HLStackLayoutManagerStackUp, cellLengths, nil, 0.0f));
    XCTAssertEqual(1, HLStackLayoutManagerCellContainingPoint(nodes, 24.01f, HLStackLayoutManagerStackUp, cellLengths, nil, 0.0f));
    XCTAssertEqual(1, HLStackLayoutManagerCellContainingPoint(nodes, 43.99f, HLStackLayoutManagerStackUp, cellLengths, nil, 0.0f));
    XCTAssertEqual(NSNotFound, HLStackLayoutManagerCellContainingPoint(nodes, 44.01f, HLStackLayoutManagerStackUp, cellLengths, nil, 0.0f));
    XCTAssertEqual(NSNotFound, HLStackLayoutManagerCellContainingPoint(nodes, 45.99f, HLStackLayoutManagerStackUp, cellLengths, nil, 0.0f));
    XCTAssertEqual(2, HLStackLayoutManagerCellContainingPoint(nodes, 47.01f, HLStackLayoutManagerStackUp, cellLengths, nil, 0.0f));
    XCTAssertEqual(2, HLStackLayoutManagerCellContainingPoint(nodes, 76.99f, HLStackLayoutManagerStackUp, cellLengths, nil, 0.0f));
    XCTAssertEqual(NSNotFound, HLStackLayoutManagerCellContainingPoint(nodes, 77.01f, HLStackLayoutManagerStackUp, cellLengths, nil, 0.0f));
    XCTAssertEqual(NSNotFound, HLStackLayoutManagerCellContainingPoint(nodes, 79.99f, HLStackLayoutManagerStackUp, cellLengths, nil, 0.0f));
    XCTAssertEqual(3, HLStackLayoutManagerCellContainingPoint(nodes, 80.01f, HLStackLayoutManagerStackUp, cellLengths, nil, 0.0f));
    XCTAssertEqual(3, HLStackLayoutManagerCellContainingPoint(nodes, 89.99f, HLStackLayoutManagerStackUp, cellLengths, nil, 0.0f));
    XCTAssertEqual(NSNotFound, HLStackLayoutManagerCellContainingPoint(nodes, 90.01f, HLStackLayoutManagerStackUp, cellLengths, nil, 0.0f));
    // Stacking direction can invert numerical values, though.
    layoutManager.stackDirection = HLStackLayoutManagerStackDown;
    layoutManager.anchorPoint = 1.0f;
    [layoutManager layout:nodes];
    XCTAssertEqual(NSNotFound, HLStackLayoutManagerCellContainingPoint(nodes, -0.99f, HLStackLayoutManagerStackDown, cellLengths, nil, 0.0f));
    XCTAssertEqual(0, HLStackLayoutManagerCellContainingPoint(nodes, -1.01f, HLStackLayoutManagerStackDown, cellLengths, nil, 0.0f));
    XCTAssertEqual(0, HLStackLayoutManagerCellContainingPoint(nodes, -20.99f, HLStackLayoutManagerStackDown, cellLengths, nil, 0.0f));
    XCTAssertEqual(NSNotFound, HLStackLayoutManagerCellContainingPoint(nodes, -21.01f, HLStackLayoutManagerStackDown, cellLengths, nil, 0.0f));
    XCTAssertEqual(NSNotFound, HLStackLayoutManagerCellContainingPoint(nodes, -23.99f, HLStackLayoutManagerStackDown, cellLengths, nil, 0.0f));
    XCTAssertEqual(1, HLStackLayoutManagerCellContainingPoint(nodes, -24.01f, HLStackLayoutManagerStackDown, cellLengths, nil, 0.0f));
    XCTAssertEqual(1, HLStackLayoutManagerCellContainingPoint(nodes, -43.99f, HLStackLayoutManagerStackDown, cellLengths, nil, 0.0f));
    XCTAssertEqual(NSNotFound, HLStackLayoutManagerCellContainingPoint(nodes, -44.01f, HLStackLayoutManagerStackDown, cellLengths, nil, 0.0f));
    XCTAssertEqual(NSNotFound, HLStackLayoutManagerCellContainingPoint(nodes, -45.99f, HLStackLayoutManagerStackDown, cellLengths, nil, 0.0f));
    XCTAssertEqual(2, HLStackLayoutManagerCellContainingPoint(nodes, -47.01f, HLStackLayoutManagerStackDown, cellLengths, nil, 0.0f));
    XCTAssertEqual(2, HLStackLayoutManagerCellContainingPoint(nodes, -76.99f, HLStackLayoutManagerStackDown, cellLengths, nil, 0.0f));
    XCTAssertEqual(NSNotFound, HLStackLayoutManagerCellContainingPoint(nodes, -77.01f, HLStackLayoutManagerStackDown, cellLengths, nil, 0.0f));
    XCTAssertEqual(NSNotFound, HLStackLayoutManagerCellContainingPoint(nodes, -79.99f, HLStackLayoutManagerStackDown, cellLengths, nil, 0.0f));
    XCTAssertEqual(3, HLStackLayoutManagerCellContainingPoint(nodes, -80.01f, HLStackLayoutManagerStackDown, cellLengths, nil, 0.0f));
    XCTAssertEqual(3, HLStackLayoutManagerCellContainingPoint(nodes, -89.99f, HLStackLayoutManagerStackDown, cellLengths, nil, 0.0f));
    XCTAssertEqual(NSNotFound, HLStackLayoutManagerCellContainingPoint(nodes, -90.01f, HLStackLayoutManagerStackDown, cellLengths, nil, 0.0f));
    // Cell anchor points and label offsets shouldn't affect anything.
    NSArray *cellAnchorPoints = @[ @0.31415f ];
    layoutManager.cellAnchorPoints = cellAnchorPoints;
    CGFloat cellLabelOffsetY = 1.14142f;
    layoutManager.cellLabelOffsetY = cellLabelOffsetY;
    [layoutManager layout:nodes];
    XCTAssertEqual(NSNotFound, HLStackLayoutManagerCellContainingPoint(nodes, -0.99f, HLStackLayoutManagerStackDown, cellLengths, cellAnchorPoints, cellLabelOffsetY));
    XCTAssertEqual(0, HLStackLayoutManagerCellContainingPoint(nodes, -1.01f, HLStackLayoutManagerStackDown, cellLengths, cellAnchorPoints, cellLabelOffsetY));
    XCTAssertEqual(0, HLStackLayoutManagerCellContainingPoint(nodes, -20.99f, HLStackLayoutManagerStackDown, cellLengths, cellAnchorPoints, cellLabelOffsetY));
    XCTAssertEqual(NSNotFound, HLStackLayoutManagerCellContainingPoint(nodes, -21.01f, HLStackLayoutManagerStackDown, cellLengths, cellAnchorPoints, cellLabelOffsetY));
    XCTAssertEqual(NSNotFound, HLStackLayoutManagerCellContainingPoint(nodes, -23.99f, HLStackLayoutManagerStackDown, cellLengths, cellAnchorPoints, cellLabelOffsetY));
    XCTAssertEqual(1, HLStackLayoutManagerCellContainingPoint(nodes, -24.01f, HLStackLayoutManagerStackDown, cellLengths, cellAnchorPoints, cellLabelOffsetY));
    XCTAssertEqual(1, HLStackLayoutManagerCellContainingPoint(nodes, -43.99f, HLStackLayoutManagerStackDown, cellLengths, cellAnchorPoints, cellLabelOffsetY));
    XCTAssertEqual(NSNotFound, HLStackLayoutManagerCellContainingPoint(nodes, -44.01f, HLStackLayoutManagerStackDown, cellLengths, cellAnchorPoints, cellLabelOffsetY));
    XCTAssertEqual(NSNotFound, HLStackLayoutManagerCellContainingPoint(nodes, -45.99f, HLStackLayoutManagerStackDown, cellLengths, cellAnchorPoints, cellLabelOffsetY));
    XCTAssertEqual(2, HLStackLayoutManagerCellContainingPoint(nodes, -47.01f, HLStackLayoutManagerStackDown, cellLengths, cellAnchorPoints, cellLabelOffsetY));
    XCTAssertEqual(2, HLStackLayoutManagerCellContainingPoint(nodes, -76.99f, HLStackLayoutManagerStackDown, cellLengths, cellAnchorPoints, cellLabelOffsetY));
    XCTAssertEqual(NSNotFound, HLStackLayoutManagerCellContainingPoint(nodes, -77.01f, HLStackLayoutManagerStackDown, cellLengths, cellAnchorPoints, cellLabelOffsetY));
    XCTAssertEqual(NSNotFound, HLStackLayoutManagerCellContainingPoint(nodes, -79.99f, HLStackLayoutManagerStackDown, cellLengths, cellAnchorPoints, cellLabelOffsetY));
    XCTAssertEqual(3, HLStackLayoutManagerCellContainingPoint(nodes, -80.01f, HLStackLayoutManagerStackDown, cellLengths, cellAnchorPoints, cellLabelOffsetY));
    XCTAssertEqual(3, HLStackLayoutManagerCellContainingPoint(nodes, -89.99f, HLStackLayoutManagerStackDown, cellLengths, cellAnchorPoints, cellLabelOffsetY));
    XCTAssertEqual(NSNotFound, HLStackLayoutManagerCellContainingPoint(nodes, -90.01f, HLStackLayoutManagerStackDown, cellLengths, cellAnchorPoints, cellLabelOffsetY));
  }
}

@end
