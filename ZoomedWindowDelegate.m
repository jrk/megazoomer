//
//  ZoomedWindowDelegate.m
//  megazoomer
//
//  Created by Ian Henderson on 24 Mar 06.
//  Copyright 2006 Ian Henderson. All rights reserved.
//

#import "ZoomedWindowDelegate.h"
#import "ZoomableWindow.h"


@implementation ZoomedWindowDelegate

- (id)initWithRealDelegate:(id)delegate
{
    if ([super init] == nil) {
        return nil;
    }
    realDelegate = delegate;
    return self;
}

- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)proposedFrameSize
{
    return [sender frame].size;
}

- (void)windowWillClose:(NSNotification *)aNotification
{
    if ([realDelegate respondsToSelector:@selector(windowWillClose:)]) {
        [realDelegate windowWillClose:aNotification];
    }
    ZoomableWindow *window = [aNotification object];
    [window returnToOriginal];
    // "self" is dead at this point, so don't add anything here
}

- (id)realDelegate
{
    return realDelegate;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    NSMethodSignature *methodSignature = [super methodSignatureForSelector:aSelector];
    if (methodSignature == nil) {
        methodSignature = [realDelegate methodSignatureForSelector:aSelector];
    }
    return methodSignature;
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    SEL aSelector = [invocation selector];
    
    if ([realDelegate respondsToSelector:aSelector]) {
        [invocation invokeWithTarget:realDelegate];
    } else {
        [super forwardInvocation:invocation];
    }
}

@end
