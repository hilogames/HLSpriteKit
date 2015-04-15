//
//  HLToolNode.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 4/13/15.
//  Copyright (c) 2015 Hilo Games. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import "HLSpriteKit/HLComponentNode.h"

/**
 Defines tool-like interaction, where a "tool" is understood to be a button
 that appears on a toolbar or icon grid or menu or a similar tool container.
 
 Generally the tool container will provide an interface for setting tool state
 and a default configuration for tool appearance when set.  For example,
 see `[HLToolbarNode setEnabled:forTool:]` and `HLToolbarNode`'s properties
 `enabledAlpha` and `disabledAlpha`: disabling a tool dims it.  (See also
 the similar `[HLGridNode setEnabled:forSquare:]`.)  But if the tool conforms
 to `HLToolNode`, the tool container will detect that the tool might be able
 to enable itself.  If the `HLToolNode` responds to the `[HLToolNode hlToolSetEnabled:`]
 selector, then the tool container will call that selector rather than doing
 its default enabling.
 
 A couple thoughts:
 
  . Perhaps all tool containers should only accept `HLToolNode` objects, rather
    than trying to automatically detect conformance to a protocol.  But historically
    the tool containers only required simple `SKNode` objects, and it seems a pity
    to introduce another layer of complexity when most use-cases don't require it.
    Also it seems sensible that most of the time all tools in a toolbar would, for
    instance, use the same `disabledAlpha`; configuring each tool's `HLToolNode`
    separately, or using a prototype, or whatever else, seems overkill.
    
  . These `HLToolNode` methods will be called by a tool container, then, when it
    detects that one of its tools: 1) conforms to `HLToolNode`; and 2) responds to
    the particular optional selector.  Otherwise default tool-container configuration
    will be used.  This seems good, but another design comes to mind: Return an
    extra parameter from the methods which tells the tools container whether or
    not it should do its default configuration.  This would allow: 1) the `HLToolNode`
    to request a default configuration as well as adding its own particular tweaks;
    and 2) the `HLToolNode` protocol to require all methods, reducing the need for
    runtime checks and improving the capability of compile-time conformance.
*/
@protocol HLToolNode <NSObject>

@optional

- (void)hlToolSetEnabled:(BOOL)enabled;

- (void)hlToolSetHighlight:(BOOL)highlight;

@end

@interface HLToolBackHighlightNode : HLComponentNode <HLToolNode>

- (id)initWithContentNode:(SKNode *)contentNode backHighlightNode:(SKNode *)backHighlightNode;

- (void)hlToolSetHighlight:(BOOL)highlight;

@end
