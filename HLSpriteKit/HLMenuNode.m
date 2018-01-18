//
//  HLMenuNode.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 5/1/14.
//  Copyright (c) 2014 Hilo Games. All rights reserved.
//

#import "HLMenuNode.h"

#import "HLLabelButtonNode.h"
#import "HLLayoutManager.h"
#import "HLLog.h"
#import "SKNode+HLGestureTarget.h"

static const NSTimeInterval HLMenuNodeLongSelectedDuration = 0.5;

enum {
  HLMenuNodeZPositionLayerButtons = 0,
  HLMenuNodeZPositionLayerCount
};

static void
HLMenuNodeValidateButtonPrototype(SKNode *buttonPrototype, NSString *label)
{
  if (![buttonPrototype respondsToSelector:@selector(size)]) {
    [NSException raise:@"HLMenuNodeInvalidButtonPrototype" format:@"Button prototype for \"%@\" must respond to selector \"size\".", label];
  }
  if (![buttonPrototype respondsToSelector:@selector(setAnchorPoint:)]) {
    [NSException raise:@"HLMenuNodeInvalidButtonPrototype" format:@"Button prototype for \"%@\" must respond to selector \"setAnchorPoint:\".", label];
  }
  if ([buttonPrototype respondsToSelector:@selector(hlGestureTarget)]) {
    if ([buttonPrototype hlGestureTarget]) {
      // This might be okay, but it seems like it will cause confusion if the button is
      // trying to handle gestures separately from the menu node.  Log error and continue.
      HLLog(HLLogWarning, @"HLMenuNode: Button prototype for \"%@\" is not expected to have a gesture target; removing it.", label);
      [buttonPrototype hlSetGestureTarget:nil];
    }
  }
}

@implementation HLMenuNode
{
  SKNode *_buttonsNode;
  HLMenu *_currentMenu;

#if TARGET_OS_IPHONE
  NSTimeInterval _touchesBeganTimestamp;
#else
  NSTimeInterval _mouseDownTimestamp;
#endif
}

- (instancetype)init
{
  self = [super init];
  if (self) {
    // note: Provide a default item appearance and behavior.  Almost all callers will be
    // providing their own, but this makes it so that the class doesn't throw exceptions
    // or seem to do nothing when used without configuration.
    _itemSeparatorSize = 4.0f;
    _anchorPoint = CGPointMake(0.5f, 0.5f);
    HLLabelButtonNode *itemButtonPrototype = [[HLLabelButtonNode alloc] initWithColor:[SKColor blackColor] size:CGSizeMake(180.0f, 0.0f)];
    itemButtonPrototype.automaticHeight = YES;
    itemButtonPrototype.fontName = @"Helvetica";
    itemButtonPrototype.fontSize = 24.0f;
    itemButtonPrototype.fontColor = [SKColor whiteColor];
    itemButtonPrototype.heightMode = HLLabelHeightModeFont;
    _itemButtonPrototype = itemButtonPrototype;
    _menuItemButtonPrototype = nil;
    _backItemButtonPrototype = nil;
    _itemAnimation = HLMenuNodeAnimationSlideLeft;
    _itemAnimationDuration = 0.25;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
    _delegate = [aDecoder decodeObjectForKey:@"delegate"];
    _topMenu = [aDecoder decodeObjectForKey:@"topMenu"];
    _currentMenu = [aDecoder decodeObjectForKey:@"currentMenu"];
    _itemSeparatorSize = (CGFloat)[aDecoder decodeDoubleForKey:@"itemSeparatorSize"];
#if TARGET_OS_IPHONE
    _size = [aDecoder decodeCGSizeForKey:@"size"];
    _anchorPoint = [aDecoder decodeCGPointForKey:@"anchorPoint"];
#else
    _size = [aDecoder decodeSizeForKey:@"size"];
    _anchorPoint = [aDecoder decodePointForKey:@"anchorPoint"];
#endif
    _itemButtonPrototype = [aDecoder decodeObjectForKey:@"itemButtonPrototype"];
    _menuItemButtonPrototype = [aDecoder decodeObjectForKey:@"menuItemButtonPrototype"];
    _backItemButtonPrototype = [aDecoder decodeObjectForKey:@"backItemButtonPrototype"];
    _itemAnimation = (HLMenuNodeAnimation)[aDecoder decodeIntegerForKey:@"itemAnimation"];
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
  // Don't encode buttons node; it can be regenerated from _topMenu.
  if (_buttonsNode) {
    [_buttonsNode removeFromParent];
  }

  // Encode.
  [super encodeWithCoder:aCoder];
  [aCoder encodeConditionalObject:_delegate forKey:@"delegate"];
  [aCoder encodeObject:_topMenu forKey:@"topMenu"];
  [aCoder encodeObject:_currentMenu forKey:@"currentMenu"];
  [aCoder encodeDouble:_itemSeparatorSize forKey:@"itemSeparatorSize"];
#if TARGET_OS_IPHONE
  [aCoder encodeCGSize:_size forKey:@"size"];
  [aCoder encodeCGPoint:_anchorPoint forKey:@"anchorPoint"];
#else
  [aCoder encodeSize:_size forKey:@"size"];
  [aCoder encodePoint:_anchorPoint forKey:@"anchorPoint"];
#endif
  [aCoder encodeObject:_itemButtonPrototype forKey:@"itemButtonPrototype"];
  [aCoder encodeObject:_menuItemButtonPrototype forKey:@"menuItemButtonPrototype"];
  [aCoder encodeObject:_backItemButtonPrototype forKey:@"backItemButtonPrototype"];
  [aCoder encodeInteger:_itemAnimation forKey:@"itemAnimation"];
  [aCoder encodeDouble:_itemAnimationDuration forKey:@"itemAnimationDuration"];
  [aCoder encodeObject:_itemSoundFile forKey:@"itemSoundFile"];

  // Replace any removed nodes.
  if (_buttonsNode) {
    [self addChild:_buttonsNode];
  }
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  [NSException raise:@"HLCopyingNotImplemented" format:@"Copying not implemented for this descendant of an NSCopying parent."];
  return nil;
}

- (void)setZPositionScale:(CGFloat)zPositionScale
{
  [super setZPositionScale:zPositionScale];
  [self HL_layoutZ];
}

- (HLMenu *)displayedMenu
{
  return _currentMenu;
}

- (void)setTopMenu:(HLMenu *)topMenu animation:(HLMenuNodeAnimation)animation
{
  _topMenu = topMenu;
  _currentMenu = topMenu;
  if (_currentMenu) {
    [self HL_showCurrentMenuAnimation:animation];
  }
}

- (void)redisplayMenuAnimation:(HLMenuNodeAnimation)animation
{
  if (!_currentMenu) {
    return;
  }
  [self HL_showCurrentMenuAnimation:animation];
}

- (void)setItemButtonPrototype:(SKNode *)itemButtonPrototype
{
  HLMenuNodeValidateButtonPrototype(itemButtonPrototype, @"itemButtonPrototype");
  _itemButtonPrototype = itemButtonPrototype;
}

- (void)setMenuItemButtonPrototype:(SKNode *)menuItemButtonPrototype
{
  HLMenuNodeValidateButtonPrototype(menuItemButtonPrototype, @"menuItemButtonPrototype");
  _menuItemButtonPrototype = menuItemButtonPrototype;
}

- (void)setBackItemButtonPrototype:(SKNode *)backItemButtonPrototype
{
  HLMenuNodeValidateButtonPrototype(backItemButtonPrototype, @"menuItemButtonPrototype");
  _backItemButtonPrototype = backItemButtonPrototype;
}

- (void)navigateToTopMenuAnimation:(HLMenuNodeAnimation)animation
{
  _currentMenu = _topMenu;
  [self HL_showCurrentMenuAnimation:animation];
}

- (void)navigateToSubmenuWithPath:(NSArray *)path animation:(HLMenuNodeAnimation)animation
{
  HLMenuItem *item = [_topMenu itemForPath:path];
  if (![item isKindOfClass:[HLMenu class]]) {
    return;
  }
  HLMenu *menu = (HLMenu *)item;
  _currentMenu = menu;
  [self HL_showCurrentMenuAnimation:animation];
}

#pragma mark -
#pragma mark HLGestureTarget

- (NSArray *)addsToGestureRecognizers
{
#if TARGET_OS_IPHONE
  return @[ [[UITapGestureRecognizer alloc] init],
            [[UILongPressGestureRecognizer alloc] init] ];
#else
  return @[ [[NSClickGestureRecognizer alloc] init],
            [[NSPressGestureRecognizer alloc] init] ];
#endif
}

- (BOOL)addToGesture:(HLGestureRecognizer *)gestureRecognizer firstLocation:(CGPoint)sceneLocation isInside:(BOOL *)isInside
{
  CGPoint location = [self convertPoint:sceneLocation fromNode:self.scene];

  *isInside = NO;
  for (SKNode *buttonNode in _buttonsNode.children) {
    if ([buttonNode containsPoint:location]) {
      *isInside = YES;
#if TARGET_OS_IPHONE
      if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
        // note: Require only one tap and one touch, same as our gesture recognizer
        // returned from addsToGestureRecognizers?  I think it's okay to be non-strict.
        [gestureRecognizer addTarget:self action:@selector(handleTap:)];
        return YES;
      }
      if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
        [gestureRecognizer addTarget:self action:@selector(handleLongPress:)];
        return YES;
      }
#else
      if ([gestureRecognizer isKindOfClass:[NSClickGestureRecognizer class]]) {
        [gestureRecognizer addTarget:self action:@selector(handleClick:)];
        return YES;
      }
      if ([gestureRecognizer isKindOfClass:[NSPressGestureRecognizer class]]) {
        [gestureRecognizer addTarget:self action:@selector(handleLongPress:)];
        return YES;
      }
#endif
      break;
    }
  }
  return NO;
}

#if TARGET_OS_IPHONE
- (void)handleTap:(HLGestureRecognizer *)gestureRecognizer
#else
- (void)handleClick:(HLGestureRecognizer *)gestureRecognizer
#endif
{
  CGPoint viewLocation = [gestureRecognizer locationInView:self.scene.view];
  CGPoint sceneLocation = [self.scene convertPointFromView:viewLocation];
  CGPoint menuLocation = [self convertPoint:sceneLocation fromNode:self.scene];

  // note: This search was just done in addToGesture; if it made a difference,
  // we could retain state from there.
  NSUInteger i = 0;
  for (SKNode *buttonNode in _buttonsNode.children) {
    if ([buttonNode containsPoint:menuLocation]) {
      [self HL_selectedItem:i];
      return;
    }
    ++i;
  }
}

- (void)handleLongPress:(HLGestureRecognizer *)gestureRecognizer
{
#if TARGET_OS_IPHONE
  if (gestureRecognizer.state != UIGestureRecognizerStateBegan) {
    return;
  }
#else
  if (gestureRecognizer.state != NSGestureRecognizerStateBegan) {
    return;
  }
#endif

  CGPoint viewLocation = [gestureRecognizer locationInView:self.scene.view];
  CGPoint sceneLocation = [self.scene convertPointFromView:viewLocation];
  CGPoint menuLocation = [self convertPoint:sceneLocation fromNode:self.scene];

  NSUInteger i = 0;
  for (SKNode *buttonNode in _buttonsNode.children) {
    if ([buttonNode containsPoint:menuLocation]) {
      [self HL_longSelectedItem:i];
      return;
    }
    ++i;
  }
}

#if TARGET_OS_IPHONE

#pragma mark -
#pragma mark UIResponder

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
  _touchesBeganTimestamp = event.timestamp;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
  if ([touches count] > 1) {
    return;
  }

  UITouch *touch = [touches anyObject];
  if (touch.tapCount > 1) {
    return;
  }

  CGPoint viewLocation = [touch locationInView:self.scene.view];
  CGPoint sceneLocation = [self.scene convertPointFromView:viewLocation];
  CGPoint menuLocation = [self convertPoint:sceneLocation fromNode:self.scene];

  NSTimeInterval touchDuration = event.timestamp - _touchesBeganTimestamp;

  NSUInteger i = 0;
  for (SKNode *buttonNode in _buttonsNode.children) {
    if ([buttonNode containsPoint:menuLocation]) {
      if (touchDuration < HLMenuNodeLongSelectedDuration) {
        [self HL_selectedItem:i];
      } else {
        [self HL_longSelectedItem:i];
      }
      return;
    }
    ++i;
  }
}

#else

#pragma mark -
#pragma mark NSResponder

- (void)mouseDown:(NSEvent *)event
{
  _mouseDownTimestamp = event.timestamp;
}

- (void)mouseUp:(NSEvent *)event
{
  if (event.clickCount > 1) {
    return;
  }

  CGPoint menuLocation = [event locationInNode:self];

  NSTimeInterval mouseDuration = event.timestamp - _mouseDownTimestamp;

  NSUInteger i = 0;
  for (SKNode *buttonNode in _buttonsNode.children) {
    if ([buttonNode containsPoint:menuLocation]) {
      if (mouseDuration < HLMenuNodeLongSelectedDuration) {
        [self HL_selectedItem:i];
      } else {
        [self HL_longSelectedItem:i];
      }
      return;
    }
    ++i;
  }
}

#endif

#pragma mark -
#pragma mark Private

- (void)HL_showCurrentMenuAnimation:(HLMenuNodeAnimation)animation
{
  SKNode *oldButtonsNode = _buttonsNode;
  _buttonsNode = [SKNode node];
  [self addChild:_buttonsNode];

  id <HLMenuNodeDelegate> delegate = _delegate;
  BOOL delegateRespondsToWillDisplayButton = [delegate respondsToSelector:@selector(menuNode:willDisplayButton:forMenuItem:itemIndex:)];

  CGFloat widthMax = 0.0f;
  CGFloat heightTotal = 0.0f;
  NSUInteger itemCount = [_currentMenu itemCount];
  for (NSUInteger i = 0; i < itemCount; ++i) {
    HLMenuItem *item = [_currentMenu itemAtIndex:i];

    SKNode *buttonPrototype = item.buttonPrototype;
    if (!buttonPrototype) {
      if ([item isMemberOfClass:[HLMenuItem class]]) {
        buttonPrototype = _menuItemButtonPrototype;
      } else if ([item isMemberOfClass:[HLMenuBackItem class]]) {
        buttonPrototype = _backItemButtonPrototype;
      }
      if (!buttonPrototype) {
        buttonPrototype = _itemButtonPrototype;
      }
    }
    if (!buttonPrototype) {
      [NSException raise:@"HLMenuNodeMissingButtonPrototype" format:@"Missing button prototype for menu item."];
    }

    SKNode *buttonNode = [buttonPrototype copy];
    if ([buttonPrototype respondsToSelector:@selector(setText:)]) {
      [(id)buttonNode setText:item.text];
    }

    if (delegate && delegateRespondsToWillDisplayButton) {
      [delegate menuNode:self willDisplayButton:buttonNode forMenuItem:item itemIndex:i];
    }

    [_buttonsNode addChild:buttonNode];

    CGSize buttonSize = HLLayoutManagerGetNodeSize(buttonNode);
    if (buttonSize.width > widthMax) {
      widthMax = buttonSize.width;
    }
    heightTotal += buttonSize.height;
  }
  if (itemCount > 0) {
    heightTotal += (itemCount - 1) * self.itemSeparatorSize;
  }
  _size = CGSizeMake(widthMax, heightTotal);

  // note: x tracks the center of each button; y tracks the top edge of each button.
  CGFloat x = _size.width * (0.5f - _anchorPoint.x);
  CGFloat y = _size.height * (1.0f - _anchorPoint.y);
  for (SKNode *buttonNode in _buttonsNode.children) {
    [(id)buttonNode setAnchorPoint:CGPointMake(0.5f, 0.5f)];
    CGSize buttonSize = HLLayoutManagerGetNodeSize(buttonNode);
    buttonNode.position = CGPointMake(x, y - buttonSize.height * 0.5f);
    y = y - buttonSize.height - _itemSeparatorSize;
  }
  [self HL_layoutZ];

  if (animation == HLMenuNodeAnimationNone) {

    if (oldButtonsNode) {
      [oldButtonsNode removeFromParent];
    }

  } else {

    CGPoint delta;
    switch (animation) {
      case HLMenuNodeAnimationSlideLeft:
        delta = CGPointMake(-1.0f * (self.scene.size.width + _size.width) / 2.0f, 0.0f);
        break;
      case HLMenuNodeAnimationSlideRight:
        delta = CGPointMake((self.scene.size.width + _size.width) / 2.0f, 0.0f);
        break;
      default:
        [NSException raise:@"HLMenuNodeUnhandledAnimation" format:@"Unhandled animation %ld.", (long)animation];
    }

    _buttonsNode.position = CGPointMake(-delta.x, -delta.y);
    SKAction *animationAction = [SKAction moveByX:delta.x y:delta.y duration:_itemAnimationDuration];
    [_buttonsNode runAction:animationAction];

    if (oldButtonsNode) {
      // note: As of iOS8, doing the remove using an [SKAction removeFromParent] causes EXC_BAD_ACCESS.
      [oldButtonsNode runAction:[SKAction sequence:@[ animationAction,
                                                      [SKAction performSelector:@selector(removeFromParent) onTarget:oldButtonsNode] ]]];
    }
  }

  // noob: Okay to preload sounds in background thread?  What if the main thread
  // also tries to load the sound at the same time?
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    [self HL_loadCurrentMenuSounds];
  });
}

- (void)HL_layoutZ
{
  if (_buttonsNode) {
    CGFloat zPositionLayerIncrement = self.zPositionScale / HLMenuNodeZPositionLayerCount;
    CGFloat buttonNodeZPosition = HLMenuNodeZPositionLayerButtons * zPositionLayerIncrement;
    for (SKNode *buttonNode in _buttonsNode.children) {
      buttonNode.zPosition = buttonNodeZPosition;
      if ([buttonNode isKindOfClass:[HLComponentNode class]]) {
        ((HLComponentNode *)buttonNode).zPositionScale = zPositionLayerIncrement;
      }
    }
  }
}

- (void)HL_loadCurrentMenuSounds
{
  // noob: Okay to keep preloading the main sound over and over again?
  // Or is that dumb?
  if (self.itemSoundFile) {
    [SKAction playSoundFileNamed:self.itemSoundFile waitForCompletion:NO];
  }

  for (NSUInteger i = 0; i < [_currentMenu itemCount]; ++i) {
    HLMenuItem *item = [_currentMenu itemAtIndex:i];
    if (item.soundFile) {
      [SKAction playSoundFileNamed:item.soundFile waitForCompletion:NO];
    }
  }
}

- (void)HL_selectedItem:(NSUInteger)itemIndex
{
  HLMenuItem *item = [_currentMenu itemAtIndex:itemIndex];

  // note: Current use prefers playing the sound effect regardless of what
  // shouldTapMenuItem returns: This is an interface acknowledgement of the gesture, no
  // matter what happens.  In particular, there's a use case for a menu button which
  // decides to skip a submenu and navigate to a different location than normal in the
  // hierarchy, so it returns NO for shouldTapMenuItem and instead calls
  // navigateToSubmenuWithPath.  Many alternate solutions and implementations come to
  // mind; wait for a compelling competing use case.
  NSString *soundFile = (item.soundFile ? item.soundFile : _itemSoundFile);
  if (soundFile) {
    // noob: Have the scene run it in case we are pressing some kind of "dismiss" button
    // and the menu node is about to be removed from its parent.  Is there a standard way
    // of thinking about this?  After all, this isn't extreme enough: The scene might be
    // about to be dismissed, too.
    [self.scene runAction:[SKAction playSoundFileNamed:soundFile waitForCompletion:NO]];
  }

  id <HLMenuNodeDelegate> delegate = self.delegate;
  if (delegate) {
#if TARGET_OS_IPHONE
    if ([delegate respondsToSelector:@selector(menuNode:shouldTapMenuItem:itemIndex:)]
        && ![delegate menuNode:self shouldTapMenuItem:item itemIndex:itemIndex]) {
      return;
    }
#else
    if ([delegate respondsToSelector:@selector(menuNode:shouldClickMenuItem:itemIndex:)]
        && ![delegate menuNode:self shouldClickMenuItem:item itemIndex:itemIndex]) {
      return;
    }
#endif
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
#if TARGET_OS_IPHONE
    if ([delegate respondsToSelector:@selector(menuNode:didTapMenuItem:itemIndex:)]) {
      [delegate menuNode:self didTapMenuItem:item itemIndex:itemIndex];
    }
#else
    if ([delegate respondsToSelector:@selector(menuNode:didClickMenuItem:itemIndex:)]) {
      [delegate menuNode:self didClickMenuItem:item itemIndex:itemIndex];
    }
#endif
  }
}

- (void)HL_longSelectedItem:(NSUInteger)itemIndex
{
  HLMenuItem *item = [_currentMenu itemAtIndex:itemIndex];

  id <HLMenuNodeDelegate> delegate = self.delegate;
  if (delegate) {
#if TARGET_OS_IPHONE
    if ([delegate respondsToSelector:@selector(menuNode:didLongPressMenuItem:itemIndex:)]) {
      [delegate menuNode:self didLongPressMenuItem:item itemIndex:itemIndex];
    }
#else
    if ([delegate respondsToSelector:@selector(menuNode:didLongClickMenuItem:itemIndex:)]) {
      [delegate menuNode:self didLongClickMenuItem:item itemIndex:itemIndex];
    }
#endif
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
      [NSException raise:@"HLMenuNodeUnhandledAnimation" format:@"Unhandled animation %ld.", (long)animation];
  }
}

@end

@implementation HLMenuItem

+ (HLMenuItem *)menuItemWithText:(NSString *)text
{
  return [[[self class] alloc] initWithText:text];
}

- (instancetype)initWithText:(NSString *)text
{
  self = [super init];
  if (self) {
    _text = [text copy];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
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
  [aCoder encodeConditionalObject:_parent forKey:@"parent"];
  [aCoder encodeObject:_text forKey:@"text"];
  [aCoder encodeObject:_buttonPrototype forKey:@"buttonPrototype"];
  [aCoder encodeObject:_soundFile forKey:@"soundFile"];
}

- (void)setButtonPrototype:(SKNode *)buttonPrototype
{
  HLMenuNodeValidateButtonPrototype(buttonPrototype, @"buttonPrototype");
  _buttonPrototype = buttonPrototype;
}

- (NSArray *)path
{
  return [self HL_pathMutable];
}

- (NSMutableArray *)HL_pathMutable
{
  HLMenu *parent = _parent;
  // note: The top-level menu, by convention, has no text, and so is not included in the
  // path.
  if (!parent || !parent.parent) {
    return [NSMutableArray arrayWithObject:self.text];
  }
  NSMutableArray *path = [parent HL_pathMutable];
  [path addObject:self.text];
  return path;
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

- (instancetype)init
{
  return [self initWithText:@"" items:nil];
}

- (instancetype)initWithText:(NSString *)text
{
  return [self initWithText:text items:nil];
}

- (instancetype)initWithText:(NSString *)text items:(NSArray *)items
{
  self = [super initWithText:text];
  if (self) {
    if (items) {
      _items = [NSMutableArray arrayWithArray:items];
      [_items enumerateObjectsUsingBlock:^(HLMenuItem *item, NSUInteger index, BOOL *stop){
        item.parent = self;
      }];
    } else {
      _items = [NSMutableArray array];
    }
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
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
  return (HLMenuItem *)_items[index];
}

- (HLMenuItem *)itemForPath:(NSArray *)path
{
  HLMenuItem *matchingItem = self;
  NSUInteger pathComponentCount = [path count];
  for (NSUInteger pc = 0; pc < pathComponentCount; ++pc) {
    NSString *pathComponent = path[pc];
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
