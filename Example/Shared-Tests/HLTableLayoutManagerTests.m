//
//  HLTableLayoutManagerTests.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 11/15/14.
//  Copyright (c) 2014 Karl Voskuil. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import <XCTest/XCTest.h>
#import <TargetConditionals.h>

#import "HLTableLayoutManager.h"

@interface HLTableLayoutManagerTests : XCTestCase

@end

@implementation HLTableLayoutManagerTests

- (void)testLayoutGeometry
{
  const CGFloat epsilon = 0.0001f;

  HLTableLayoutManager *layoutManager = [[HLTableLayoutManager alloc] init];

  NSMutableArray *layoutNodes = [NSMutableArray array];
  for (NSInteger i = 0; i < 9; ++i) {
    [layoutNodes addObject:[SKNode node]];
  }

  layoutManager.anchorPoint = CGPointZero;
  layoutManager.columnCount = 3;
#if TARGET_OS_IPHONE
  layoutManager.columnAnchorPoints = @[ [NSValue valueWithCGPoint:CGPointMake(0.5f, 0.5f)] ];
#else
  layoutManager.columnAnchorPoints = @[ [NSValue valueWithPoint:NSMakePoint(0.5f, 0.5f)] ];
#endif

  {
    layoutManager.columnWidths = @[ @(10.0f) ];
    layoutManager.rowHeights = @[ @(10.0f) ];
    [layoutManager layout:layoutNodes];

    CGFloat node0PositionX = ((SKNode *)layoutNodes[0]).position.x;
    CGFloat node1PositionX = ((SKNode *)layoutNodes[1]).position.x;
    CGFloat node2PositionX = ((SKNode *)layoutNodes[2]).position.x;
    CGFloat node3PositionX = ((SKNode *)layoutNodes[3]).position.x;
    XCTAssertLessThan(node0PositionX, node1PositionX);
    XCTAssertLessThan(node1PositionX, node2PositionX);
    XCTAssertEqualWithAccuracy(node3PositionX, node0PositionX, epsilon);
    CGFloat node0PositionY = ((SKNode *)layoutNodes[0]).position.y;
    CGFloat node1PositionY = ((SKNode *)layoutNodes[1]).position.y;
    CGFloat node2PositionY = ((SKNode *)layoutNodes[2]).position.y;
    CGFloat node3PositionY = ((SKNode *)layoutNodes[3]).position.y;
    XCTAssertEqualWithAccuracy(node0PositionY, node1PositionY, epsilon);
    XCTAssertEqualWithAccuracy(node1PositionY, node2PositionY, epsilon);
    XCTAssertGreaterThan(node0PositionY, node3PositionY);
  }

  {
    layoutManager.columnWidths = @[ @(-1.0f), @(0.0f), @(-2.0f) ];
    layoutManager.rowHeights = @[ @(-1.0f), @(0.0f), @(-2.0f) ];
    layoutManager.constrainedSize = CGSizeMake(30.0f, 30.0f);
    [layoutManager layout:layoutNodes];
    
    CGFloat node3PositionX = ((SKNode *)layoutNodes[3]).position.x;
    CGFloat node4PositionX = ((SKNode *)layoutNodes[4]).position.x;
    CGFloat node5PositionX = ((SKNode *)layoutNodes[5]).position.x;
    XCTAssertEqualWithAccuracy(node3PositionX, 5.0f, epsilon);
    XCTAssertEqualWithAccuracy(node4PositionX, 10.0f, epsilon);
    XCTAssertEqualWithAccuracy(node5PositionX, 20.0f, epsilon);
    CGFloat node1PositionY = ((SKNode *)layoutNodes[1]).position.y;
    CGFloat node4PositionY = ((SKNode *)layoutNodes[4]).position.y;
    CGFloat node7PositionY = ((SKNode *)layoutNodes[7]).position.y;
    XCTAssertEqualWithAccuracy(node1PositionY, 25.0f, epsilon);
    XCTAssertEqualWithAccuracy(node4PositionY, 20.0f, epsilon);
    XCTAssertEqualWithAccuracy(node7PositionY, 10.0f, epsilon);
  }
}

@end
