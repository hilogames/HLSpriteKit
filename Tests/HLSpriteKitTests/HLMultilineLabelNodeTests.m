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

#if TARGET_OS_IPHONE
  // note: The behavior of the underlying bounds calculation changed in iOS 9.0.  Previously, the
  // the width of the multiline label node might be wider than the provided maximum.
  NSOperatingSystemVersion iOS90000Version = { 9, 0, 0 };
  if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:iOS90000Version]) {
    for (int widthMaximum = 1; widthMaximum < 100; ++widthMaximum) {
      labelNode.widthMaximum = (CGFloat)widthMaximum;
      XCTAssertLessThanOrEqual(labelNode.size.width, (CGFloat)widthMaximum);
    }
  }
#else
  for (int widthMaximum = 1; widthMaximum < 100; ++widthMaximum) {
    labelNode.widthMaximum = (CGFloat)widthMaximum;
    XCTAssertLessThanOrEqual(labelNode.size.width, (CGFloat)widthMaximum);
  }
#endif
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
