//
//  HLMenuScene.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 5/1/14.
//  Copyright (c) 2014 Hilo. All rights reserved.
//

#import "HLMenuScene.h"

#import "HLLabelButtonNode.h"

static const CGFloat HLZPositionBackground = 0.0f;
static const CGFloat HLZPositionMenus = 1.0f;

@implementation HLMenuItem

- (id)initWithText:(NSString *)text
{
  self = [super init];
  if (self) {
    _text = [text copy];
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
  self = [super init];
  if (self) {
    _text = [aDecoder decodeObjectForKey:@"text"];
    _buttonPrototype = [aDecoder decodeObjectForKey:@"buttonPrototype"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [aCoder encodeObject:_text forKey:@"text"];
  [aCoder encodeObject:_buttonPrototype forKey:@"buttonPrototype"];
}

@end

@implementation HLMenu
{
  NSMutableArray *_items;
}

- (id)init
{
  self = [super init];
  if (self) {
    _items = [NSMutableArray array];
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
    _items = [aDecoder decodeObjectForKey:@"items"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject:_items forKey:@"items"];
}

- (void)addItem:(HLMenuItem *)item
{
  [_items addObject:item];
}

- (NSUInteger)itemCount
{
  return [_items count];
}

- (HLMenuItem *)itemAtIndex:(NSUInteger)index
{
  return (HLMenuItem *)[_items objectAtIndex:index];
}

@end

@implementation HLMenuScene
{
  BOOL _contentCreated;
  SKNode *_menusNode;
  HLMenu *_currentMenu;
}

- (id)initWithSize:(CGSize)size
{
  self = [super initWithSize:size];
  if (self) {
    _contentCreated = NO;
    _currentMenu = nil;
    _menu = [[HLMenu alloc] init];
    
    // note: Provide a default button layout.  Almost all callers will be providing
    // their own, but this makes it so that the class doesn't throw exceptions or
    // seem to do nothing when used without configuration.
    _itemSpacing = 60.0f;
    _buttonPrototype = [[HLLabelButtonNode alloc] initWithColor:[UIColor blackColor] size:CGSizeMake(240.0f, 40.0f)];
    _buttonPrototype.centerRect = CGRectMake(0.3333333f, 0.3333333f, 0.3333333f, 0.3333333f);
    _buttonPrototype.fontName = @"Helvetica";
    _buttonPrototype.fontSize = 24.0f;
    _buttonPrototype.fontColor = [UIColor whiteColor];
    _buttonPrototype.verticalAlignmentMode = HLLabelButtonNodeVerticalAlignFont;
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
    _contentCreated = [aDecoder decodeBoolForKey:@"contentCreated"];
    if (_contentCreated) {
      [self HL_createMenusNode];
    } else {
      _menusNode = nil;
    }
    _menu = [aDecoder decodeObjectForKey:@"menu"];
    _currentMenu = [aDecoder decodeObjectForKey:@"currentMenu"];
    self.backgroundImageName = [aDecoder decodeObjectForKey:@"backgroundImageName"];
    _itemSpacing = [aDecoder decodeFloatForKey:@"itemSpacing"];
    _buttonPrototype = [aDecoder decodeObjectForKey:@"buttonPrototype"];
    [self HL_showMenu:_menu];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  // Temporarily remove nodes that don't need to be encoded.
  SKSpriteNode *backgroundImageNode = (SKSpriteNode *)[self childNodeWithName:@"backgroundImage"];
  if (backgroundImageNode) {
    [backgroundImageNode removeFromParent];
  }
  if (_menusNode) {
    [_menusNode removeFromParent];
  }

  // Encode.
  [super encodeWithCoder:aCoder];
  // note: It would be a little strange for this object to be encoded before its
  // content had been created, but it seems best to treat it as a possible state.
  [aCoder encodeBool:_contentCreated forKey:@"contentCreated"];
  // note: The node tree has already been encoded by the call to super.  This is
  // a pointer to an already-encoded object.
  [aCoder encodeObject:_menu forKey:@"menu"];
  [aCoder encodeObject:_currentMenu forKey:@"currentMenu"];
  [aCoder encodeObject:_backgroundImageName forKey:@"backgroundImageName"];
  [aCoder encodeFloat:_itemSpacing forKey:@"itemSpacing"];
  [aCoder encodeObject:_buttonPrototype forKey:@"buttonPrototype"];

  // Replace any removed nodes.
  if (backgroundImageNode) {
    [self addChild:backgroundImageNode];
  }
  if (_menusNode) {
    [self addChild:_menusNode];
  }
}

- (void)didMoveToView:(SKView *)view
{
  if (!_contentCreated) {
    [self HL_createSceneContents];
    _contentCreated = YES;
  }
}

- (void)HL_createSceneContents
{
  self.anchorPoint = CGPointMake(0.5f, 0.5f);
  [self HL_createMenusNode];
  [self HL_showMenu:_menu];
}

- (void)HL_createMenusNode
{
  _menusNode = [SKNode node];
  _menusNode.zPosition = HLZPositionMenus;
  [self addChild:_menusNode];
}

- (void)didChangeSize:(CGSize)oldSize
{
  SKSpriteNode *backgroundImageNode = (SKSpriteNode *)[self childNodeWithName:@"backgroundImage"];
  if (backgroundImageNode) {
    backgroundImageNode.size = self.size;
  }
}

- (void)setBackgroundImageName:(NSString *)backgroundImageName
{
  if (backgroundImageName == _backgroundImageName) {
    return;
  }
  _backgroundImageName = backgroundImageName;

  SKSpriteNode *backgroundImageNode = (SKSpriteNode *)[self childNodeWithName:@"backgroundImage"];

  if (backgroundImageNode) {
    [backgroundImageNode removeFromParent];
  }
  if (backgroundImageName) {
    SKTexture *texture = [SKTexture textureWithImageNamed:backgroundImageName];
    backgroundImageNode = [SKSpriteNode spriteNodeWithTexture:texture size:self.size];
    backgroundImageNode.name = @"backgroundImage";
    backgroundImageNode.zPosition = HLZPositionBackground;
    [self addChild:backgroundImageNode];
  }
}

- (void)HL_showMenu:(HLMenu *)menu
{
  if (_currentMenu) {
    [_menusNode removeAllChildren];
  }

  for (NSUInteger i = 0; i < [menu itemCount]; ++i) {
    HLMenuItem *item = [menu itemAtIndex:i];
    HLLabelButtonNode *buttonPrototype = (item.buttonPrototype ? item.buttonPrototype : self.buttonPrototype);
    if (!buttonPrototype) {
      [NSException raise:@"HLMenuSceneMissingButtonPrototype" format:@"Missing button prototype for menu item."];
    }
    HLLabelButtonNode *buttonNode = [buttonPrototype copy];
    buttonNode.text = item.text;
    // note: SKSpriteNode in iOS 7.1 SDK does not support using centerRect with changes to the size
    // property -- only the scale properties.  HLLabelButtonNode works around that, for now.
    buttonNode.position = CGPointMake(0.0f, -self.itemSpacing * i);
    [_menusNode addChild:buttonNode];
  }

  _currentMenu = menu;
}

@end
