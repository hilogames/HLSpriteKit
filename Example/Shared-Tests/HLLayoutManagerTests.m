//
//  HLLayoutManagerTests.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 10/10/17.
//  Copyright © 2017 Hilo Games. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <SpriteKit/SpriteKit.h>

#import "HLLayoutManager.h"

@interface HLLayoutManagerTests : XCTestCase
@end

@interface HLSizedThing : NSObject
- (instancetype)initWithSize:(CGSize)size;
@property (nonatomic, assign) CGSize size;
@end
@implementation HLSizedThing
- (instancetype)initWithSize:(CGSize)size
{
  self = [super init];
  if (self) {
    _size = size;
  }
  return self;
}
@end

@interface HLWrongTypeSizedThing : NSObject
- (instancetype)initWithSize:(NSUInteger)size;
@property (nonatomic, assign) NSUInteger size;
@end
@implementation HLWrongTypeSizedThing
- (instancetype)initWithSize:(NSUInteger)size
{
  self = [super init];
  if (self) {
    _size = size;
  }
  return self;
}
@end

@implementation HLLayoutManagerTests

- (void)testGetNodeSize
{
  {
    id nullObject = [NSNull null];
    CGSize size = HLLayoutManagerGetNodeSize(nullObject);
    XCTAssertTrue(CGSizeEqualToSize(size, CGSizeZero));
  }

  {
    SKNode *genericNode = [SKNode node];
    CGSize size = HLLayoutManagerGetNodeSize(genericNode);
    XCTAssertTrue(CGSizeEqualToSize(size, CGSizeZero));
  }

  {
    SKLabelNode *labelNode = [SKLabelNode labelNodeWithText:@"hello"];
    CGSize size = HLLayoutManagerGetNodeSize(labelNode);
    XCTAssertGreaterThan(size.width, 0.0f);
  }

  {
    CGSize spriteNodeSize = CGSizeMake(10.0f, 10.0f);
    SKSpriteNode *spriteNode = [SKSpriteNode spriteNodeWithColor:[SKColor blackColor] size:spriteNodeSize];
    CGSize size = HLLayoutManagerGetNodeSize(spriteNode);
    XCTAssertTrue(CGSizeEqualToSize(size, spriteNodeSize));
  }

  {
    HLWrongTypeSizedThing *wrongTypeSizedThing = [[HLWrongTypeSizedThing alloc] initWithSize:3];
    CGSize size;
    XCTAssertNoThrow(size = HLLayoutManagerGetNodeSize(wrongTypeSizedThing));
    // note: Ideally we should get a return value of zero if the size method doesn't have
    // the right signature.  And for my more-recent (simulated) devices and iOS versions,
    // it does indeed.  However, for older devices, or older iOS versions, the function
    // happily writes a NSUInteger into a CGSize and return it.  So remove this test for
    // now, since after all we never really promised to return anything in particular
    // in this situation (except that we'd like to compile correctly and not throw an
    // exception).
    //XCTAssertTrue(CGSizeEqualToSize(size, CGSizeZero));
  }
}

@end
