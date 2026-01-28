//
//  HLUglyShufflerTests.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 5/17/17.
//  Copyright © 2017 Hilo Games. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "HLUglyShuffler.h"

@interface HLUglyShufflerTests : XCTestCase

@end

@implementation HLUglyShufflerTests

- (void)testSampledN
{
  // note: It's not hard to find N for which the ugly shuffler fails one or more of the
  // following tests.  It's hard to know how to deal with this, since, ya know, it's the
  // ugly shuffler, and that's okay.  But right now treat these as simple regression
  // tests: Currently, they pass, and if something changes, we'd like to know, even if
  // we just have to find different N for which it passes.

  NSUInteger testValues[] = { 5, 8, 16, 17, 36, 37, 62, 63 };
  NSUInteger testValueLength = 8;
  for (NSUInteger t = 0; t < testValueLength; ++t) {
    NSUInteger itemCount = testValues[t];
    [self HL_testDistributionForItemCount:itemCount];
    [self HL_testAdjacenciesForItemCount:itemCount];
    [self HL_testFirstItemsForItemCount:itemCount];
    [self HL_testItemSubsequencesForItemCount:itemCount];
    [self HL_testDifferenceSubsequencesForItemCount:itemCount];
  }
}

- (void)HL_testDistributionForItemCount:(NSUInteger)itemCount
{
  // Each shuffle returns each item (0 <= item < N) exactly once.
  for (NSUInteger S = 0; S < itemCount; ++S) {
    HLUglyShuffler *shuffler = [[HLUglyShuffler alloc] initWithItemCount:itemCount shuffle:S];
    BOOL itemReturned[itemCount];
    for (NSUInteger i = 0; i < itemCount; ++i) {
      itemReturned[i] = NO;
    }
    for (NSUInteger i = 0; i < itemCount; ++i) {
      NSUInteger item = [shuffler nextItem];
      XCTAssertFalse(itemReturned[item],
                     @"Item %lu returned more than once by shuffle S=%lu for N=%lu.",
                     (unsigned long)item, (unsigned long)S, (unsigned long)itemCount);
      itemReturned[item] = YES;
    }
  }
}

- (void)HL_testAdjacenciesForItemCount:(NSUInteger)itemCount
{
  // Each shuffle (0 <= S < N) doesn't contain lots of adjacencies.
  const NSUInteger adjacenciesLimit = (NSUInteger)sqrt(itemCount) + 3;
  for (NSUInteger S = 0; S < itemCount; ++S) {
    HLUglyShuffler *shuffler = [[HLUglyShuffler alloc] initWithItemCount:itemCount shuffle:S];
    NSUInteger adjacencies = 0;
    NSUInteger currentItem = [shuffler nextItem];
    for (NSUInteger i = 0; i < itemCount; ++i) {
      NSUInteger nextItem = [shuffler nextItem];
      NSInteger difference = (NSInteger)nextItem - (NSInteger)currentItem;
      if (labs(difference) == 1) {
        ++adjacencies;
      }
      currentItem = nextItem;
    }
    XCTAssertLessThan(adjacencies, adjacenciesLimit,
                      @"Found %lu adjacent items for N=%lu in shuffle S=%lu; seems like too many.",
                      (unsigned long)adjacencies, (unsigned long)itemCount, (unsigned long)S);
  }
}

- (void)HL_testFirstItemsForItemCount:(NSUInteger)itemCount
{
  // Different shuffles (0 <= S < N) start on unique items.
  NSInteger startingItemTakenBy[itemCount];
  for (NSInteger i = 0; i < itemCount; ++i) {
    startingItemTakenBy[i] = -1;
  }
  for (NSUInteger S = 0; S < itemCount; ++S) {
    HLUglyShuffler *shuffler = [[HLUglyShuffler alloc] initWithItemCount:itemCount shuffle:S];
    NSUInteger item = [shuffler nextItem];
    XCTAssertEqual(startingItemTakenBy[item], -1,
                   @"Starting item %lu of N=%lu already used by shuffle S=%lu and so cannot be used for S=%lu.",
                   (unsigned long)item, (unsigned long)itemCount,
                   (unsigned long)startingItemTakenBy[item], (unsigned long)S);
    startingItemTakenBy[item] = S;
  }
}

- (void)HL_testItemSubsequencesForItemCount:(NSUInteger)itemCount
{
  // Different shuffles (0 <= S < N) don't contain the same subsequences of items.

  //   In two shuffles match one particular 3-sequence:                       1 / ( (N-1)(N-2) )
  //   In two shuffles match any of N 3-seqeunces:                            N / ( (N-1)(N-2) )
  //   Do this for all pairwise comparisons of N shuffles:  (N (N - 1) / 2) * N / ( (N-1)(N-2) )
  //   Simplify:                                            N^2 / (2N - 4)
  //
  // We expect about N/2 matching subsequences of length 3 in N shuffles.
  // The variance is, uh.  Normal?  Ugly shuffler is concerned with appearing random, so let's
  // say we expect no more than N 3-sequence matches.
  [self HL_testItemSubsequencesForItemCount:itemCount subsequenceLength:3 subsequenceLimit:itemCount];
  // For 4-sequences, similar math results in N^2 / ( (N-2)(N-3)2 ), which means we expect less
  // than one 4-sequence match for N shuffles, regardless of N.
  [self HL_testItemSubsequencesForItemCount:itemCount subsequenceLength:4 subsequenceLimit:1];
}

- (void)HL_testItemSubsequencesForItemCount:(NSUInteger)itemCount
                          subsequenceLength:(NSUInteger)subsequenceLength
                           subsequenceLimit:(NSUInteger)subsequenceLimit
{
  NSUInteger subsequenceCount = 0;
  for (NSUInteger S = 0; S < itemCount - 1; ++S) {
    HLUglyShuffler *shuffler = [[HLUglyShuffler alloc] initWithItemCount:itemCount shuffle:S];
    for (NSUInteger testS = S + 1; testS < itemCount; ++testS) {
      HLUglyShuffler *testShuffler = [[HLUglyShuffler alloc] initWithItemCount:itemCount shuffle:testS];
      NSUInteger matchLength = 0;
      NSUInteger subsequence[itemCount];
      NSUInteger i = 0;
      while (i < itemCount || (i < itemCount + subsequenceLength
                               && matchLength > 1
                               && matchLength < subsequenceLength)) {
        NSUInteger item = [shuffler nextItem];
        while ([testShuffler nextItem] != item) {
          matchLength = 0;
        }
        subsequence[matchLength] = item;
        ++matchLength;
        if (matchLength >= subsequenceLength) {
          ++subsequenceCount;
          if (subsequenceCount >= subsequenceLimit) {
            printf("(Example: Identical subsequence");
            for (NSUInteger j = matchLength - subsequenceLength; j < matchLength; ++j) {
              printf(" %lu", (unsigned long)subsequence[j]);
            }
            printf(" found in shuffles S=%lu and S=%lu for N=%lu.)\n",
                   (unsigned long)S, (unsigned long)testS, (unsigned long)itemCount);
          }
        }
        ++i;
      }
    }
  }
  XCTAssertLessThan(subsequenceCount, subsequenceLimit,
                    @"Identical subsequences of length %lu matched %lu times (limit %lu) in different shuffles for N=%lu.",
                    (unsigned long)subsequenceLength, (unsigned long)subsequenceCount,
                    (unsigned long)subsequenceLimit, (unsigned long)itemCount);
}

- (void)HL_testDifferenceSubsequencesForItemCount:(NSUInteger)itemCount
{
  // Different shuffles (0 <= S < N) don't contain the same
  // subsequences of differences.

  // note: This one is a bit limited, currently: We only check to see
  // if a bunch of shuffles all start with an adjacency.  Is there any
  // other pattern of differences that would be noticeable across
  // different shuffles?

  NSUInteger adjacencyCount = 0;
  for (NSUInteger S = 0; S < itemCount; ++S) {
    HLUglyShuffler *shuffler = [[HLUglyShuffler alloc] initWithItemCount:itemCount shuffle:S];
    NSUInteger firstShuffledItem = [shuffler nextItem];
    NSUInteger secondShuffledItem = [shuffler nextItem];
    NSInteger difference = labs((NSInteger)firstShuffledItem - (NSInteger)secondShuffledItem);
    if (difference == 1) {
      ++adjacencyCount;
    }
  }

  // note: If random, there are 2 picks out of N-1 items that would cause an adjacency between
  // the first and second cards.
  NSUInteger adjacencyLimit = (NSUInteger)sqrt(itemCount) + 3;

  XCTAssertLessThan(adjacencyCount, adjacencyLimit,
                    @"Too many shuffles begin with an adjacency for N=%lu.", (unsigned long)itemCount);
}

@end
