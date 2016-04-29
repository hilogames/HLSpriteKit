# HLSpriteKit

[![CI Status](http://img.shields.io/travis/hilogames/HLSpriteKit.svg?style=flat)](https://travis-ci.org/hilogames/HLSpriteKit)
[![Version](https://img.shields.io/cocoapods/v/HLSpriteKit.svg?style=flat)](http://cocoadocs.org/docsets/HLSpriteKit)
[![License](https://img.shields.io/cocoapods/l/HLSpriteKit.svg?style=flat)](http://cocoadocs.org/docsets/HLSpriteKit)
[![Platform](https://img.shields.io/cocoapods/p/HLSpriteKit.svg?style=flat)](http://cocoadocs.org/docsets/HLSpriteKit)

SpriteKit scene and node subclasses, plus various utilities.

## Features

### HLGestureTarget

A gesture target handles gestures from `UIGestureRecognizer`s. It can
be attached to any `SKNode` using the class category
`SKNode+HLGestureTarget`.

The use pattern is this: The `SKScene` knows about its view, and so
the scene is the `UIGestureRecognizerDelegate`. It manages a
collection of shared gesture recognizers, which it attaches to and
detaches from its view as appropriate. When a certain gesture is
recognized by a gesture recognizer, the scene figures out which node
or nodes are the target of the gesture, and it forwards the gestures
to those nodes using the `HLGestureTarget` interface.

Here’s the point: The scene can effectively use `UIGestureRecognizer`s
rather than the `UIResponder` interface (`touchesBegan:withEvent:` and
the rest), and the gesture handling code can be encapsulated within
node subclasses (rather than dumped into a bloated scene).

### HLLayoutManager

A layout manager provides a single method (`layout`) to lay out
nodes. It can be attached to any `SKNode` using the class category
`SKNode+HLLayoutManager`.

Layout managers currently provided:

 * `HLTableLayoutManager`, for table-like layouts;

 * `HLRingLayoutManager`, for ring-like polar-coordinate layouts;

 * `HLOutlineLayoutManager`, for vertical lists (especially of text)
   indented in levels.

Putting layout code in a third-party object (rather than in the
`SKScene` or `SKNode` subclass) allows for easier reuse of common
layout math.

### Custom SKNode Subclasses

`HLSpriteKit` includes a number of custom `SKNode` subclasses.

 * `HLGridNode`. Organizes content into a grid of same-size squares,
   with visual formatting and interaction options.

 * `HLLabelButtonNode`. A simple `SKLabelNode` displayed over an
   `SKSpriteNode`, but with extra sizing and alignment options. In
   particular, it can size the sprite node to the text, and it can do
   baseline alignment so that the full font size (including descender)
   is vertically centered in the background; the math for the
   calculation is provided for all `SKLabelNode`s in a category
   `SKLabelNode+HLLabelNodeAdditions`.

 * `HLMenuNode`. An interface and model of a hierarchical menu of
   buttons. The interface is a simple vertical stack of buttons, for
   now, but it provides a few layout and animation features.

 * `HLMessageNode`. Shows a text message over a solid or textured
   background, with some animation options.

 * `HLRingNode`. A collection of items (usually buttons) arranged in a
   circle around a center point.

 * `HLScrollNode`. Provides support for scrolling and scaling its
   content with pan and pinch gestures. The interface is deliberately
   analogous to `UIScrollView`.

 * `HLToolbarNode`. A horizontal toolbar of squares, with various
   visual formatting, sizing, and animation options.

 * `HLTiledNode`. Behaves like an `SKSpriteNode` that tiles its
   texture to fit a specified size.

### HLScene

`HLScene` contains functionality useful to many scenes, including but
not limited to:

 * loading scene assets in a background thread
 * a shared gesture recognition system and an `HLGestureTarget`-aware
   gesture delegate implementation
 * modal presentation of a node above the scene
 * registration of nodes for common scene-related behaviors
   (e.g. resizing when the scene resizes; not encoding when the scene
   encodes; and so on)

### HLAction

`HLAction` provides encodable alternatives to block-running `SKAction`
actions.

The problem: When the `SKScene` node hierarchy is encoded, as is
common during application state preservation or a “game save”, nodes
running `SKAction` actions with code blocks must be handled specially,
since the code blocks cannot be encoded. In particular, attempting to
encode either `runBlock:` or `customActionWithDuration:actionBlock:`
leads to a runtime warning message:

  > SKAction: Run block actions can not be properly encoded, Objective-C
  > blocks do not support NSCoding.

The `HLAction` file provides a few encodable alternatives. The basic
idea is to use selector callbacks (with extra features) rather than
code blocks.

## Gesture Recognition FAQ and Examples

### I want to use `UIGestureRecognizer` in my scene to recognize gestures.

Here is the pattern used in `HLSpriteKit`:

 * Your scene owns all gesture recognizer objects relevant to the
   scene. As it is presented on an `SKView`, it adds its gesture
   recognizers to the view.

 * Your scene is the delegate of the gesture recognizers; that is, the
   `UIGestureRecognizerDelegate`.

 * Right before a gesture recognizer starts recognizing, in
   `gestureRecognizer:shouldReceiveTouch:`, your scene sets the
   gesture recognizer’s target (object and selector) to the most
   relevant receiver node. As the gesture is recognized, that node
   will get the calls.

Consider some alternate designs. In particular, say your scene
contains a number of button nodes that should respond to tap
events. These are design possibilities that are **not** the pattern
used in `HLSpriteKit`:

 * Each button could have its own `UITapGestureRecognizer` added to
   the `SKView`.

 * The buttons could share a single `UITapGestureRecognizer` that has
   a fixed target method in your scene; call it `handleTap:`. When a
   tap gesture was recognized, `handleTap:` would figure out which
   button was being tapped, and execute appropriate code.

 * The buttons could share a single `UITapGestureRecognizer` and each
   add a separate target to it. When a tap gesture was recognized,
   each target would decide whether it was being tapped, and execute
   appropriate code if so.

### I want to use `UIGestureRecognizer` in my scene the `HLSpriteKit` way.

Create your scene as a subclass of `HLScene`.

### I want to use one of your gesture-target components, like `HLToolbarNode`, in my scene.

The components in `HLSpriteKit` are gesture targets, but the mechanism
is disabled by default. It takes a few lines of code to get it going.

First, make sure you are a subclass of `HLScene`:

```obj-c
#import "HLSpriteKit/HLSpriteKit.h"

@interface MyScene : HLScene
```

Next, create your `HLToolbarNode` and add it to your scene:

```obj-c
HLToolbarNode *toolbarNode = ...;
toolbarNode.delegate = self;
[self addChild:toolbarNode];
```

Finally, set the toolbar’s gesture target to itself, and register it
with the scene as a gesture target:

```obj-c
[toolbarNode hlSetGestureTarget:toolbarNode];
[self registerDescendant:toolbarNode withOptions:[NSSet setWithObject:HLSceneChildGestureTarget]];
```

This will give you delegate callbacks for taps on toolbar tools.

See the Example project (`HLSpriteKit/Example/HLSpriteKit/HLCatalogScene.m` in project or
[on GitHub](https://github.com/hilogames/HLSpriteKit/blob/master/Example/HLSpriteKit/HLCatalogScene.m))
for a working example of a scene using multiple gesture targets.

### I want to make my own gesture-target nodes in my scene.

Okay!

Here are your options:

 1. Create a custom node that can be its own gesture target.

 2. Attach a generic gesture target to an existing node.

 3. Attach a custom gesture target to an existing node.

 4. Handle it in the scene.

#### Create a custom node that can be its own gesture target.

Follow the pattern of components in `HLSpriteKit`, and conform to the
`HLGestureTarget` protocol in your custom node class. Through the
`HLGestureTarget` interface, your node will tell its scene what
`UIGestureRecognizer`s it expects, and what to do when those gesture
recognizers trigger.

You can then include your node in your scene the same way you included
the gesture-target components of `HLSpriteKit`.

#### Attach a generic gesture target to an existing node.

Sometimes creating a new node class seems like overkill. Sometimes
even implementing a delegate interface seems like overkill. Here are
some examples:

 * You have a red square sprite node in your scene, and you want it to
   wiggle when you tap it.

 * You want to pop up a label node with some text on it, and have it
   dismiss itself when tapped.

Or here’s a different problem: Say you get an out-of-the-box node
class from a third-party library, which doesn't have any kind of
interaction programmed, and you want it to respond to taps.

For all these problems, you can attach a generic gesture target to an
existing node, without creating any new classes.

Here is the code for making a red square sprite node wiggle when you
tap it, assuming your scene is a subclass of `HLScene`:

```obj-c
SKSpriteNode *redSquareNode = [SKSpriteNode spriteNodeWithColor:[SKColor redColor] size:CGSizeMake(20.0f, 20.0f)];
[self addChild:redSquareNode];
HLTapGestureTarget *tapGestureTarget = [[HLTapGestureTarget alloc] init];
tapGestureTarget.handleGestureBlock = ^(UIGestureRecognizer *gestureRecognizer){
  // wiggle red square node
};
[redSquareNode hlSetGestureTarget:tapGestureTarget];
[self registerDescendant:redSquareNode withOptions:[NSSet setWithObject:HLSceneChildGestureTarget]];
```

If you're into the whole brevity thing, you can combine some of the
lines:

```obj-c
SKSpriteNode *redSquareNode = [SKSpriteNode spriteNodeWithColor:[SKColor redColor] size:CGSizeMake(20.0f, 20.0f)];
[redSquareNode hlSetGestureTarget:[HLTapGestureTarget tapGestureTargetWithHandleGestureBlock:^(UIGestureRecognizer *gestureRecognizer){
  // wiggle red square node
}]];
[self addChild:redSquareNode withOptions:[NSSet setWithObject:HLSceneChildGestureTarget]];
```

The `HLTapGestureTarget` is a simple implementation of a gesture
target which only knows about tap gestures (and not pans or
long-presses). Because the tap gesture is so straightforward, it’s
easy to reuse the same gesture target for just about any node.

The popup example:

```obj-c
HLLabelButtonNode *labelButtonNode = [[HLLabelButtonNode alloc] initWithColor:[SKColor blackColor] size:CGSizeZero];
labelButtonNode.automaticWidth = YES;
labelButtonNode.automaticHeight = YES;
labelButtonNode.text = @"Tap to dismiss";
[self addChild:labelButtonNode];

[labelButtonNode hlSetGestureTarget:[HLTapGestureTarget tapGestureTargetWithHandleGestureBlock:^(UIGestureRecognizer *gestureRecognizer){
  [labelButtonNode removeFromParent];
}]];
[self registerDescendant:labelButtonNode withOptions:[NSSet setWithObject:HLSceneChildGestureTarget]];
```

`HLLabelButtonNode` doesn't even implement its own gesture target,
since the generic `HLTapGestureTarget` is usually all the owner
wants. Thus, this code serves also as an example of attaching a
generic gesture target to a third-party node.

#### Attach a custom gesture target to an existing node.

`HLToolbarNode` recognizes taps, but not long-presses. Can you get
long-presses? Maybe pans, too?

You can write your own custom `HLGestureTarget` and attach it to the
node using the familiar `SKNode` category extension
`hlSetGestureTarget`.

I did this as an exercise, and found it unpleasant. The result of my
exercise is class `HLToolbarNodeMultiGestureTarget` declared in
`HLToolbarNode.h`. Once written, the enabling code is familiar:

```obj-c
HLToolbarNode *toolbarNode = ...;
toolbarNode.delegate = self;
[self addChild:toolbarNode];

HLToolbarNodeMultiGestureTarget *multiGestureTarget = [[HLToolbarNodeMultiGestureTarget alloc] initWithToolbarNode:toolbarNode];
multiGestureTarget.delegate = self;
[toolbarNode hlSetGestureTarget:multiGestureTarget];
[self registerDescendant:toolbarNode withOptions:[NSSet setWithObject:HLSceneChildGestureTarget]];
```

You can use the `HLToolbarNodeMultiGestureTarget` class as a pattern
for writing your own custom gesture targets.

In the design stages, the ability to write customized gesture targets
for any node seemed like a strength of the `HLGestureTarget`
system. For instance, it keeps bloat out of the default
`HLToolbarNode` gesture target. But in practice, it seems like way too
much work to get gesture handling code out of the scene, only to
delegate the calls right back into the scene.

Perhaps a better design alternative would be to subclass
`HLToolbarNode` in order to override the default gesture handling. Or
to handle the gestures in the scene rather than in a gesture target.

#### Handle it in the scene.

One of the goals of `HLGestureTarget` is to get gesture-handling code
out of the scene, so that it can be more easily reused between scenes.

But here we are. You want to handle some gestures in the scene.

You can see an example of this kind of hybrid model in
[a scene in Flippy](https://github.com/hilogames/Flippy/blob/master/Flippy/FLTrackScene.mm). Search
for the bloated method `gestureRecognizer:shouldReceiveTouch:`. The
scene handles most gestures inline, but then sometimes calls `[super]`
to let `HLScene` handle the real `HLGestureTarget` components. Here is
an excerpt:

```obj-c
// Modal overlay layer (handled by HLScene).
if ([self modalNodePresented]) {
  return [super gestureRecognizer:gestureRecognizer shouldReceiveTouch:touch];
}

// Construction toolbar.
if (_constructionToolbarState.toolbarNode
    && _constructionToolbarState.toolbarNode.parent
    && [_constructionToolbarState.toolbarNode containsPoint:sceneLocation]) {
  if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
    [gestureRecognizer removeTarget:nil action:NULL];
    [gestureRecognizer addTarget:self action:@selector(handleConstructionToolbarPan:)];
    return YES;
  }
  if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]
      && [(UITapGestureRecognizer *)gestureRecognizer numberOfTapsRequired] == 1) {
    [gestureRecognizer removeTarget:nil action:NULL];
    [gestureRecognizer addTarget:self action:@selector(handleConstructionToolbarTap:)];
    return YES;
  }
  if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
    [gestureRecognizer removeTarget:nil action:NULL];
    [gestureRecognizer addTarget:self action:@selector(handleConstructionToolbarLongPress:)];
    return YES;
  }
  return NO;
}

...
```

Note how the override follows the same pattern as `HLScene`: If a
certain component should get the gesture, then the old gesture target
is cleared and a new one set.

### I want to use one of your gesture-target components, like `HLToolbarNode`, in my scene, but I don't want to use your gesture handling system.

`HLGestureTarget` is lightweight, and optional, and should not
introduce overhead for the `HLSpriteKit` components.

That said, I haven't bothered to write `UIResponder` implementations
for the components yet, or even good public interfaces for controlling
the interaction externally.

I would be happy to do so, or to accept pull requests for such
implementations. Let me know what you need!

## Development

`HLSpriteKit` is under active development, and so includes other
experimental classes and functions which seem general enough for
reuse. For instance, an `SKEmitterNode` store and some image
manipulation functions are included, but it’s not clear they are
useful.

## Installation

`HLSpriteKit` is available through [CocoaPods](http://cocoapods.org).
To install it, simply add the following line to your Podfile:

    pod 'HLSpriteKit'

## Author

Karl Voskuil (karl * hilogames dot com)

## License

`HLSpriteKit` is available under the MIT License. See the LICENSE file
for more info.
