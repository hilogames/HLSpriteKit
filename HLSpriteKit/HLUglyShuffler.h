//
//  HLUglyShuffler.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 5/17/17.
//  Copyright (c) 2017 Hilo Games. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 A shuffler that can produce one of N different random-ish shuffles of N items.  The next
 item in the shuffle is computed in constant time, and the shuffler itself uses constant
 storage.

 It is the Ugly Shuffler:

  * Ugly, because the quality of the random-ness is poor;

  * Shuffler, because it produces a full-cycle (or maximum length sequence) of all N items
    before repeats.

 ### Motivation

 A random shuffle (limited only by the quality of the underlying random number generator)
 can be produced by the well-known Fisher-Yates technique: Pick each subsequent item
 randomly from all unpicked items.  The implementation generally requires a storage on the
 order of N (either the entire shuffle, or a list of picked, or a list of unpicked).  The
 algorithm can produce up to N! distinct shuffles of N items.

 For some applications, this kind of randomness is not necessary.  For instance:

  * Say we have a large list of N names that are to be issued to characters in a game.
    We'd like to use every name once before repeating ourselves, and we'd like the order
    of issued names to be somewhat unpredictable, but we do not require N! different
    permutations of names.  Furthermore, it seems silly to store a list of unused names in
    every single save-game file.

  * Say we have a playlist of music to shuffle.  Again, the shuffling does not need to be
    maximally random, and again it seems like overkill to use an algorithm which must
    store (or compute) proportionally to N.

 That said, even relaxed applications like these want more than one distinct shuffle.
 After all, not every game should issue names in the same order, and not every playthrough
 of music should be the same.  It would be nice to have about, oh, say, N different
 shuffles.  After N games, or after N evenings of music, it seems okay to resuse an old
 shuffle.

 ### Implementation

 Many implementations are possible.

 Some implementations appear quite random in all N shuffles.  The ugly shuffler might be
 implemented using a class of PRNG known to create a full cycle under certain conditions
 (https://en.wikipedia.org/wiki/Full_cycle).  In particular, note the linear feedback
 shift register, which can be created for a given N (closest power of two, anyway).  That
 might be nice!

 Some implementations might generate their N shuffles in a way that ensures minimum
 spacing between consecutive items.  That can be nice when the original item list is
 ordered in an extremely recognizable way.  For instance, if the original items are an
 alphabetical list of names, a player might think it strange to see two Z names issued one
 after another.  Or, if the original items are a playlist of a few albums of songs, the
 listener might think it strange to hear two consecutive tracks from the same album.  So,
 a shuffler that guaranteed a little space might be nice.

 But this is the ugly shuffler!  You do not know what you are getting, except that it will
 be ugly, and a shuffle!
*/
@interface HLUglyShuffler : NSObject <NSCoding>

- (instancetype)initWithItemCount:(NSUInteger)itemCount shuffle:(NSUInteger)shuffleIdentifier;

- (NSUInteger)nextItem;

- (NSUInteger)peekItem;

@end

/**
 Convenience method for printing out a table of items for all possible shuffles.
*/
void HLUglyShufflerDumpItems(NSUInteger itemCount);

/**
 Convenience method for printing out a table of differences for all possible shuffles.
*/
void HLUglyShufflerDumpDifferences(NSUInteger itemCount);

/**
 Convenience method for printing out a histogram of differences for all possible shuffles.
*/
void HLUglyShufflerDumpDifferencesHistogram(NSUInteger itemCount);
