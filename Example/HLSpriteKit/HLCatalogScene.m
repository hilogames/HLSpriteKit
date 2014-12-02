//
//  HLCatalogScene.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 11/14/14.
//  Copyright (c) 2014 Karl Voskuil. All rights reserved.
//

#import "HLCatalogScene.h"

#import "HLSpriteKit.h"

@implementation HLCatalogScene
{
  BOOL _contentCreated;
  HLScrollNode *_catalogScrollNode;
  HLMessageNode *_messageNode;
}

- (void)didMoveToView:(SKView *)view
{
  if (!_contentCreated) {
    [self HL_createContent];
  }
  
  [self HL_showMessage:@"Scroll and zoom catalog using pan and pinch."];
}

- (void)HL_createContent
{
  SKSpriteNode *catalogNode = [SKSpriteNode spriteNodeWithColor:[SKColor colorWithRed:0.5f green:0.7f blue:0.9f alpha:1.0f] size:CGSizeZero];
  HLTableLayoutManager *catalogLayoutManager = [[HLTableLayoutManager alloc] initWithColumnCount:3
                                                                                    columnWidths:@[ @(0.0f) ]
                                                                              columnAnchorPoints:@[ [NSValue valueWithCGPoint:CGPointMake(0.5f, 0.5f)] ]
                                                                                      rowHeights:@[ @(0.0f) ]];
  catalogLayoutManager.tableBorder = 5.0f;
  catalogLayoutManager.columnSeparator = 15.0f;
  catalogLayoutManager.rowSeparator = 15.0f;
  [catalogNode hlSetLayoutManager:catalogLayoutManager];

  HLGridNode *gridNode = [self HL_createContentGridNode];
  [catalogNode addChild:gridNode];
  [gridNode hlSetGestureTarget:gridNode];
  gridNode.squareTappedBlock = ^(int squareIndex){
    [self HL_showMessage:[NSString stringWithFormat:@"Tapped HLGridNode squareIndex %d.", squareIndex]];
  };
  [self registerDescendant:gridNode withOptions:[NSSet setWithObject:HLSceneChildGestureTarget]];

  HLLabelButtonNode *labelButtonNode = [self HL_createContentLabelButtonNode];
  [catalogNode addChild:labelButtonNode];
  [labelButtonNode hlSetGestureTarget:[HLTapGestureTarget tapGestureTargetWithHandleGestureBlock:^(UIGestureRecognizer *gestureRecognizer){
    [self HL_showMessage:@"Tapped HLLabelButtonNode."];
  }]];
  [self registerDescendant:labelButtonNode withOptions:[NSSet setWithObject:HLSceneChildGestureTarget]];

  HLTiledNode *tiledNode = [self HL_createContentTiledNode];
  [catalogNode addChild:tiledNode];
  [tiledNode hlSetGestureTarget:[HLTapGestureTarget tapGestureTargetWithHandleGestureBlock:^(UIGestureRecognizer *gestureRecognizer){
    [self HL_showMessage:@"Tapped HLTiledNode."];
  }]];
  [self registerDescendant:tiledNode withOptions:[NSSet setWithObject:HLSceneChildGestureTarget]];

  HLToolbarNode *toolbarNode = [self HL_createContentToolbarNode];
  [catalogNode addChild:[SKNode node]];
  [catalogNode addChild:toolbarNode];
  [catalogNode addChild:[SKNode node]];
  [toolbarNode hlSetGestureTarget:toolbarNode];
  toolbarNode.toolTappedBlock = ^(NSString *toolTag){
    [self HL_showMessage:[NSString stringWithFormat:@"Tapped tool '%@' on HLToolbarNode.", toolTag]];
  };
  [self registerDescendant:toolbarNode withOptions:[NSSet setWithObject:HLSceneChildGestureTarget]];

  [catalogNode hlLayoutChildren];
  catalogNode.size = catalogLayoutManager.size;

  _catalogScrollNode = [[HLScrollNode alloc] initWithSize:self.size contentSize:catalogLayoutManager.size];
  _catalogScrollNode.contentInset = UIEdgeInsetsMake(30.0f, 30.0f, 30.0f, 30.f);
  _catalogScrollNode.contentScaleMinimum = 0.0f;
  _catalogScrollNode.contentScaleMinimumMode = HLScrollNodeContentScaleMinimumFitLoose;
  _catalogScrollNode.contentScaleMaximum = 2.0f;
  _catalogScrollNode.contentScale = 0.0f;
  _catalogScrollNode.contentNode = catalogNode;
  [self addChild:_catalogScrollNode];

  [_catalogScrollNode hlSetGestureTarget:_catalogScrollNode];
  [self registerDescendant:_catalogScrollNode withOptions:[NSSet setWithObjects:HLSceneChildResizeWithScene, HLSceneChildGestureTarget, nil]];
}

- (HLGridNode *)HL_createContentGridNode
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

- (HLLabelButtonNode *)HL_createContentLabelButtonNode
{
  HLLabelButtonNode *labelButtonNode = [[HLLabelButtonNode alloc] initWithColor:[SKColor colorWithRed:0.9f green:0.7f blue:0.5f alpha:1.0f]
                                                                           size:CGSizeMake(0.0f, 24.0f)];
  labelButtonNode.fontSize = 14.0f;
  labelButtonNode.automaticWidth = YES;
  labelButtonNode.automaticHeight = NO;
  labelButtonNode.labelPadX = 5.0f;
  labelButtonNode.verticalAlignmentMode = HLLabelNodeVerticalAlignFont;
  labelButtonNode.text = @"HLLabelButtonNode";
  return labelButtonNode;
}

- (HLTiledNode *)HL_createContentTiledNode
{
  CGSize imageSize = CGSizeMake(50.0f, 30.0f);
  UIGraphicsBeginImageContext(imageSize);
  CGContextRef context = UIGraphicsGetCurrentContext();
  // note: Flip, to account for differences in coordinate system for UIImage.
  CGContextTranslateCTM(context, 0.0f, imageSize.height);
  CGContextScaleCTM(context, 1.0f, -1.0f);
  CGContextSetFillColorWithColor(context, [[SKColor yellowColor] CGColor]);
  CGContextFillRect(context, CGRectMake(0.0f, 0.0f, imageSize.width / 2.0f, imageSize.height));
  CGContextSetFillColorWithColor(context, [[SKColor blueColor] CGColor]);
  CGContextFillRect(context, CGRectMake(imageSize.width / 2.0f, 0.0f, imageSize.width / 2.0f, imageSize.height));
  CGContextSetFillColorWithColor(context, [[SKColor greenColor] CGColor]);
  CGContextFillEllipseInRect(context, CGRectMake(2.0f, 2.0f, imageSize.width - 4.0f, imageSize.height - 4.0f));
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  SKTexture *texture = [SKTexture textureWithImage:image];
  HLTiledNode *tiledNode = [HLTiledNode tiledNodeWithTexture:texture size:CGSizeMake(120.0f, 100.0f)];
  return tiledNode;
}

- (HLToolbarNode *)HL_createContentToolbarNode
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

- (void)HL_showMessage:(NSString *)message
{
  if (!_messageNode) {
    _messageNode = [[HLMessageNode alloc] initWithColor:[SKColor colorWithWhite:0.0f alpha:0.3f]
                                                   size:CGSizeZero];
    _messageNode.zPosition = 1.0f;
    _messageNode.fontName = @"Helvetica";
    _messageNode.fontSize = 12.0f;
    _messageNode.verticalAlignmentMode = HLLabelNodeVerticalAlignFont;
    _messageNode.messageLingerDuration = 5.0;
  }
  _messageNode.size = CGSizeMake(self.size.width, 20.0f);
  _messageNode.position = CGPointMake(0.0f, (_messageNode.size.height - self.size.height) / 2.0f + 30.0f);
  [_messageNode showMessage:message parent:self];
}

@end
