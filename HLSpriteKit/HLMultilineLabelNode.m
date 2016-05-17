//
//  HLMultilineLabelNode.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 5/11/16.
//  Copyright (c) 2016 Hilo Games. All rights reserved.
//

#import "HLMultilineLabelNode.h"

@implementation HLMultilineLabelNode
{
  SKSpriteNode *_renderNode;
}

- (instancetype)initWithFontNamed:(NSString *)fontName
{
  self = [super init];
  if (self) {
    _renderNode = [SKSpriteNode node];
    [self addChild:_renderNode];

    _widthMaximum = 0.0f;
    _lineSpacing = 0.0f;
    _renderNode.anchorPoint = CGPointMake(0.5f, 0.5f);
    _alignment = NSTextAlignmentCenter;
    _fontName = [fontName copy];
    _fontSize = 32.0f;
    _fontColor = [SKColor whiteColor];
    _shadow = nil;

    [self GL_render];
  }
  return self;
}

- (instancetype)initWithText:(NSString *)text
                widthMaximum:(CGFloat)widthMaximum
                 lineSpacing:(CGFloat)lineSpacing
                   alignment:(NSTextAlignment)alignment
                    fontName:(NSString *)fontName
                    fontSize:(CGFloat)fontSize
                   fontColor:(UIColor *)fontColor
                      shadow:(NSShadow *)shadow
{
  self = [super init];
  if (self) {
    _renderNode = [SKSpriteNode node];
    [self addChild:_renderNode];

    _text = [text copy];
    _widthMaximum = widthMaximum;
    _lineSpacing = lineSpacing;
    _renderNode.anchorPoint = CGPointMake(0.5f, 0.5f);
    _alignment = alignment;
    _fontName = [fontName copy];
    _fontSize = fontSize;
    _fontColor = fontColor;
    _shadow = shadow;

    [self GL_render];
  }
  return self;
}

+ (instancetype)multilineLabelNodeWithFontNamed:(NSString *)fontName
{
  return [[[self class] alloc] initWithFontNamed:fontName];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
    _renderNode = [SKSpriteNode node];
    [self addChild:_renderNode];

    _text = [aDecoder decodeObjectForKey:@"text"];
    _widthMaximum = (CGFloat)[aDecoder decodeDoubleForKey:@"widthMaximum"];
    _lineSpacing = (CGFloat)[aDecoder decodeDoubleForKey:@"lineSpacing"];
    _renderNode.anchorPoint = [aDecoder decodeCGPointForKey:@"anchorPoint"];
    _alignment = [aDecoder decodeIntegerForKey:@"alignment"];
    _fontName = [aDecoder decodeObjectForKey:@"fontName"];
    _fontSize = (CGFloat)[aDecoder decodeDoubleForKey:@"fontSize"];
    _fontColor = [aDecoder decodeObjectForKey:@"fontColor"];
    _shadow = [aDecoder decodeObjectForKey:@"shadow"];

    [self GL_render];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [_renderNode removeFromParent];

  [super encodeWithCoder:aCoder];

  [aCoder encodeObject:_text forKey:@"text"];
  [aCoder encodeDouble:_widthMaximum forKey:@"widthMaximum"];
  [aCoder encodeDouble:_lineSpacing forKey:@"lineSpacing"];
  [aCoder encodeCGPoint:_renderNode.anchorPoint forKey:@"anchorPoint"];
  [aCoder encodeObject:_fontName forKey:@"fontName"];
  [aCoder encodeDouble:_fontSize forKey:@"fontSize"];
  [aCoder encodeObject:_fontColor forKey:@"fontColor"];
  [aCoder encodeObject:_shadow forKey:@"shadow"];

  [self addChild:_renderNode];
}

- (void)setText:(NSString *)text
{
  _text = [text copy];
  [self GL_render];
}

- (void)setWidthMaximum:(CGFloat)widthMaximum
{
  _widthMaximum = widthMaximum;
  [self GL_render];
}

- (CGPoint)anchorPoint
{
  return _renderNode.anchorPoint;
}

- (void)setAnchorPoint:(CGPoint)anchorPoint
{
  _renderNode.anchorPoint = anchorPoint;
}

- (void)setAlignment:(NSTextAlignment)alignment
{
  _alignment = alignment;
  [self GL_render];
}

- (void)setLineSpacing:(CGFloat)lineSpacing
{
  _lineSpacing = lineSpacing;
  [self GL_render];
}

- (CGSize)size
{
  return _renderNode.size;
}

- (void)setFontName:(NSString *)fontName
{
  _fontName = [fontName copy];
  [self GL_render];
}

- (void)setFontSize:(CGFloat)fontSize
{
  _fontSize = fontSize;
  [self GL_render];
}

- (void)setFontColor:(UIColor *)fontColor
{
  _fontColor = fontColor;
  [self GL_render];
}

- (void)setShadow:(NSShadow *)shadow
{
  _shadow = shadow;
  [self GL_render];
}

#pragma mark - Common

- (void)GL_render
{
  if (!_text || _text.length == 0) {
    _renderNode.texture = nil;
    _renderNode.size = CGSizeZero;
    return;
  }

  NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
  paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
  paragraphStyle.lineSpacing = _lineSpacing;
  paragraphStyle.alignment = _alignment;

  NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
  attributes[NSFontAttributeName] = [UIFont fontWithName:_fontName size:_fontSize];
  attributes[NSForegroundColorAttributeName] = _fontColor;
  attributes[NSParagraphStyleAttributeName] = paragraphStyle;
  if (_shadow) {
    attributes[NSShadowAttributeName] = _shadow;
  }

  NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:_text attributes:attributes];

  CGFloat width = (_widthMaximum > 0.0f ? _widthMaximum : CGFLOAT_MAX);
  CGRect boundingRect = [attributedText boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX)
                                                     options:(NSStringDrawingUsesLineFragmentOrigin)
                                                     context:nil];

  // note: [Tested on iOS 8.4 and 9.3.] The bitmap graphics context will convert the input
  // size to pixels using the current device scaling and then rounding up to the nearest
  // whole pixel.  For example on a lorum ipsum label on an iPhone 6 plus simulator:
  //
  //     _widthMaximum                   240.0
  //     boundingRect.size.width         229.48828125        calculated
  //     CGBitmapContextGetWidth         698                 then *3 and rounded up
  //     image.size.width                229.6               then /3
  //
  // This would all seem to be exactly what we want.
  UIGraphicsBeginImageContextWithOptions(boundingRect.size, NO, 0.0f);
  // note: Use `drawInRect:` on an attributed string, rather than `drawInRect:attributes:`.
  // On iOS 9.3 the latter does not render shadows correctly on multiline text.
  [attributedText drawInRect:boundingRect];
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  SKTexture *texture = [SKTexture textureWithImage:image];
  _renderNode.texture = texture;
  _renderNode.size = texture.size;
}

@end
