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

@implementation HLMenuScene
{
  BOOL _contentCreated;
  SKNode *_menusNode;
  HLMenu *_currentMenu;
  
  UITapGestureRecognizer *_tapRecognizer;
}

- (id)initWithSize:(CGSize)size
{
  self = [super initWithSize:size];
  if (self) {
    _contentCreated = NO;
    _menu = [[HLMenu alloc] init];
    _currentMenu = _menu;
    
    // note: Provide a default item appearance and behavior.  Almost all callers will be
    // providing their own, but this makes it so that the class doesn't throw exceptions or
    // seem to do nothing when used without configuration.
    _itemSpacing = 60.0f;
    _itemButtonPrototype = [[HLLabelButtonNode alloc] initWithColor:[UIColor blackColor] size:CGSizeMake(240.0f, 40.0f)];
    _itemButtonPrototype.centerRect = CGRectMake(0.3333333f, 0.3333333f, 0.3333333f, 0.3333333f);
    _itemButtonPrototype.fontName = @"Helvetica";
    _itemButtonPrototype.fontSize = 24.0f;
    _itemButtonPrototype.fontColor = [UIColor whiteColor];
    _itemButtonPrototype.verticalAlignmentMode = HLLabelButtonNodeVerticalAlignFont;
    _itemAnimation = HLMenuSceneAnimationSlideLeft;
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
    _contentCreated = [aDecoder decodeBoolForKey:@"contentCreated"];
    _menu = [aDecoder decodeObjectForKey:@"menu"];
    _currentMenu = [aDecoder decodeObjectForKey:@"currentMenu"];
    self.backgroundImageName = [aDecoder decodeObjectForKey:@"backgroundImageName"];
    _itemSpacing = [aDecoder decodeFloatForKey:@"itemSpacing"];
    _itemButtonPrototype = [aDecoder decodeObjectForKey:@"itemButtonPrototype"];
    _itemAnimation = (HLMenuSceneAnimation)[aDecoder decodeIntForKey:@"itemAnimation"];
    _itemSoundFile = [aDecoder decodeObjectForKey:@"itemSoundFile"];
    if (_contentCreated) {
      [self HL_showCurrentMenuAnimation:HLMenuSceneAnimationNone];
    }
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
  [aCoder encodeDouble:_itemSpacing forKey:@"itemSpacing"];
  [aCoder encodeObject:_itemButtonPrototype forKey:@"itemButtonPrototype"];
  [aCoder encodeInt:(int)_itemAnimation forKey:@"itemAnimation"];
  [aCoder encodeObject:_itemSoundFile forKey:@"itemSoundFile"];

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
  
  _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
  _tapRecognizer.delegate = self;
  [view addGestureRecognizer:_tapRecognizer];
}

- (void)willMoveFromView:(SKView *)view
{
  [view removeGestureRecognizer:_tapRecognizer];
}

- (void)HL_createSceneContents
{
  self.anchorPoint = CGPointMake(0.5f, 0.5f);
  [self HL_showCurrentMenuAnimation:_itemAnimation];
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

- (void)navigateToMenu:(HLMenu *)menu animation:(HLMenuSceneAnimation)animation
{
  _currentMenu = menu;
  if (_contentCreated) {
    [self HL_showCurrentMenuAnimation:animation];
  }
}

#pragma mark -
#pragma mark UIGestureRecognizerDelegate

- (void)handleTap:(UIGestureRecognizer *)gestureRecognizer
{
  CGPoint viewLocation = [gestureRecognizer locationInView:self.view];
  CGPoint sceneLocation = [self convertPointFromView:viewLocation];

  NSUInteger i = 0;
  for (HLLabelButtonNode *buttonNode in _menusNode.children) {
    if ([buttonNode containsPoint:sceneLocation]) {
      [self HL_tappedItem:i];
      return;
    }
    ++i;
  }
}

#pragma mark -
#pragma mark Private

- (void)HL_showCurrentMenuAnimation:(HLMenuSceneAnimation)animation
{
  if (!_currentMenu) {
    [NSException raise:@"HLMenuSceneNoCurrentMenu" format:@"Current menu must be set before showing."];
  }

  const NSTimeInterval HLMenuSceneSlideDuration = 0.25f;

  SKNode *oldMenusNode = _menusNode;
  _menusNode = [SKNode node];
  _menusNode.zPosition = HLZPositionMenus;
  [self addChild:_menusNode];

  for (NSUInteger i = 0; i < [_currentMenu itemCount]; ++i) {
    HLMenuItem *item = [_currentMenu itemAtIndex:i];
    HLLabelButtonNode *buttonPrototype = (item.buttonPrototype ? item.buttonPrototype : self.itemButtonPrototype);
    if (!buttonPrototype) {
      [NSException raise:@"HLMenuSceneMissingButtonPrototype" format:@"Missing button prototype for menu item."];
    }
    HLLabelButtonNode *buttonNode = [buttonPrototype copy];
    buttonNode.text = item.text;
    buttonNode.position = CGPointMake(0.0f, -self.itemSpacing * i);
    [_menusNode addChild:buttonNode];
  }

  if (animation == HLMenuSceneAnimationNone) {

    if (oldMenusNode) {
      [oldMenusNode removeFromParent];
    }
  
  } else {

    CGFloat buttonWidthMax = self.itemButtonPrototype.size.width;
    for (NSUInteger i = 0; i < [_currentMenu itemCount]; ++i) {
      HLMenuItem *item = [_currentMenu itemAtIndex:i];
      if (item.buttonPrototype && item.buttonPrototype.size.width > buttonWidthMax) {
        buttonWidthMax = item.buttonPrototype.size.width;
      }
    }
  
    CGPoint delta;
    switch (animation) {
      case HLMenuSceneAnimationSlideLeft:
        delta = CGPointMake(-1.0f * (self.scene.size.width + buttonWidthMax) / 2.0f, 0.0f);
        break;
      case HLMenuSceneAnimationSlideRight:
        delta = CGPointMake((self.scene.size.width + buttonWidthMax) / 2.0f, 0.0f);
        break;
      default:
        [NSException raise:@"HLMenuSceneUnhandledAnimation" format:@"Unhandled animation %d.", animation];
    }
  
    _menusNode.position = CGPointMake(-delta.x, -delta.y);
    SKAction *animationAction = [SKAction moveByX:delta.x y:delta.y duration:HLMenuSceneSlideDuration];
    [_menusNode runAction:animationAction];

    if (oldMenusNode) {
      [oldMenusNode runAction:[SKAction sequence:@[ animationAction, [SKAction removeFromParent] ]]];
    }
  }

  // noob: Okay to preload sounds in background thread?  What if the main thread
  // also tries to load the sound at the same time?
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    [self HL_loadCurrentMenuSounds];
  });
}

- (void)HL_loadCurrentMenuSounds
{
  NSDate *startDate = [NSDate date];

  // noob: Okay to keep preloading the main sound over and over again?
  // Or is that dumb?
  NSLog(@"loading sound %@", self.itemSoundFile);
  [SKAction playSoundFileNamed:self.itemSoundFile waitForCompletion:NO];
  
  for (NSUInteger i = 0; i < [_currentMenu itemCount]; ++i) {
    HLMenuItem *item = [_currentMenu itemAtIndex:i];
    if (item.soundFile) {
      NSLog(@"loading sound %@", item.soundFile);
      [SKAction playSoundFileNamed:item.soundFile waitForCompletion:NO];
    }
  }

  NSLog(@"loaded sounds for current menu in %.2f seconds", [[NSDate date] timeIntervalSinceDate:startDate]);
}

- (void)HL_tappedItem:(NSUInteger)itemIndex
{
  HLMenuItem *item = [_currentMenu itemAtIndex:itemIndex];

  id<HLMenuSceneDelegate> delegate = self.delegate;
  if (delegate) {
    if ([delegate respondsToSelector:@selector(menuScene:shouldTapMenuItem:)]
        && ![delegate menuScene:self shouldTapMenuItem:item]) {
      return;
    }
  }

  NSString *soundFile = (item.soundFile ? item.soundFile : _itemSoundFile);
  if (soundFile) {
    [self runAction:[SKAction playSoundFileNamed:soundFile waitForCompletion:NO]];
  }

  if ([item isKindOfClass:[HLMenu class]]) {
    _currentMenu = (HLMenu *)item;
    [self HL_showCurrentMenuAnimation:_itemAnimation];
  } else if ([item isKindOfClass:[HLMenuBackItem class]]) {
    _currentMenu = _currentMenu.parent;
    [self HL_showCurrentMenuAnimation:[self HL_oppositeAnimation:_itemAnimation]];
  }

  if (delegate) {
    if ([delegate respondsToSelector:@selector(menuScene:didTapMenuItem:)]) {
      [delegate menuScene:self didTapMenuItem:item];
    }
  }
}

- (HLMenuSceneAnimation)HL_oppositeAnimation:(HLMenuSceneAnimation)animation
{
  switch (animation) {
    case HLMenuSceneAnimationNone:
      return HLMenuSceneAnimationNone;
    case HLMenuSceneAnimationSlideLeft:
      return HLMenuSceneAnimationSlideRight;
    case HLMenuSceneAnimationSlideRight:
      return HLMenuSceneAnimationSlideLeft;
    default:
      [NSException raise:@"HLMenuSceneUnhandledAnimation" format:@"Unhandled animation %d.", animation];
  }
}

@end

@implementation HLMenuItem

+ (HLMenuItem *)menuItemWithText:(NSString *)text
{
  return [[[self class] alloc] initWithText:text];
}

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
    _parent = [aDecoder decodeObjectForKey:@"parent"];
    _text = [aDecoder decodeObjectForKey:@"text"];
    _buttonPrototype = [aDecoder decodeObjectForKey:@"buttonPrototype"];
    _soundFile = [aDecoder decodeObjectForKey:@"soundFile"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [aCoder encodeObject:_parent forKey:@"parent"];
  [aCoder encodeObject:_text forKey:@"text"];
  [aCoder encodeObject:_buttonPrototype forKey:@"buttonPrototype"];
  [aCoder encodeObject:_soundFile forKey:@"soundFile"];
}

- (NSString *)path
{
  HLMenu *parent = _parent;
  // note: The top-level menu, by convention, has no text, and so is not
  // included in the path.
  if (!parent || !parent.parent) {
    return self.text;
  }
  return [NSString stringWithFormat:@"%@/%@", [parent path], self.text];
}

@end

@implementation HLMenu
{
  NSMutableArray *_items;
}

+ (HLMenu *)menuWithText:(NSString *)text items:(NSArray *)items
{
  return [[[self class] alloc] initWithText:text items:items];
}

- (id)init
{
  self = [super initWithText:@""];
  if (self) {
    _items = [NSMutableArray array];
  }
  return self;
}

- (id)initWithText:(NSString *)text
{
  self = [super initWithText:text];
  if (self) {
    _items = [NSMutableArray array];
  }
  return self;
}

- (id)initWithText:(NSString *)text items:(NSArray *)items
{
  self = [super initWithText:text];
  if (self) {
    _items = [NSMutableArray array];
    for (HLMenuItem *item in items) {
      [self addItem:item];
    }
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
  item.parent = self;
}

- (NSUInteger)itemCount
{
  return [_items count];
}

- (HLMenuItem *)itemAtIndex:(NSUInteger)index
{
  return (HLMenuItem *)[_items objectAtIndex:index];
}

- (HLMenuItem *)itemForPathComponents:(NSArray *)pathComponents
{
  HLMenuItem *matchingItem = self;
  NSUInteger pathComponentCount = [pathComponents count];
  for (NSUInteger pc = 0; pc < pathComponentCount; ++pc) {
    NSString *pathComponent = [pathComponents objectAtIndex:pc];
    BOOL foundMatchingItem = NO;
    for (HLMenuItem *item in ((HLMenu *)matchingItem)->_items) {
      if ([item.text isEqualToString:pathComponent]) {
        foundMatchingItem = YES;
        matchingItem = item;
        break;
      }
    }
    if (!foundMatchingItem) {
      return nil;
    }
    if ((pc + 1) < pathComponentCount && ![matchingItem isKindOfClass:[HLMenu class]]) {
      return nil;
    }
  }
  return matchingItem;
}

@end

@implementation HLMenuBackItem

@end
