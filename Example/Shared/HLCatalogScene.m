//
//  HLCatalogScene.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 11/14/14.
//  Copyright (c) 2014 Karl Voskuil. All rights reserved.
//

#import "HLCatalogScene.h"

#import <TargetConditionals.h>

#import "HLSpriteKit.h"

#if ! TARGET_OS_IPHONE
// note: Under macOS, hack into the SKView to forward scroll wheel events
// in order to demonstrate scaling interaction in the HLScrollNode.
@implementation SKView(ScrollWheelForwarding)
- (void)scrollWheel:(NSEvent *)event
{
  [self.scene scrollWheel:event];
}
@end
#endif

@implementation HLCatalogScene
{
  BOOL _contentCreated;
  HLToolbarNode *_applicationToolbarNode;
  HLScrollNode *_catalogScrollNode;
  HLMessageNode *_messageNode;
  HLTiledNode *_tiledNode;
  SKSpriteNode *_tiledNodeSizeTemplateNode;
}

- (void)didMoveToView:(SKView *)view
{
  [super didMoveToView:view];

  if (!_contentCreated) {
    [self HL_createContent];
    _contentCreated = YES;
  }

#if TARGET_OS_IPHONE
  NSString *message = @"Scroll and zoom catalog using pan and pinch.";
#else
  NSString *message = @"Scroll catalog using left-click; zoom with scroll-wheel or trackpad pinch.";
#endif
  [self runAction:[SKAction sequence:@[ [SKAction waitForDuration:1.0],
                                        [SKAction runBlock:^{
    [self HL_showMessage:message];
  }] ]]];
}

- (void)didChangeSize:(CGSize)oldSize
{
  [super didChangeSize:oldSize];
  _catalogScrollNode.size = self.size;
  [self HL_layoutApplicationToolbarNode];
}

- (void)update:(NSTimeInterval)currentTime
{
  static NSTimeInterval lastTime = 0.0;
  if (lastTime > 0.0) {
    NSTimeInterval incrementalTime = currentTime - lastTime;
    [_tiledNode hlActionRunnerUpdate:incrementalTime];
  }
  lastTime = currentTime;
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

- (void)HL_layoutApplicationToolbarNode
{
  _applicationToolbarNode.size = CGSizeMake(self.size.width, 0.0f);
  [_applicationToolbarNode layoutToolsAnimation:HLToolbarNodeAnimationNone];
  _applicationToolbarNode.position = CGPointMake(0.0f, (_applicationToolbarNode.size.height - self.size.height) / 2.0f + 5.0f);
  _applicationToolbarNode.zPosition = 1.0f;
}

- (void)HL_createContent
{
  SKSpriteNode *catalogNode = [SKSpriteNode spriteNodeWithColor:[SKColor colorWithRed:0.5f green:0.7f blue:0.9f alpha:1.0f] size:CGSizeZero];
#if TARGET_OS_IPHONE
  NSArray *columnAnchorPoints = @[ [NSValue valueWithCGPoint:CGPointMake(0.5f, 0.5f)] ];
#else
  NSArray *columnAnchorPoints = @[ [NSValue valueWithPoint:NSMakePoint(0.5f, 0.5f)] ];
#endif
  HLTableLayoutManager *catalogLayoutManager = [[HLTableLayoutManager alloc] initWithColumnCount:2
                                                                                    columnWidths:@[ @(0.0f) ]
                                                                              columnAnchorPoints:columnAnchorPoints
                                                                                      rowHeights:@[ @(0.0f) ]];
  catalogLayoutManager.tableBorder = 5.0f;
  catalogLayoutManager.columnSeparator = 15.0f;
  catalogLayoutManager.rowSeparator = 15.0f;
  [catalogNode hlSetLayoutManager:catalogLayoutManager];

  HLMultilineLabelNode *multilineLabelNode = [self HL_createMultilineLabelNode];
  // note: Show the label on a solid background to illustrate the size of the multiline label node.
  SKSpriteNode *multilineLabelBackgroundNode = [SKSpriteNode spriteNodeWithColor:[SKColor colorWithRed:0.65f green:0.8f blue:0.95f alpha:1.0f]
                                                                            size:multilineLabelNode.size];
  [multilineLabelBackgroundNode addChild:multilineLabelNode];
#if TARGET_OS_IPHONE
  [multilineLabelNode hlSetGestureTarget:[HLTapGestureTarget tapGestureTargetWithHandleGestureBlock:^(UIGestureRecognizer *gestureRecognizer){
    [self HL_showMessage:@"Tapped HLMultilineLabelNode."];
  }]];
#else
  [multilineLabelNode hlSetGestureTarget:[HLClickGestureTarget clickGestureTargetWithHandleGestureBlock:^(NSGestureRecognizer *gestureRecognizer){
    [self HL_showMessage:@"Clicked HLMultilineLabelNode."];
  }]];
#endif
  [self needSharedGestureRecognizersForNode:multilineLabelNode];
  [catalogNode addChild:multilineLabelBackgroundNode];

  HLGridNode *gridNode = [self HL_createGridNode];
#if TARGET_OS_IPHONE
  gridNode.squareTappedBlock = ^(int squareIndex){
    [self HL_showMessage:[NSString stringWithFormat:@"Tapped HLGridNode squareIndex %d.", squareIndex]];
  };
#else
  gridNode.squareClickedBlock = ^(int squareIndex){
    [self HL_showMessage:[NSString stringWithFormat:@"Clicked HLGridNode squareIndex %d.", squareIndex]];
  };
#endif
  [gridNode hlSetGestureTarget:gridNode];
  [self needSharedGestureRecognizersForNode:gridNode];
  // Alternately, use UIResponder/NSResponder interface with squareTappedBlock/squareClickedBlock:
  //   gridNode.userInteractionEnabled = YES;
  [catalogNode addChild:gridNode];

  HLToolbarNode *toolbarNode = [self HL_createToolbarNode];
#if TARGET_OS_IPHONE
  toolbarNode.toolTappedBlock = ^(NSString *toolTag){
    [self HL_showMessage:[NSString stringWithFormat:@"Tapped tool '%@' on HLToolbarNode.", toolTag]];
  };
#else
  toolbarNode.toolClickedBlock = ^(NSString *toolTag){
    [self HL_showMessage:[NSString stringWithFormat:@"Clicked tool '%@' on HLToolbarNode.", toolTag]];
  };
#endif
  [toolbarNode hlSetGestureTarget:toolbarNode];
  [self needSharedGestureRecognizersForNode:toolbarNode];
  // Alternately, use UIResponder/NSResponder interface with toolTappedBlock/toolClickedBlock:
  //   toolbarNode.userInteractionEnabled = YES;
  [catalogNode addChild:toolbarNode];

  _tiledNode = [self HL_createTiledNodeWithSizeTemplateNode:&_tiledNodeSizeTemplateNode];
  [self HL_animateTiledNode];
#if TARGET_OS_IPHONE
  [_tiledNode hlSetGestureTarget:[HLTapGestureTarget tapGestureTargetWithHandleGestureBlock:^(UIGestureRecognizer *gestureRecognizer){
    [self HL_showMessage:@"Tapped HLTiledNode."];
    [self HL_animateTiledNode];
  }]];
#else
  [_tiledNode hlSetGestureTarget:[HLClickGestureTarget clickGestureTargetWithHandleGestureBlock:^(NSGestureRecognizer *gestureRecognizer){
    [self HL_showMessage:@"Clicked HLTiledNode."];
    [self HL_animateTiledNode];
  }]];
#endif
  [self needSharedGestureRecognizersForNode:_tiledNode];
  [_tiledNodeSizeTemplateNode addChild:_tiledNode];
  [catalogNode addChild:_tiledNodeSizeTemplateNode];

  HLLabelButtonNode *labelButtonNode = [self HL_createLabelButtonNode];
#if TARGET_OS_IPHONE
  [labelButtonNode hlSetGestureTarget:[HLTapGestureTarget tapGestureTargetWithHandleGestureBlock:^(UIGestureRecognizer *gestureRecognizer){
    [self HL_showMessage:@"Tapped HLLabelButtonNode."];
  }]];
#else
  [labelButtonNode hlSetGestureTarget:[HLClickGestureTarget clickGestureTargetWithHandleGestureBlock:^(NSGestureRecognizer *gestureRecognizer){
    [self HL_showMessage:@"Clicked HLLabelButtonNode."];
  }]];
#endif
  [self needSharedGestureRecognizersForNode:labelButtonNode];
  [catalogNode addChild:labelButtonNode];

  SKLabelNode *wideLabelNode = [self HL_createWideLabelNode];
  [self HL_animateWideLabelNode:wideLabelNode];
#if TARGET_OS_IPHONE
  [wideLabelNode hlSetGestureTarget:[HLTapGestureTarget tapGestureTargetWithHandleGestureBlock:^(UIGestureRecognizer *gestureRecognizer){
    [self HL_showMessage:@"Tapped SKLabelNode with text width fitting."];
    [self HL_animateWideLabelNode:wideLabelNode];
  }]];
#else
  [wideLabelNode hlSetGestureTarget:[HLClickGestureTarget clickGestureTargetWithHandleGestureBlock:^(NSGestureRecognizer *gestureRecognizer){
    [self HL_showMessage:@"Clicked SKLabelNode with text width fitting."];
    [self HL_animateWideLabelNode:wideLabelNode];
  }]];
#endif
  [self needSharedGestureRecognizersForNode:wideLabelNode];
  [catalogNode addChild:wideLabelNode];

  [catalogNode hlLayoutChildren];
  catalogNode.size = catalogLayoutManager.size;

  _catalogScrollNode = [[HLScrollNode alloc] initWithSize:self.size contentSize:catalogLayoutManager.size];
#if TARGET_OS_IPHONE
  _catalogScrollNode.contentInset = UIEdgeInsetsMake(30.0f, 30.0f, 30.0f, 30.f);
#else
  _catalogScrollNode.contentInset = NSEdgeInsetsMake(30.0f, 30.0f, 30.0f, 30.f);
#endif
  _catalogScrollNode.contentScaleMinimum = 0.0f;
  _catalogScrollNode.contentScaleMinimumMode = HLScrollNodeContentScaleMinimumFitLoose;
  _catalogScrollNode.contentScaleMaximum = 3.0f;
  _catalogScrollNode.contentScale = 0.0f;
  _catalogScrollNode.contentNode = catalogNode;
  [_catalogScrollNode hlSetGestureTarget:_catalogScrollNode];
  [self needSharedGestureRecognizersForNode:_catalogScrollNode];
  // Alternately, use UIResponder/NSResponder interface:
  //   _catalogScrollNode.userInteractionEnabled = YES;
  //   self.view.multipleTouchEnabled = YES;
  [self addChild:_catalogScrollNode];
}

#if ! TARGET_OS_IPHONE

- (void)scrollWheel:(NSEvent *)event
{
  NSPoint contentLocation = [event locationInNode:_catalogScrollNode.contentNode];
  CGFloat newContentScale = _catalogScrollNode.contentScale * (1.0f + event.deltaY * 0.02f);
  [_catalogScrollNode pinContentLocation:contentLocation andSetContentScale:newContentScale];
}

#endif

- (HLGridNode *)HL_createGridNode
{
  HLGridNode *gridNode = [[HLGridNode alloc] initWithGridWidth:3
                                                   squareCount:10
                                                   anchorPoint:CGPointMake(0.5f, 0.5f)
                                                    layoutMode:HLGridNodeLayoutModeFill
                                                    squareSize:CGSizeMake(24.0f, 24.0f)
                                          backgroundBorderSize:3.0f
                                           squareSeparatorSize:1.0f];
  NSMutableArray *gridContentNodes = [NSMutableArray array];
  for (NSInteger n = 0; n < 10; ++n) {
    SKLabelNode *contentNode = [SKLabelNode labelNodeWithFontNamed:@"Courier"];
    contentNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeCenter;
    contentNode.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    contentNode.fontSize = 12.0f;
    if (n == 9) {
      contentNode.text = @"None";
    } else {
      contentNode.text = [NSString stringWithFormat:@"%c", (char)(n + 65)];
    }
    [gridContentNodes addObject:contentNode];
  }
  [gridNode setContent:gridContentNodes];
  return gridNode;
}

- (HLLabelButtonNode *)HL_createLabelButtonNode
{
  HLLabelButtonNode *labelButtonNode = [[HLLabelButtonNode alloc] initWithColor:[SKColor colorWithRed:0.9f green:0.7f blue:0.5f alpha:1.0f]
                                                                           size:CGSizeMake(0.0f, 24.0f)];
  labelButtonNode.fontSize = 14.0f;
  labelButtonNode.automaticWidth = YES;
  labelButtonNode.automaticHeight = NO;
  labelButtonNode.labelPadX = 5.0f;
  labelButtonNode.heightMode = HLLabelHeightModeFont;
  labelButtonNode.text = @"HLLabelButtonNode";
  return labelButtonNode;
}

- (HLTiledNode *)HL_createTiledNodeWithSizeTemplateNode:(SKSpriteNode * __strong *)sizeTemplateNode
{
  CGSize imageSize = CGSizeMake(40.0f, 50.0f);

#if TARGET_OS_IPHONE
  UIGraphicsBeginImageContext(imageSize);
  CGContextRef context = UIGraphicsGetCurrentContext();
#else
  NSImage *image = [[NSImage alloc] initWithSize:imageSize];
  [image lockFocus];
  CGContextRef context = [NSGraphicsContext.currentContext CGContext];
#endif

  CGContextSetFillColorWithColor(context, [[SKColor colorWithRed:0.3f green:0.6f blue:0.3f alpha:0.8f] CGColor]);
  CGContextFillRect(context, CGRectMake(0.0f, 0.0f, imageSize.width, imageSize.height));

  CGContextSetFillColorWithColor(context, [[SKColor colorWithRed:0.3f green:0.7f blue:0.8f alpha:0.8f] CGColor]);
  CGContextFillRect(context, CGRectMake(2.0f, 2.0f, 13.0f, 13.0f));
  CGContextFillRect(context, CGRectMake(2.0f, imageSize.height - 15.0f, 13.0f, 13.0f));
  CGContextFillRect(context, CGRectMake(imageSize.width - 15.0f, 2.0f, 13.0f, 13.0f));
  CGContextFillRect(context, CGRectMake(imageSize.width - 15.0f, imageSize.height - 15.0f, 13.0f, 13.0f));

  CGContextSetFillColorWithColor(context, [[SKColor colorWithRed:0.1f green:0.3f blue:0.4f alpha:0.8f] CGColor]);
  CGContextFillRect(context, CGRectMake(2.0f, 2.0f, 4.0f, 4.0f));
  CGContextFillRect(context, CGRectMake(2.0f, imageSize.height - 6.0f, 4.0f, 4.0f));
  CGContextFillRect(context, CGRectMake(imageSize.width - 6.0f, 2.0f, 4.0f, 4.0f));
  CGContextFillRect(context, CGRectMake(imageSize.width - 6.0f, imageSize.height - 6.0f, 4.0f, 4.0f));

  CGContextSetFillColorWithColor(context, [[SKColor colorWithRed:0.8f green:0.6f blue:0.3f alpha:0.8f] CGColor]);
  CGContextFillRect(context, CGRectMake(17.0f, 4.0f, 6.0f, 8.0f));
  CGContextSetFillColorWithColor(context, [[SKColor colorWithRed:0.6f green:0.8f blue:0.3f alpha:0.8f] CGColor]);
  CGContextFillRect(context, CGRectMake(17.0f, imageSize.height - 12.0f, 6.0f, 8.0f));

  CGContextSetFillColorWithColor(context, [[SKColor colorWithRed:0.8f green:0.5f blue:0.6f alpha:0.8f] CGColor]);
  CGContextFillRect(context, CGRectMake(4.0f, 17.0f, 8.0f, 16.0f));
  CGContextSetFillColorWithColor(context, [[SKColor colorWithRed:0.6f green:0.5f blue:0.8f alpha:0.8f] CGColor]);
  CGContextFillRect(context, CGRectMake(imageSize.width - 12.0f, 17.0f, 8.0f, 16.0f));

  CGContextSetFillColorWithColor(context, [[SKColor whiteColor] CGColor]);
  CGContextFillRect(context, CGRectMake(19.0f, 24.0f, 2.0f, 2.0f));

#if TARGET_OS_IPHONE
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
#else
  [image unlockFocus];
#endif

  CGSize startingSize = CGSizeMake(120.0f, 100.0f);
  SKTexture *texture = [SKTexture textureWithImage:image];
  HLTiledNode *tiledNode = [HLTiledNode tiledNodeWithTexture:texture
                                                        size:startingSize
                                                    sizeMode:HLTiledNodeSizeModeCrop
                                                 anchorPoint:CGPointMake(0.5f, 0.5f)
                                                  centerRect:CGRectMake(0.4f, 0.32f, 0.2f, 0.36f)];

  *sizeTemplateNode = [SKSpriteNode spriteNodeWithColor:[SKColor colorWithWhite:0.2f alpha:1.0f] size:startingSize];

  return tiledNode;
}

- (void)HL_animateTiledNode
{
  static NSUInteger animateCount = 0;
  if (animateCount % 2 == 0) {
    _tiledNode.centerRect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
  } else {
    _tiledNode.centerRect = CGRectMake(0.4f, 0.32f, 0.2f, 0.36f);
  }
  _tiledNode.sizeMode = (animateCount / 2) % 3;
  ++animateCount;

  // Animation depends on hlUpdateActionRunner code in update method.
  HLAction *resizeAction = [HLAction customActionWithDuration:4.0f selector:@selector(HL_updateTiledNode:elapsedTime:duration:userData:) weakTarget:self userData:nil];
  [_tiledNode hlRunAction:resizeAction withKey:@"resize"];
}

- (void)HL_updateTiledNode:(HLTiledNode *)tiledNode
               elapsedTime:(CGFloat)elapsedTime
                  duration:(NSTimeInterval)duration
                  userData:(id)userData
{
  CGFloat normalTime = (CGFloat)(elapsedTime / duration);
  CGFloat startWidth = 0.0f;
  CGFloat startHeight = 0.0f;
  CGFloat finishWidth = 120.0f;
  CGFloat finishHeight = 100.0f;
  CGSize size = CGSizeMake((1.0f - normalTime) * startWidth + normalTime * finishWidth,
                           (1.0f - normalTime) * startHeight + normalTime * finishHeight);
  _tiledNode.size = size;
  _tiledNodeSizeTemplateNode.size = size;
}

- (HLToolbarNode *)HL_createToolbarNode
{
  HLToolbarNode *toolbarNode = [[HLToolbarNode alloc] init];
  toolbarNode.automaticHeight = NO;
  toolbarNode.automaticWidth = NO;
  toolbarNode.backgroundBorderSize = 2.0f;
  toolbarNode.squareSeparatorSize = 4.0f;
  toolbarNode.toolPad = 2.0f;
  toolbarNode.size = CGSizeMake(240.0f, 32.0f);

  NSMutableArray *toolNodes = [NSMutableArray array];
  NSMutableArray *toolTags = [NSMutableArray array];

  SKSpriteNode *redTool = [SKSpriteNode spriteNodeWithColor:[SKColor redColor] size:CGSizeMake(20.0f, 20.0f)];
  [toolNodes addObject:redTool];
  [toolTags addObject:@"red"];

  SKSpriteNode *orangeTool = [SKSpriteNode spriteNodeWithColor:[SKColor orangeColor] size:CGSizeMake(10.0f, 20.0f)];
  [toolNodes addObject:orangeTool];
  [toolTags addObject:@"orange"];

  SKSpriteNode *yellowTool = [SKSpriteNode spriteNodeWithColor:[SKColor yellowColor] size:CGSizeMake(30.0f, 20.0f)];
  [toolNodes addObject:yellowTool];
  [toolTags addObject:@"yellow"];

  SKSpriteNode *greenTool = [SKSpriteNode spriteNodeWithColor:[SKColor greenColor] size:CGSizeMake(20.0f, 20.0f)];
  [toolNodes addObject:greenTool];
  [toolTags addObject:@"green"];

  [toolbarNode setTools:toolNodes tags:toolTags animation:HLToolbarNodeAnimationSlideUp];
  return toolbarNode;
}

- (HLMultilineLabelNode *)HL_createMultilineLabelNode
{
  NSString *text = @"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.";
  HLMultilineLabelNode *multilineLabelNode = [[HLMultilineLabelNode alloc] initWithText:text
                                                                           widthMaximum:240.0f
                                                                     lineHeightMultiple:0.0f
                                                                            lineSpacing:0.0f
                                                                              alignment:NSTextAlignmentLeft
                                                                               fontName:@"Helvetica"
                                                                               fontSize:12.0f
                                                                              fontColor:[SKColor darkGrayColor]
                                                                                 shadow:nil];
  return multilineLabelNode;
}

- (SKLabelNode *)HL_createWideLabelNode
{
  SKLabelNode *wideLabelNode = [SKLabelNode node];
  wideLabelNode.fontColor = [SKColor blackColor];
  return wideLabelNode;
}

- (void)HL_animateWideLabelNode:(SKLabelNode *)wideLabelNode
{
  const NSTimeInterval duration = 5.0;
  const CGFloat widthMinimum = 10.0f;
  const CGFloat widthMaximum = 180.0;
  SKAction *decreaseWidthAction = [SKAction customActionWithDuration:duration actionBlock:^(SKNode *node, CGFloat elapsedTime){
    CGFloat normalTime = elapsedTime / duration;
    CGFloat widthCurrent = widthMinimum * normalTime + widthMaximum * (1.0f - normalTime);
    [self HL_updateWideLabelNode:wideLabelNode withWidthMaximum:widthCurrent];
  }];
  SKAction *increaseWidthAction = [SKAction customActionWithDuration:duration actionBlock:^(SKNode *node, CGFloat elapsedTime){
    CGFloat normalTime = elapsedTime / duration;
    CGFloat widthCurrent = widthMinimum * (1.0f - normalTime) + widthMaximum * normalTime;
    [self HL_updateWideLabelNode:wideLabelNode withWidthMaximum:widthCurrent];
  }];
  SKAction *changeWidthAction = [SKAction sequence:@[ decreaseWidthAction, increaseWidthAction ]];
  [wideLabelNode runAction:changeWidthAction];
  [self HL_updateWideLabelNode:wideLabelNode withWidthMaximum:widthMaximum];
}

- (void)HL_updateWideLabelNode:(SKLabelNode *)wideLabelNode withWidthMaximum:(CGFloat)widthMaximum
{
  NSString *text = @"Lorem ipsum dolor sit amet.";
  [wideLabelNode setText:text widthMaximum:widthMaximum
       fontSizePreferred:16.0f
         fontSizeMinimum:12.0f
          truncationMode:HLLabelTruncationModeMiddle
         truncationIndex:0];
}

- (void)HL_showMessage:(NSString *)message
{
  if (!_messageNode) {
    _messageNode = [[HLMessageNode alloc] initWithColor:[SKColor colorWithWhite:0.0f alpha:0.3f]
                                                   size:CGSizeZero];
    _messageNode.zPosition = 1.0f;
    _messageNode.fontName = @"Helvetica";
    _messageNode.fontSize = 12.0f;
    _messageNode.messageLingerDuration = 5.0;
  }
  _messageNode.size = CGSizeMake(self.size.width, 20.0f);
  _messageNode.position = CGPointMake(0.0f, (self.size.height - _messageNode.size.height) / 2.0f - 10.0f);
  [_messageNode showMessage:message parent:self];
}

@end
