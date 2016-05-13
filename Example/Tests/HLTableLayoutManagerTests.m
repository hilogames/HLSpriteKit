//
//  HLTableLayoutManagerTests.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 11/15/14.
//  Copyright (c) 2014 Karl Voskuil. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import <XCTest/XCTest.h>

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
  layoutManager.columnAnchorPoints = @[ [NSValue valueWithCGPoint:CGPointMake(0.5f, 0.5f)] ];

  {
    layoutManager.columnWidths = @[ @(10.0f) ];
    layoutManager.rowHeights = @[ @(10.0f) ];
    [layoutManager layout:layoutNodes];

    XCTAssertLessThan([layoutNodes[0] position].x, [layoutNodes[1] position].x);
    XCTAssertLessThan([layoutNodes[1] position].x, [layoutNodes[2] position].x);
    XCTAssertEqualWithAccuracy([layoutNodes[3] position].x, [layoutNodes[0] position].x, epsilon);
    XCTAssertEqualWithAccuracy([layoutNodes[0] position].y, [layoutNodes[1] position].y, epsilon);
    XCTAssertEqualWithAccuracy([layoutNodes[1] position].y, [layoutNodes[2] position].y, epsilon);
    XCTAssertGreaterThan([layoutNodes[0] position].y, [layoutNodes[3] position].y);
  }

  {
    layoutManager.columnWidths = @[ @(-1.0f), @(0.0f), @(-2.0f) ];
    layoutManager.rowHeights = @[ @(-1.0f), @(0.0f), @(-2.0f) ];
    layoutManager.constrainedSize = CGSizeMake(30.0f, 30.0f);
    [layoutManager layout:layoutNodes];
    
    XCTAssertEqualWithAccuracy([layoutNodes[3] position].x, 5.0f, epsilon);
    XCTAssertEqualWithAccuracy([layoutNodes[4] position].x, 10.0f, epsilon);
    XCTAssertEqualWithAccuracy([layoutNodes[5] position].x, 20.0f, epsilon);
    XCTAssertEqualWithAccuracy([layoutNodes[1] position].y, 25.0f, epsilon);
    XCTAssertEqualWithAccuracy([layoutNodes[4] position].y, 20.0f, epsilon);
    XCTAssertEqualWithAccuracy([layoutNodes[7] position].y, 10.0f, epsilon);
  }
}

@end
