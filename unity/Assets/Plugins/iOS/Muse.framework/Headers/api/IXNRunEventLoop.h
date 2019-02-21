// Copyright 2016 Interaxon, Inc.

#import <Foundation/Foundation.h>

#import "Muse/api/IXNEventLoop.h"

/**
 * An IXNEventLoop implementation using NSRunLoop
 */
@interface IXNRunEventLoop : NSObject <IXNEventLoop>
    /**
     * Initializes the object with the passed NSRunLoop.
     *
     * \param runLoop The NSRunLoop to use for the IXNEventLoop.
     */
- (instancetype)initWithRunLoop:(NSRunLoop *)runLoop;
@end
