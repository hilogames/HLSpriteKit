//
//  HLGridLayoutManagerTests.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 10/11/16.
//  Copyright © 2016 Hilo Games. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import <XCTest/XCTest.h>

#import "HLGridLayoutManager.h"

@interface HLGridLayoutManagerTests : XCTestCase

@end

@implementation HLGridLayoutManagerTests

- (void)testGridDimensions
{
  NSMutableArray *layoutNodes = [NSMutableArray array];
  for (NSInteger i = 0; i < 10; ++i) {
    [layoutNodes addObject:[SKNode node]];
  }

  {
    HLGridLayoutManager *layoutManager = [[HLGridLayoutManager alloc] initWithColumnCount:3 squareSize:CGSizeMake(10.0f, 10.0f)];
    [layoutManager layout:layoutNodes];
    XCTAssertEqual(layoutManager.columnCount, 3);
    XCTAssertEqual(layoutManager.rowCount, 4);

    layoutManager.rowCount = 3;
    [layoutManager layout:layoutNodes];
    XCTAssertEqual(layoutManager.rowCount, 3);
    XCTAssertEqual(layoutManager.columnCount, 4);
  }

  {
    HLGridLayoutManager *layoutManager = [[HLGridLayoutManager alloc] initWithRowCount:3 squareSize:CGSizeMake(10.0f, 10.0f)];
    [layoutManager layout:layoutNodes];
    XCTAssertEqual(layoutManager.rowCount, 3);
    XCTAssertEqual(layoutManager.columnCount, 4);

    layoutManager.columnCount = 3;
    [layoutManager layout:layoutNodes];
    XCTAssertEqual(layoutManager.columnCount, 3);
    XCTAssertEqual(layoutManager.rowCount, 4);
  }
}

- (void)testFillMode
{
  const CGFloat epsilon = 0.0001f;
  
  NSMutableArray *layoutNodes = [NSMutableArray array];
  for (NSInteger i = 0; i < 9; ++i) {
    [layoutNodes addObject:[SKNode node]];
  }
  
  {
    HLGridLayoutManager *layoutManager = [[HLGridLayoutManager alloc] initWithColumnCount:3 squareSize:CGSizeMake(10.0f, 10.0f)];
    layoutManager.fillMode = HLGridLayoutManagerFillRightThenDown;
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
    HLGridLayoutManager *layoutManager = [[HLGridLayoutManager alloc] initWithRowCount:3 squareSize:CGSizeMake(10.0f, 10.0f)];
    layoutManager.fillMode = HLGridLayoutManagerFillDownThenRight;
    [layoutManager layout:layoutNodes];
    
    CGFloat node0PositionX = ((SKNode *)layoutNodes[0]).position.x;
    CGFloat node1PositionX = ((SKNode *)layoutNodes[1]).position.x;
    CGFloat node2PositionX = ((SKNode *)layoutNodes[2]).position.x;
    CGFloat node3PositionX = ((SKNode *)layoutNodes[3]).position.x;
    XCTAssertEqualWithAccuracy(node0PositionX, node1PositionX, epsilon);
    XCTAssertEqualWithAccuracy(node1PositionX, node2PositionX, epsilon);
    XCTAssertGreaterThan(node3PositionX, node0PositionX);
    CGFloat node0PositionY = ((SKNode *)layoutNodes[0]).position.y;
    CGFloat node1PositionY = ((SKNode *)layoutNodes[1]).position.y;
    CGFloat node2PositionY = ((SKNode *)layoutNodes[2]).position.y;
    CGFloat node3PositionY = ((SKNode *)layoutNodes[3]).position.y;
    XCTAssertGreaterThan(node0PositionY, node1PositionY);
    XCTAssertGreaterThan(node1PositionY, node2PositionY);
    XCTAssertEqualWithAccuracy(node3PositionY, node0PositionY, epsilon);
  }
}

- (void)testSize
{
  const CGFloat epsilon = 0.0001f;

  NSMutableArray *layoutNodes = [NSMutableArray array];
  for (NSInteger i = 0; i < 9; ++i) {
    [layoutNodes addObject:[SKNode node]];
  }
  
  {
    HLGridLayoutManager *layoutManager = [[HLGridLayoutManager alloc] initWithColumnCount:3 squareSize:CGSizeMake(13.0f, 13.0f)];
    layoutManager.gridBorder = 11.0f;
    layoutManager.squareSeparator = 7.0f;
    [layoutManager layout:layoutNodes];
    XCTAssertEqualWithAccuracy(layoutManager.size.width, layoutManager.size.height, epsilon);
    XCTAssertEqualWithAccuracy(layoutManager.size.width, 75.0f, epsilon);
  }
}

@end
