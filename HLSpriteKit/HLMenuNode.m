
//
//  HLMenuNode.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 5/1/14.
//  Copyright (c) 2014 Hilo. All rights reserved.
//

#import "HLMenuNode.h"

#import "HLLabelButtonNode.h"

@implementation HLMenuNode
{
  SKNode *_buttonsNode;
  HLMenu *_currentMenu;
}

- (id)init
{
  self = [super init];
  if (self) {
    // note: Provide a default item appearance and behavior.  Almost all callers will be
    // providing their own, but this makes it so that the class doesn't throw exceptions or
    // seem to do nothing when used without configuration.
    _itemSpacing = 60.0f;
    _itemButtonPrototype = [[HLLabelButtonNode alloc] initWithColor:[UIColor blackColor] size:CGSizeMake(240.0f, 40.0f)];
    _itemButtonPrototype.centerRect = CGRectMake(0.3333333f, 0.3333333f, 0.3333333f, 0.3333333f);
    _itemButtonPrototype.fontName = @"Helvetica";
    _itemButtonPrototype.fontSize = 24.0f;
    _itemButtonPrototype.fontColor = [UIColor whiteColor];
    _itemButtonPrototype.verticalAlignmentMode = HLLabelNodeVerticalAlignFont;
    _itemAnimation = HLMenuNodeAnimationSlideLeft;
    _itemAnimationDuration = 0.25;
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
    _menu = [aDecoder decodeObjectForKey:@"menu"];
    _currentMenu = [aDecoder decodeObjectForKey:@"currentMenu"];
    _itemSpacing = [aDecoder decodeFloatForKey:@"itemSpacing"];
    _itemButtonPrototype = [aDecoder decodeObjectForKey:@"itemButtonPrototype"];
    _itemAnimation = (HLMenuNodeAnimation)[aDecoder decodeIntForKey:@"itemAnimation"];
    _itemAnimationDuration = [aDecoder decodeDoubleForKey:@"itemAnimationDuration"];
    _itemSoundFile = [aDecoder decodeObjectForKey:@"itemSoundFile"];
    if (_currentMenu) {
      [self HL_showCurrentMenuAnimation:HLMenuNodeAnimationNone];
    }
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  // Don't encode buttons node; it can be regenerated from _menu.
  if (_buttonsNode) {
    [_buttonsNode removeFromParent];
  }

  // Encode.
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject:_menu forKey:@"menu"];
  [aCoder encodeObject:_currentMenu forKey:@"currentMenu"];
  [aCoder encodeDouble:_itemSpacing forKey:@"itemSpacing"];
  [aCoder encodeObject:_itemButtonPrototype forKey:@"itemButtonPrototype"];
  [aCoder encodeInt:(int)_itemAnimation forKey:@"itemAnimation"];
  [aCoder encodeDouble:_itemAnimationDuration forKey:@"itemAnimationDuration"];
  [aCoder encodeObject:_itemSoundFile forKey:@"itemSoundFile"];

  // Replace any removed nodes.
  if (_buttonsNode) {
    [self addChild:_buttonsNode];
  }
}

- (void)setMenu:(HLMenu *)menu animation:(HLMenuNodeAnimation)animation
{
  _menu = menu;
  _currentMenu = menu;
  if (_currentMenu) {
    [self HL_showCurrentMenuAnimation:animation];
  }
}

- (void)navigateToTopMenuAnimation:(HLMenuNodeAnimation)animation
{
  _currentMenu = _menu;
  [self HL_showCurrentMenuAnimation:animation];
}

- (void)navigateToSubmenuWithPathComponents:(NSArray *)pathComponents animation:(HLMenuNodeAnimation)animation
{
  HLMenuItem *item = [_menu itemForPathComponents:pathComponents];
  if (![item isKindOfClass:[HLMenu class]]) {
    return;
  }
  HLMenu *menu = (HLMenu *)item;
  _currentMenu = menu;
  [self HL_showCurrentMenuAnimation:animation];
}

#pragma mark -
#pragma mark HLGestureTarget

- (BOOL)addToGesture:(UIGestureRecognizer *)gestureRecognizer firstTouch:(UITouch *)touch isInside:(BOOL *)isInside
{
  CGPoint location = [touch locationInNode:self];

  *isInside = NO;
  for (HLLabelButtonNode *buttonNode in _buttonsNode.children) {
    if ([buttonNode containsPoint:location]) {
      *isInside = YES;
      if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
        [gestureRecognizer addTarget:self action:@selector(handleTap:)];
        return YES;
      }
      break;
    }
  }
  return NO;
}

- (BOOL)addsToTapGestureRecognizer
{
  return YES;
}

- (BOOL)addsToPanGestureRecognizer
{
  return NO;
}

- (void)handleTap:(UIGestureRecognizer *)gestureRecognizer
{
  // note: Clearly, could retain state from addToGesture if it improved
  // performance significantly.
  CGPoint viewLocation = [gestureRecognizer locationInView:self.scene.view];
  CGPoint sceneLocation = [self.scene convertPointFromView:viewLocation];
  CGPoint menuLocation = [self convertPoint:sceneLocation fromNode:self.scene];

  NSUInteger i = 0;
  for (HLLabelButtonNode *buttonNode in _buttonsNode.children) {
    if ([buttonNode containsPoint:menuLocation]) {
      [self HL_tappedItem:i];
      return;
    }
    ++i;
  }
}

#pragma mark -
#pragma mark Private

- (void)HL_showCurrentMenuAnimation:(HLMenuNodeAnimation)animation
{
  SKNode *oldButtonsNode = _buttonsNode;
  _buttonsNode = [SKNode node];
  [self addChild:_buttonsNode];

  for (NSUInteger i = 0; i < [_currentMenu itemCount]; ++i) {
    HLMenuItem *item = [_currentMenu itemAtIndex:i];
    HLLabelButtonNode *buttonPrototype = (item.buttonPrototype ? item.buttonPrototype : self.itemButtonPrototype);
    if (!buttonPrototype) {
      [NSException raise:@"HLMenuNodeMissingButtonPrototype" format:@"Missing button prototype for menu item."];
    }
    HLLabelButtonNode *buttonNode = [buttonPrototype copy];
    buttonNode.text = item.text;
    buttonNode.position = CGPointMake(0.0f, -self.itemSpacing * i);
    [_buttonsNode addChild:buttonNode];
  }

  if (animation == HLMenuNodeAnimationNone) {

    if (oldButtonsNode) {
      [oldButtonsNode removeFromParent];
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
      case HLMenuNodeAnimationSlideLeft:
        delta = CGPointMake(-1.0f * (self.scene.size.width + buttonWidthMax) / 2.0f, 0.0f);
        break;
      case HLMenuNodeAnimationSlideRight:
        delta = CGPointMake((self.scene.size.width + buttonWidthMax) / 2.0f, 0.0f);
        break;
      default:
        [NSException raise:@"HLMenuNodeUnhandledAnimation" format:@"Unhandled animation %d.", animation];
    }
  
    _buttonsNode.position = CGPointMake(-delta.x, -delta.y);
    SKAction *animationAction = [SKAction moveByX:delta.x y:delta.y duration:_itemAnimationDuration];
    [_buttonsNode runAction:animationAction];

    if (oldButtonsNode) {
      [oldButtonsNode runAction:[SKAction sequence:@[ animationAction, [SKAction removeFromParent] ]]];
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

  id<HLMenuNodeDelegate> delegate = self.delegate;
  if (delegate) {
    if ([delegate respondsToSelector:@selector(menuNode:shouldTapMenuItem:itemIndex:)]
        && ![delegate menuNode:self shouldTapMenuItem:item itemIndex:itemIndex]) {
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
    if (!_currentMenu.parent) {
      [NSException raise:@"HLMenuNodeBadBackButton" format:@"Back button has no destination."];
    }
    _currentMenu = _currentMenu.parent;
    [self HL_showCurrentMenuAnimation:[self HL_oppositeAnimation:_itemAnimation]];
  }

  if (delegate) {
    if ([delegate respondsToSelector:@selector(menuNode:didTapMenuItem:itemIndex:)]) {
      [delegate menuNode:self didTapMenuItem:item itemIndex:itemIndex];
    }
  }
}

- (HLMenuNodeAnimation)HL_oppositeAnimation:(HLMenuNodeAnimation)animation
{
  switch (animation) {
    case HLMenuNodeAnimationNone:
      return HLMenuNodeAnimationNone;
    case HLMenuNodeAnimationSlideLeft:
      return HLMenuNodeAnimationSlideRight;
    case HLMenuNodeAnimationSlideRight:
      return HLMenuNodeAnimationSlideLeft;
    default:
      [NSException raise:@"HLMenuNodeUnhandledAnimation" format:@"Unhandled animation %d.", animation];
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

- (void)removeAllItems
{
  [_items removeAllObjects];
}

@end

@implementation HLMenuBackItem

@end
