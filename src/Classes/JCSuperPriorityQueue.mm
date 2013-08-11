//
//  JCSuperPriorityQueue.mm
//  JCPriorityQueue
//
//  Created by Jesse Collis on 28/02/12.
//  Copyright (c) 2012 JC Multimedia Design. All rights reserved.
//

#import "JCSuperPriorityQueue.h"
#import <algorithm>

struct JCPQNode {
    id obj;
    float val;
};

static bool NodeLessThan(struct JCPQNode &n1, struct JCPQNode &n2)
{
    if (n1.val != n2.val)
    {
        return n1.val < n2.val;
    }
    
    //FIXME: is it important or necessary to compare them at this point?
    return false; //(unsigned) n1.obj < (unsigned) n2.obj;
}

@implementation JCSuperPriorityQueue {
    // For ARC
    NSMutableArray *_storage;
}

- (id)init
{
    if ((self = [super init]))
    {
        //TODO: Optimise the allocation
        mCapacity = 1024;
        mObjs = (struct JCPQNode *)calloc(mCapacity, sizeof(*mObjs));
        if (mObjs == NULL) {
            NSLog(@"Error allocate");
        }
        
        // ARC
        _storage = [[NSMutableArray alloc] initWithCapacity:mCapacity];
        
        [self clear];
    }
    
    return self;
}

- (void)dealloc
{
    free(mObjs);
    
    // ARC
    [_storage removeAllObjects];
}

- (void)clear
{
    mCount = 0;
    std::make_heap(mObjs, mObjs + mCount, NodeLessThan);
    mHeapified = YES;
    
    // ARC
    [_storage removeAllObjects];
}

- (unsigned)count
{
    return mCount;
}

- (bool)empty
{
    return (mCount < 1);
}

- (void)addObject:(id)obj value:(float)val
{
    if (!mHeapified) return;
    
    mCount++;
    
    if (mCount > mCapacity)
    {
        mCapacity *= 2;
        mObjs = (struct JCPQNode *)realloc(mObjs, mCapacity * sizeof(*mObjs));
        if (mObjs == NULL) {
            NSLog(@"Error allocate");
            @throw [NSException exceptionWithName:@"AllocationError"
                                           reason:@"Cannot allocate memory"
                                         userInfo:nil];
        }
    }
    
    mObjs[mCount - 1].obj = obj;
    mObjs[mCount - 1].val = val;
    
    std::push_heap(mObjs, mObjs + mCount, NodeLessThan);
    
    // ARC
    [_storage addObject:obj];
}

- (id)pop
{
    if ([self empty]) return nil;
    
    std::pop_heap(mObjs, mObjs + mCount, NodeLessThan);
    mCount--;
    
    // ARC
    //[_storage removeObject:mObjs[mCount].obj];
    
    return mObjs[mCount].obj;
}

- (id)first
{
    if ([self empty]) return nil;
    
    return mObjs[0].obj;
}

@end
