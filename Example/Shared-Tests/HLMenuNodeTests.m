//
//  HLMenuNodeTests.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 8/3/15.
//  Copyright (c) 2015 Karl Voskuil. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "HLMenuNode.h"
#import "HLLabelButtonNode.h"

@interface HLMenuNodeTests : XCTestCase

@end

@interface HLMenuNodeTestsGoodButtonNode : SKNode
@property (nonatomic, readonly) CGSize size;
@property (nonatomic, assign) CGPoint anchorPoint;
@property (nonatomic, copy) NSString *text;
@end
@implementation HLMenuNodeTestsGoodButtonNode
@end

@interface HLMenuNodeTestsBadButtonNode : SKNode
@end
@implementation HLMenuNodeTestsBadButtonNode
@end

@implementation HLMenuNodeTests

- (void)testButtonPrototypeTyping
{
  HLMenuNode *menuNode = [[HLMenuNode alloc] init];

  HLMenuNodeTestsGoodButtonNode *goodButtonNode = [[HLMenuNodeTestsGoodButtonNode alloc] init];
  XCTAssertNoThrow(menuNode.itemButtonPrototype = goodButtonNode);

  HLMenuNodeTestsBadButtonNode *badButtonNode = [[HLMenuNodeTestsBadButtonNode alloc] init];
  XCTAssertThrows(menuNode.itemButtonPrototype = badButtonNode);

  // HLLabelButtonNode is intended to always be valid for use with HLMenuNode.
  HLLabelButtonNode *labelButtonNode = [[HLLabelButtonNode alloc] init];
  XCTAssertNoThrow(menuNode.itemButtonPrototype = labelButtonNode);

  // A simple SKSpriteNode will work, under current specifications.
  SKSpriteNode *spriteNode = [SKSpriteNode spriteNodeWithColor:[SKColor redColor] size:CGSizeMake(200.0f, 50.0f)];
  XCTAssertNoThrow(menuNode.itemButtonPrototype = spriteNode);

  // A simple SKLabelNode won't do, under current specifications.
  SKLabelNode *labelNode = [SKLabelNode labelNodeWithFontNamed:@"Courier"];
  XCTAssertThrows(menuNode.itemButtonPrototype = labelNode);
}

@end
