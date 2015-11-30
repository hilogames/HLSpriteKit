//
//  HLViewController.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 11/14/2014.
//  Copyright (c) 2014 Karl Voskuil. All rights reserved.
//

#import "HLViewController.h"

#import <SpriteKit/SpriteKit.h>

#import "HLCatalogScene.h"

@implementation HLViewController

- (void)loadView
{
  SKView *skView = [[SKView alloc] init];
  skView.showsFPS = YES;
  skView.showsNodeCount = YES;
  skView.showsDrawCount = YES;
  self.view = skView;
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  HLCatalogScene *catalogScene = [[HLCatalogScene alloc] initWithSize:self.view.bounds.size];
  catalogScene.scaleMode = SKSceneScaleModeResizeFill;
  catalogScene.anchorPoint = CGPointMake(0.5f, 0.5f);
  [(SKView *)self.view presentScene:catalogScene];
}

- (BOOL)shouldAutorotate
{
  return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
    return UIInterfaceOrientationMaskAllButUpsideDown;
  } else {
    return UIInterfaceOrientationMaskAll;
  }
}

@end
