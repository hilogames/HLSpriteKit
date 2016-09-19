//
//  HLViewController.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 9/19/16.
//  Copyright © 2016 Hilo Games. All rights reserved.
//

#import "HLViewController.h"

#import <SpriteKit/SpriteKit.h>

#import "HLCatalogScene.h"

@implementation HLViewController

- (void)viewDidLoad
{
  [super viewDidLoad];

  SKView *skView = (SKView *)self.view;

  HLCatalogScene *catalogScene = [[HLCatalogScene alloc] initWithSize:skView.bounds.size];
  catalogScene.scaleMode = SKSceneScaleModeResizeFill;
  catalogScene.anchorPoint = CGPointMake(0.5f, 0.5f);
  [skView presentScene:catalogScene];

  skView.showsFPS = YES;
  skView.showsNodeCount = YES;
  skView.showsDrawCount = YES;
}

@end
