//
//  ZoomableWindow.m
//  megazoomer
//
//  Created by Ian Henderson on 20.09.05.
//  Copyright 2005 Ian Henderson. All rights reserved.
//

#import "MegaZoomer.h"
#import "ZoomableWindow.h"
#import "ZoomedWindowDelegate.h"
#import <Carbon/Carbon.h>

static NSMutableDictionary *bignesses = nil;
static NSMutableDictionary *originalFrames = nil;
static NSMutableDictionary *originalBackgroundMovabilities = nil;

@implementation ZoomableWindow

- (NSRect)constrainFrameRect:(NSRect)frameRect toScreen:(NSScreen *)screen
{
	if ([self isBig]) {
		return frameRect;
	} else {
		return [super constrainFrameRect:frameRect toScreen:screen];
	}
}

- (void)setBig:(BOOL)big
{
	if (!bignesses) {
		bignesses = [[NSMutableDictionary alloc] init];
	}
	[bignesses setObject:[NSNumber numberWithBool:big] forKey:[NSNumber numberWithInt:[self windowNumber]]];
}

- (void)returnToOriginal
{
	NSRect originalFrame = [[originalFrames objectForKey:[NSNumber numberWithInt:[self windowNumber]]] rectValue];
    id fakeDelegate = [self delegate];
    if ([fakeDelegate respondsToSelector:@selector(realDelegate)]) {
        [self setDelegate:[fakeDelegate realDelegate]];
        [fakeDelegate release];
    }
    [self setBig:NO];
    [self setShowsResizeIndicator:YES];
    [self setFrame:originalFrame display:YES animate:YES];
    [self setMovableByWindowBackground:[[originalBackgroundMovabilities objectForKey:[NSNumber numberWithInt:[self windowNumber]]] boolValue]];
    if (![ZoomableWindow anyBig]) {
        SetSystemUIMode(kUIModeNormal, 0);
    }
}

- (void)toggleToolbarShown:sender
{
    if (![self isBig]) {
        [super toggleToolbarShown:sender];
    }
}

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
    if ([self isBig] && ([item action] == @selector(toggleToolbarShown:) || [item action] == @selector(performZoom:) )) {
        return NO;
    }
    if ([super respondsToSelector:@selector(validateMenuItem:)]) {
        return [super validateMenuItem:item];
    }
    return YES;
}

#define NOT_WHEN_BIG(method) \
- (BOOL)method \
{ \
    if ([self isBig]) { \
        return NO; \
    } \
    return [super method]; \
}

NOT_WHEN_BIG(isResizable)
NOT_WHEN_BIG(isMiniaturizable)
NOT_WHEN_BIG(isZoomable)

- (void)zoom:sender
{
    if (![self isBig]) {
        [super zoom:sender];
    }
}

- (void)performZoom:sender
{
    if (![self isBig]) {
        [super performZoom:sender];
    }
}

- (BOOL)isMegaZoomable
{
    return [super isZoomable] || ([MegaZoomer zoomMenuItem] != nil && [self validateMenuItem:[MegaZoomer zoomMenuItem]]);
}

- (NSRect)megaZoomedFrame
{
    NSRect newContentRect = [[self screen] frame];
    return [NSWindow frameRectForContentRect:newContentRect styleMask:[self styleMask]];
}

- (void)megaZoom
{
    if (![self isMegaZoomable]) {
        return;
    }
    if (![ZoomableWindow anyBig]) {
        SetSystemUIMode(kUIModeAllHidden, kUIOptionAutoShowMenuBar);
    }
	if (!originalFrames) {
		originalFrames = [[NSMutableDictionary alloc] init];
	}
	[originalFrames setObject:[NSValue valueWithRect:[self frame]] forKey:[NSNumber numberWithInt:[self windowNumber]]];
    
    if (!originalBackgroundMovabilities) {
        originalBackgroundMovabilities = [[NSMutableDictionary alloc] init];
    }
	[originalBackgroundMovabilities setObject:[NSNumber numberWithBool:[self isMovableByWindowBackground]] forKey:[NSNumber numberWithInt:[self windowNumber]]];
    
    [self setBig:YES];
    [self setShowsResizeIndicator:NO];
    [self setFrame:[self megaZoomedFrame] display:YES animate:YES];
    [self setMovableByWindowBackground:NO];
    
    id realDelegate = [self delegate];
    [self setDelegate:[[ZoomedWindowDelegate alloc] initWithRealDelegate:realDelegate]];
}

- (void)toggleMegaZoom
{
    if ([self isBig]) {
        [self returnToOriginal];
    } else {
        [self megaZoom];
    }
}

- (BOOL)isBig
{
	return [[bignesses objectForKey:[NSNumber numberWithInt:[self windowNumber]]] boolValue];
}

+ (BOOL)anyBig
{
    NSEnumerator *bignessEnumerator = [[bignesses allValues] objectEnumerator];
    NSNumber *isBig;
    while ((isBig = [bignessEnumerator nextObject]) != nil) {
        if ([isBig boolValue]) {
            return YES;
        }
    }
    return NO;
}

@end
