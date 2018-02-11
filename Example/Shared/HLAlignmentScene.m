//
//  HLAlignmentScene.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 1/10/18.
//  Copyright © 2018 Hilo Games. All rights reserved.
//

#import "HLAlignmentScene.h"

#import "HLSpriteKit.h"

@implementation HLAlignmentScene
{
  BOOL _contentCreated;
  HLToolbarNode *_applicationToolbarNode;
  SKNode *_skLayoutNode;
  SKNode *_hlLayoutNode;
  NSArray *_examplePositions;
  NSArray *_exampleLabelNodes;
  NSArray *_exampleLineNodes;
  NSArray *_exampleBoxNodes;
  HLToolbarNode *_skAlignToolbar;
  HLToolbarNode *_hlAlignToolbar;
  HLToolbarNode *_hlHeightToolbar;
  NSString *_hlHeightToolbarSelectionPrevious;
}

- (void)didMoveToView:(SKView *)view
{
  [super didMoveToView:view];

  if (!_contentCreated) {
    [self HL_createContent];
    _contentCreated = YES;
  }
  [self HL_layoutContent];
}

- (void)didChangeSize:(CGSize)oldSize
{
  [super didChangeSize:oldSize];
  [self HL_layoutContent];
  [self HL_layoutApplicationToolbarNode];
}

- (void)setApplicationToolbar:(HLToolbarNode *)applicationToolbarNode
{
  if (_applicationToolbarNode == applicationToolbarNode) {
    return;
  }
  if (_applicationToolbarNode) {
    [_applicationToolbarNode removeFromParent];
  }
  _applicationToolbarNode = applicationToolbarNode;
  if (_applicationToolbarNode) {
    [self addChild:_applicationToolbarNode];
    [self HL_layoutApplicationToolbarNode];
  }
}

#pragma mark - HLToolbarNodeDelegate

#if TARGET_OS_IPHONE
- (void)toolbarNode:(HLToolbarNode *)toolbarNode didTapTool:(NSString *)toolTag
#else
- (void)toolbarNode:(HLToolbarNode *)toolbarNode didClickTool:(NSString *)toolTag
#endif
{
  [toolbarNode setSelectionForTool:toolTag];
  if (toolbarNode == _skAlignToolbar) {
    [_hlAlignToolbar clearSelection];
    NSString *hlHeightToolbarSelection = [_hlHeightToolbar selectionTool];
    if (hlHeightToolbarSelection) {
      _hlHeightToolbarSelectionPrevious = hlHeightToolbarSelection;
      [_hlHeightToolbar clearSelection];
    }
  } else if (toolbarNode == _hlAlignToolbar) {
    [_skAlignToolbar clearSelection];
    if (![_hlHeightToolbar selectionTool]) {
      if (_hlHeightToolbarSelectionPrevious) {
        [_hlHeightToolbar setSelectionForTool:_hlHeightToolbarSelectionPrevious];
        _hlHeightToolbarSelectionPrevious = nil;
      } else {
        [_hlHeightToolbar setSelectionForTool:@"text"];
      }
    }
  }
  [self HL_examplesAlign];
}

#pragma mark - Private

- (void)HL_layoutApplicationToolbarNode
{
  _applicationToolbarNode.position = CGPointMake(0.0f, (_applicationToolbarNode.size.height - self.size.height) / 2.0f + 5.0f);
  //_applicationToolbarNode.size = CGSizeMake(self.size.width, 0.0f);  // height is automatic
  _applicationToolbarNode.zPosition = 1.0f;
  //[_applicationToolbarNode layoutToolsAnimation:HLToolbarNodeAnimationNone];
}

- (void)HL_createContent
{
  self.backgroundColor = [SKColor colorWithRed:0.7f green:0.9f blue:1.0f alpha:1.0f];
  SKColor *interfaceColor = [SKColor colorWithRed:0.3f green:0.2f blue:0.0f alpha:1.0f];

  SKNode *examplesNode = [self HL_examplesCreate];
  [self addChild:examplesNode];

  _skLayoutNode = [self HL_skLayoutCreateWithColor:interfaceColor];
  [self addChild:_skLayoutNode];

  _hlLayoutNode = [self HL_hlLayoutCreateWithColor:interfaceColor];
  [self addChild:_hlLayoutNode];

  [_skAlignToolbar setSelectionForTool:@"baseline"];
}

- (void)HL_layoutContent
{
  if (self.size.width >= self.size.height) {
    _skLayoutNode.position = CGPointMake(0.0f, 80.0f);
    _hlLayoutNode.position = CGPointMake(0.0f, -80.0f);
  } else {
    _skLayoutNode.position = CGPointMake(0.0f, 180.0f);
    _hlLayoutNode.position = CGPointMake(0.0f, -180.0f);
  }
  [self HL_examplesLayout];
  [self HL_examplesAlign];  // because alignments depend on node position
}

- (SKNode *)HL_examplesCreate
{
  SKNode *examplesNode = [SKNode node];
  NSMutableArray *exampleBoxNodes = [NSMutableArray array];
  NSMutableArray *exampleLineNodes = [NSMutableArray array];
  NSMutableArray *exampleLabelNodes = [NSMutableArray array];

  NSArray *texts = @[ @"acemruwxz", @"bdfklt bdfklt", @"gpqy gpqy", @"{([Q1j!∫∑|])}", @"LORUM IP" ];

  for (NSString *text in texts) {

    SKSpriteNode *boxNode = [SKSpriteNode spriteNodeWithColor:[SKColor blackColor] size:CGSizeZero];
    boxNode.alpha = 0.15f;
    boxNode.zPosition = 0.0f;
    [examplesNode addChild:boxNode];

    SKSpriteNode *lineNode = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor] size:CGSizeMake(100.0f, 1.0f)];
    lineNode.zPosition = 1.0f;
    [examplesNode addChild:lineNode];

    SKLabelNode *labelNode = [SKLabelNode labelNodeWithText:text];
    labelNode.fontColor = [SKColor blackColor];
    labelNode.zPosition = 1.0f;
    [examplesNode addChild:labelNode];

    [exampleBoxNodes addObject:boxNode];
    [exampleLineNodes addObject:lineNode];
    [exampleLabelNodes addObject:labelNode];
  }

  _exampleBoxNodes = exampleBoxNodes;
  _exampleLineNodes = exampleLineNodes;
  _exampleLabelNodes = exampleLabelNodes;

  return examplesNode;
}

- (void)HL_examplesLayout
{
  NSMutableArray *examplePositions = [NSMutableArray array];

  BOOL horizontalLayout = (self.size.width >= self.size.height);

  CGFloat x;
  CGFloat y;
  if (horizontalLayout) {
    x = -200.0f;
    y = 0.0f;
  } else {
    x = 0.0f;
    y = 80.0f;
  }

  NSUInteger examplesCount = [_exampleLabelNodes count];
  for (NSUInteger e = 0; e < examplesCount; ++e) {

    CGPoint examplePosition = CGPointMake(x, y);

    SKSpriteNode *boxNode = _exampleBoxNodes[e];
    boxNode.position = examplePosition;

    SKSpriteNode *lineNode = _exampleLineNodes[e];
    lineNode.position = examplePosition;
    if (horizontalLayout) {
      lineNode.size = CGSizeMake(100.0f, 1.0f);
    } else {
      lineNode.size = CGSizeMake(120.0f, 1.0f);
    }

    SKLabelNode *labelNode = _exampleLabelNodes[e];
    labelNode.position = examplePosition;
    if (horizontalLayout) {
      labelNode.fontSize = 18.0f;
    } else {
      labelNode.fontSize = 24.0f;
    }

#if TARGET_OS_IPHONE
    [examplePositions addObject:[NSValue valueWithCGPoint:examplePosition]];
#else
    [examplePositions addObject:[NSValue valueWithPoint:examplePosition]];
#endif

    if (horizontalLayout) {
      x += 100.0f;
    } else {
      y -= 40.0f;
    }
  }

  _examplePositions = examplePositions;
}

- (void)HL_examplesAlign
{
  NSString *skAlignSelected = [_skAlignToolbar selectionTool];
  if (skAlignSelected) {
    SKLabelVerticalAlignmentMode alignmentMode;
    if ([skAlignSelected isEqualToString:@"baseline"]) {
      alignmentMode = SKLabelVerticalAlignmentModeBaseline;
    } else if ([skAlignSelected isEqualToString:@"top"]) {
      alignmentMode = SKLabelVerticalAlignmentModeTop;
    } else if ([skAlignSelected isEqualToString:@"center"]) {
      alignmentMode = SKLabelVerticalAlignmentModeCenter;
    } else if ([skAlignSelected isEqualToString:@"bottom"]) {
      alignmentMode = SKLabelVerticalAlignmentModeBottom;
    } else {
      [NSException raise:@"HLLabelScene" format:@"Unrecognized alignment mode button \"%@\".", skAlignSelected];
    }
    [self HL_examplesAlignSKWithAlignmentMode:alignmentMode];
    return;
  }

  NSString *hlAlignSelected = [_hlAlignToolbar selectionTool];
  if (hlAlignSelected) {
    SKLabelVerticalAlignmentMode alignmentMode;
    if ([hlAlignSelected isEqualToString:@"baseline"]) {
      alignmentMode = SKLabelVerticalAlignmentModeBaseline;
    } else if ([hlAlignSelected isEqualToString:@"top"]) {
      alignmentMode = SKLabelVerticalAlignmentModeTop;
    } else if ([hlAlignSelected isEqualToString:@"center"]) {
      alignmentMode = SKLabelVerticalAlignmentModeCenter;
    } else if ([hlAlignSelected isEqualToString:@"bottom"]) {
      alignmentMode = SKLabelVerticalAlignmentModeBottom;
    } else {
      [NSException raise:@"HLLabelScene" format:@"Unrecognized alignment mode button \"%@\".", hlAlignSelected];
    }
    NSString *hlHeightSelected = [_hlHeightToolbar selectionTool];
    HLLabelHeightMode heightMode;
    if ([hlHeightSelected isEqualToString:@"text"]) {
      heightMode = HLLabelHeightModeText;
    } else if ([hlHeightSelected isEqualToString:@"font"]) {
      heightMode = HLLabelHeightModeFont;
    } else if ([hlHeightSelected isEqualToString:@"ascender"]) {
      heightMode = HLLabelHeightModeFontAscender;
    } else if ([hlHeightSelected isEqualToString:@"ascender-bias"]) {
      heightMode = HLLabelHeightModeFontAscenderBias;
    } else {
      [NSException raise:@"HLLabelScene" format:@"Unrecognized height mode button \"%@\".", hlHeightSelected];
    }
    [self HL_examplesAlignHLWithAlignmentMode:alignmentMode heightMode:heightMode];
    return;
  }
}

- (void)HL_examplesAlignSKWithAlignmentMode:(SKLabelVerticalAlignmentMode)alignmentMode
{
  for (NSUInteger e = 0; e < [_examplePositions count]; ++e) {
    CGPoint position = [_examplePositions[e] CGPointValue];
    SKLabelNode *labelNode = _exampleLabelNodes[e];
    SKSpriteNode *boxNode = _exampleBoxNodes[e];

    labelNode.position = position;
    labelNode.verticalAlignmentMode = alignmentMode;

    boxNode.hidden = NO;
    boxNode.size = labelNode.frame.size;
    switch (alignmentMode) {
      case SKLabelVerticalAlignmentModeBaseline:
        // note: No natural choice for anchor point.
        boxNode.hidden = YES;
        break;
      case SKLabelVerticalAlignmentModeTop:
        boxNode.anchorPoint = CGPointMake(0.5f, 1.0f);
        break;
      case SKLabelVerticalAlignmentModeCenter:
        boxNode.anchorPoint = CGPointMake(0.5f, 0.5f);
        break;
      case SKLabelVerticalAlignmentModeBottom:
        boxNode.anchorPoint = CGPointMake(0.5f, 0.0f);
        break;
    }
  }
  for (SKLabelNode *toolNode in _skAlignToolbar.toolNodes) {
    toolNode.verticalAlignmentMode = alignmentMode;
  }
}

- (void)HL_examplesAlignHLWithAlignmentMode:(SKLabelVerticalAlignmentMode)alignmentMode heightMode:(HLLabelHeightMode)heightMode
{
  for (NSUInteger e = 0; e < [_examplePositions count]; ++e) {
    CGPoint position = [_examplePositions[e] CGPointValue];
    SKLabelNode *labelNode = _exampleLabelNodes[e];
    SKSpriteNode *boxNode = _exampleBoxNodes[e];

    // note: Can use this method for convenience if you don't care about labelHeight:
    //   [labelNode alignVerticalWithAlignmentMode:alignmentMode heightMode:heightMode];
    SKLabelVerticalAlignmentMode useAlignmentMode;
    CGFloat labelHeight;
    CGFloat offsetY;
    [labelNode getVerticalAlignmentForAlignmentMode:alignmentMode
                                         heightMode:heightMode
                                   useAlignmentMode:&useAlignmentMode
                                        labelHeight:&labelHeight
                                            offsetY:&offsetY];
    labelNode.verticalAlignmentMode = useAlignmentMode;
    labelNode.position = CGPointMake(position.x, position.y + offsetY);

    boxNode.hidden = NO;
    boxNode.size = CGSizeMake(labelNode.frame.size.width, labelHeight);
    switch (alignmentMode) {
      case SKLabelVerticalAlignmentModeBaseline:
        // note: No natural choice for anchor point.
        boxNode.hidden = YES;
        break;
      case SKLabelVerticalAlignmentModeTop:
        boxNode.anchorPoint = CGPointMake(0.5f, 1.0f);
        break;
      case SKLabelVerticalAlignmentModeCenter:
        boxNode.anchorPoint = CGPointMake(0.5f, 0.5f);
        break;
      case SKLabelVerticalAlignmentModeBottom:
        boxNode.anchorPoint = CGPointMake(0.5f, 0.0f);
        break;
    }
  }
  for (HLLabelButtonNode *toolNode in _hlAlignToolbar.toolNodes) {
    toolNode.heightMode = heightMode;
  }
  for (HLLabelButtonNode *toolNode in _hlHeightToolbar.toolNodes) {
    toolNode.heightMode = heightMode;
  }
}

- (SKNode *)HL_skLayoutCreateWithColor:(SKColor *)interfaceColor
{
  SKNode *skLayoutNode = [SKNode node];

  SKLabelNode *titleNode = [SKLabelNode labelNodeWithFontNamed:@"Courier"];
  titleNode.text = @"SKLabelNode Vertical Alignment";
  titleNode.fontColor = interfaceColor;
  titleNode.fontSize = 12.0f;
  [skLayoutNode addChild:titleNode];

  _skAlignToolbar = [self HL_createToolbarForTexts:@[ @"baseline", @"top", @"center", @"bottom" ] color:interfaceColor labelOnly:YES];
  [skLayoutNode addChild:_skAlignToolbar];

  titleNode.position = CGPointMake(0.0f, 8.0f);
  _skAlignToolbar.position = CGPointMake(0.0f, -8.0f);

  return skLayoutNode;
}

- (SKNode *)HL_hlLayoutCreateWithColor:(SKColor *)interfaceColor
{
  SKNode *hlLayoutNode = [SKNode node];

  SKLabelNode *titleNode = [SKLabelNode labelNodeWithFontNamed:@"Courier"];
  titleNode.text = @"HLLabelNode Vertical Alignment";
  titleNode.fontColor = interfaceColor;
  titleNode.fontSize = 12.0f;
  [hlLayoutNode addChild:titleNode];

  _hlAlignToolbar = [self HL_createToolbarForTexts:@[ @"baseline", @"top", @"center", @"bottom" ] color:interfaceColor labelOnly:NO];
  [hlLayoutNode addChild:_hlAlignToolbar];

  _hlHeightToolbar = [self HL_createToolbarForTexts:@[ @"text", @"font", @"ascender", @"ascender-bias"] color:interfaceColor labelOnly:NO];
  [hlLayoutNode addChild:_hlHeightToolbar];

  titleNode.position = CGPointMake(0.0f, 20.0f);
  _hlAlignToolbar.position = CGPointMake(0.0f, 4.0f);
  _hlHeightToolbar.position = CGPointMake(0.0f, -20.0f);

  return hlLayoutNode;
}

- (HLToolbarNode *)HL_createToolbarForTexts:(NSArray *)toolTexts
                                      color:(SKColor *)interfaceColor
                                  labelOnly:(BOOL)labelOnly
{
  HLToolbarNode *toolbarNode = [[HLToolbarNode alloc] init];
  toolbarNode.automaticWidth = YES;
  toolbarNode.automaticHeight = YES;
  toolbarNode.toolPad = 2.0f;
  toolbarNode.backgroundBorderSize = 2.0f;
  toolbarNode.squareSeparatorSize = 2.0f;
  toolbarNode.highlightColor = [SKColor colorWithRed:0.0f green:1.0f blue:0.7f alpha:1.0f];

  [toolbarNode hlSetGestureTarget:toolbarNode];
  [self needSharedGestureRecognizersForNode:toolbarNode];
  toolbarNode.delegate = self;

  NSMutableArray *toolNodes = [NSMutableArray array];
  for (NSString *text in toolTexts) {
    if (labelOnly) {
      SKLabelNode *toolNode = [SKLabelNode labelNodeWithText:text];
      toolNode.fontColor = interfaceColor;
      toolNode.fontSize = 12.0f;
      toolNode.fontName = @"Courier";
      toolNode.verticalAlignmentMode = SKLabelVerticalAlignmentModeBaseline;
      [toolNodes addObject:toolNode];
    } else {
      HLLabelButtonNode *toolNode = [[HLLabelButtonNode alloc] initWithColor:interfaceColor size:CGSizeZero];
      toolNode.fontColor = [SKColor whiteColor];
      toolNode.fontSize = 12.0f;
      toolNode.fontName = @"Courier";
      toolNode.automaticWidth = YES;
      toolNode.automaticHeight = YES;
      toolNode.heightMode = HLLabelHeightModeFontAscenderBias;
      toolNode.labelPadX = 2.0f;
      toolNode.labelPadY = 2.0f;
      toolNode.text = text;
      [toolNodes addObject:toolNode];
    }
  }

  [toolbarNode setTools:toolNodes tags:toolTexts animation:HLToolbarNodeAnimationNone];
  return toolbarNode;
}

@end
