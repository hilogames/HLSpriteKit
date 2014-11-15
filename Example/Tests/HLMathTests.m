//
//  HLMathTests.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 11/14/14.
//  Copyright (c) 2014 Karl Voskuil. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "HLMath.h"

@interface HLMathTests : XCTestCase

@end

@implementation HLMathTests

- (void)testHLGetBoundsForTransformation
{
  {
    CGSize originalSize = CGSizeMake(10.0f, 20.0f);
    CGFloat rotation = M_PI_2;
    CGSize transformedSize = HLGetBoundsForTransformation(originalSize, rotation);
    XCTAssertEqualWithAccuracy(transformedSize.width, originalSize.height, 0.0001f);
    XCTAssertEqualWithAccuracy(transformedSize.height, originalSize.width, 0.0001f);
  }

  {
    CGSize originalSize = CGSizeMake(10.0f, 10.0f);
    CGFloat rotation = M_PI_2 / 2.0f;
    CGSize transformedSize = HLGetBoundsForTransformation(originalSize, rotation);
    XCTAssertEqualWithAccuracy(transformedSize.width, originalSize.width * sqrt(2.0), 0.0001f);
    XCTAssertEqualWithAccuracy(transformedSize.height, originalSize.height * sqrt(2.0), 0.0001f);
  }
}

@end
