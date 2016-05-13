//
//  HLMultilineLabelNodeTests.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 5/13/16.
//  Copyright © 2016 Karl Voskuil. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "HLMultilineLabelNode.h"

@interface HLMultilineLabelNodeTests : XCTestCase

@end

@implementation HLMultilineLabelNodeTests

- (void)testSize
{
  HLMultilineLabelNode *labelNode = [[HLMultilineLabelNode alloc] initWithFontNamed:@"Helvetica"];
  XCTAssertEqual(labelNode.size.width, 0.0f);
  XCTAssertEqual(labelNode.size.height, 0.0f);
  labelNode.text = @"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.";
  XCTAssertGreaterThan(labelNode.size.width, 0.0f);
  XCTAssertGreaterThan(labelNode.size.height, 0.0f);

  for (int widthMaximum = 1; widthMaximum < 100; ++widthMaximum) {
    labelNode.widthMaximum = (CGFloat)widthMaximum;
    XCTAssertLessThanOrEqual(labelNode.size.width, (CGFloat)widthMaximum);
  }
}

- (void)testEmptyStrings
{
  HLMultilineLabelNode *labelNode = [[HLMultilineLabelNode alloc] initWithFontNamed:@"Helvetica"];

  labelNode.text = @"";
  XCTAssertEqual(labelNode.size.width, 0.0f);

  labelNode.text = @" ";
  XCTAssertGreaterThan(labelNode.size.width, 0.0f);
}

@end
