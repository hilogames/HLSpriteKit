//
//  HLFunctionTests.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 7/19/19.
//  Copyright © 2019 Hilo Games. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "HLFunction.h"

@interface HLFunctionTests : XCTestCase

@end

@implementation HLFunctionTests

- (void)testPiecewiseLinearFunction
{
  HLPiecewiseLinearFunction *plf = [[HLPiecewiseLinearFunction alloc] initWithKnotXValues:@[ @(0.0f), @(0.5f), @(1.0f)]
                                                                              knotYValues:@[ @(0.0f), @(1.0f), @(0.0f)]];
  XCTAssertEqual([plf yForX:-999.0f], 0.0f);
  XCTAssertEqual([plf yForX:0.25f], 0.5f);
  XCTAssertEqual([plf yForX:0.5f], 1.0f);
  XCTAssertEqual([plf yForX:0.75f], 0.5f);
  XCTAssertEqual([plf yForX:999.0f], 0.0f);
}

@end
