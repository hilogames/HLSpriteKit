* Annoyances

  * Setting gestureTargetHitTestMode to
    HLSceneGestureTargetHitTestModeDeepestThenParent when
    ignoresSiblingOrder == YES.  Can there be a warning logged, or
    something, when there seems to be a mismatch?  Or how about a
    debug mode where HLScene's gestureRecognizer:shouldReceiveTouch:
    logs itself verbosely, so that you can see how it is making
    decisions?

* HLScrollNode

  * Implement inertial scrolling.

* Big Picture: Reimplement UIKit in SpriteKit.

  * Gesture handling should then be more like UIKit, where each view
    creates its own UIGestureRecognizers.  In that case, we need the
    ability to "add" UIGestureRecognizers to a node rather than a
    view; that implies that the scene keeps track of lots and lots of
    gesture recognizers, assigned to nodes, and it adds them to the
    view right a the moment that a touch starts over a certain node
    (?).  Interesting.

  * Gradual transition in the meantime: Make HLLabelButtonNode more
    like UIButton, and call it HLButtonNode.  Build an HLTableNode.

* Big Picture: Simpler HLGestureTarget

  * This is too much code to set up a gesture target:

        HLToolbarNode *toolbarNode = ...;
        [self addChild:toolbarNode];
        [toolbarNode hlSetGestureTarget:toolbarNode];
        toolbarNode.delegate = self;
        [self registerDescendant:toolbarNode withOptions:[NSSet setWithObject:HLSceneChildGestureTarget]];

  * Use case: Get handling code out of scene.

    * Works well for something like HLScrollNode and HLMenuNode.
      Works poorly for something like HLToolbarNode, because the
      handling code ends up delegated back to the scene anyway.  Nice
      to have string identifier for tools, I suppose.

    * But even for HLScrollNode, the whole thing where the content has
      to be gesture transparent is a mess.  Instead, it would be
      better like UIScrollView, where the scroller keeps its own
      gesture recognizers regardless of what is above it.

  * Use case: Ad-hoc creation of gesture-responsive nodes, like a
    popup.  Current system works well.  Although again, code ends up
    delegated back to the scene via the ad-hoc gesture target anyway,
    so it's not clear that it's better than having a single target for
    the gesture handler in the scene, and then detecting in that scene
    target that the popup is present and should get the tap.

  * Use case: Re-use of gesture targets among multiple components.
    Nah, doesn't work.  The reuable gesture targets just delegate all
    their work back to the owner; should have just left the code in
    the scene rather than doing all the complicated scene -> target ->
    scene stuff.

  * Use case: Extend someone else's component with custom gesture
    handling.  Maybe better to subclass rather than write a custom
    gesture target and attach it.  Could HLScrollNode be extended so
    that a double-tap does zooming?  Hm.  That example, plus the
    extension of HLToolbar to recognize pans, might be good motivating
    examples.

  * So go back to the simple goal of getting code out of the scene: We
    have UIGestureRecognizers in the scene, but we want the nodes to
    contain their own handling methods.

    * Create shared gesture recognizers in scene, and set up simple
      targets in the scene: handleTap, handleLongPress, etc.  Rather
      than do it in gestureHandler:shouldReceiveTouch:, just have a
      finite number of well-known target methods implemented in HLScene.

    * In each of those, provide a shared hit-testing method which can
      identify a good node target for a location (whether using
      z-position-first, or node-tree-depth-first).

    * Traverse the hit-test order looking for response to handleTap:,
      handleLongPress:, etc: They are optional methods from a protocol
      HLGestureTarget.  Return boolean from those indicating whether to
      continue or not.  Those guys can have their own
      "gestureHandlingEnabled" flags if they want.

    * The big thing this misses is ad-hoc gesture handling for nodes
      that aren't custom subclasses.  For that case and that case only,
      we could have standalone HLGestureTarget classes which can be
      attached via an SKNode category, and checked for separately by the
      HLScene routine.

    * Okay, the other thing it misses is trying to extend gesture
      handling for an out-of-the-box component like HLToolbarNode.  Say
      it only comes with tap and long press, and you want to add pan.
      In that case, you either must subclass the HLToolbarNode, or else
      you have to make an ad-hoc gesture target handler and attach it
      via the class category.

    * Which pretty much gets us back to where we started.

  * It would be nice, though, to not have an HLScene.  Put the power
    in the hands of the user's custom SKScene.  Provide an API for a
    collection of UIGestureRecognizers, with hooks to add all to view
    and remove all from view.  Provide an API for node hit testing
    routines.  Hm.
