//
//  ZoomableWindow.m
//  megazoomer
//
//  Created by Ian Henderson on 20.09.05.
//  Copyright 2005 Ian Henderson. All rights reserved.
//  Extended by Jonathan Ragan-Kelley, 2005-2013.
//

#import "MegaZoomer.h"
#import "ZoomableWindow.h"
#import <Carbon/Carbon.h>
#import <objc/runtime.h>
#import <objc/message.h>

// This shit is ugly
#define NOT_BIG 0
#define GETTING_BIG 1
#define TOTALLY_BIG 2

#define NOT_AFLOAT 0
#define IS_AFLOAT 1

typedef enum {
    MegaZoomNone = NOT_BIG,
    
    MegaZoomFullScreen,
    MegaZoomVertical,
    MegaZoomLeftHalf,
    MegaZoomRightHalf,
    
    MegaZoomModeMax
} MegaZoomMode;

static NSMutableDictionary *afloatnesses = nil;
static NSMutableDictionary *bignesses = nil;
static NSMutableDictionary *modes = nil;
static NSMutableDictionary *originalFrames = nil;
static NSMutableDictionary *originalBackgroundMovabilities = nil;

@interface NSWindow(ZoomableWindowSwizzle)
- (NSRect)__appkit_constrainFrameRect:(NSRect)r toScreen:(NSScreen *)s;
- (BOOL)__appkit_isZoomable;
- (BOOL)__appkit_isResizable;
- (BOOL)__appkit_isMiniaturizable;
- (BOOL)__appkit_validateMenuItem:(NSMenuItem *)item;
- (void)__appkit_zoom:sender;
- (void)__appkit_performZoom:sender;
- (void)__appkit_toggleToolbarShown:sender;
- (void)__appkit_setFrame:(NSRect)windowFrame display:(BOOL)displayViews;
- (void)__appkit_close;
@end

@implementation NSWindow(ZoomableWindow)

- (NSRect)megaZoomedFrame:(MegaZoomMode)mode
{
    NSRect oldContentRect = [self frame];
    NSRect screenRect = [[self screen] frame];
    NSRect newContentRect;
    
    assert(mode < MegaZoomModeMax);
    
    if (mode == MegaZoomFullScreen) {
        newContentRect = screenRect;
    } else if (mode == MegaZoomVertical || mode == MegaZoomLeftHalf || mode == MegaZoomRightHalf) {
        newContentRect.origin.y     = screenRect.origin.y;
        newContentRect.size.height  = screenRect.size.height;
        if (mode == MegaZoomVertical) {
            newContentRect.origin.x     = oldContentRect.origin.x;
            newContentRect.size.width   = oldContentRect.size.width;
        } else {
            newContentRect.size.width   = screenRect.size.width/2;
            if (mode == MegaZoomLeftHalf) {
                newContentRect.origin.x = 0;
            } else {
                newContentRect.origin.x = screenRect.size.width - newContentRect.size.width;
            }
        }
    }
    
    return [NSWindow frameRectForContentRect:newContentRect styleMask:[self styleMask]];
}

- (MegaZoomMode)mode
{
	return (MegaZoomMode)[[modes objectForKey:[NSNumber numberWithInt:[self windowNumber]]] intValue];
}

- (void)__megazoomer_close
{
    if ([self isBig]) {
        [self returnToOriginal];
    }
    [self __appkit_close];
}

- (void)__megazoomer_setFrame:(NSRect)windowFrame display:(BOOL)displayViews
{
	if (![self isBig]) {
		[self __appkit_setFrame:windowFrame display:displayViews];
	}
}

- (NSRect)__megazoomer_constrainFrameRect:(NSRect)frameRect toScreen:(NSScreen *)screen
{
	if ([self isBig] || [self isGettingBig]) {
		return [self megaZoomedFrame:[self mode]]; // TODO: fix this to read mode dict
	} else {
		return [self __appkit_constrainFrameRect:frameRect toScreen:screen];
	}
}

- (void)setBig:(int)big
{
	if (!bignesses) {
		bignesses = [[NSMutableDictionary alloc] init];
	}
	[bignesses setObject:[NSNumber numberWithInt:big] forKey:[NSNumber numberWithInt:[self windowNumber]]];
}

- (void)setAfloat:(int)afloat
{
	if (!afloatnesses) {
		afloatnesses = [[NSMutableDictionary alloc] init];
	}
	[afloatnesses setObject:[NSNumber numberWithInt:afloat] forKey:[NSNumber numberWithInt:[self windowNumber]]];
}

- (void)setMode:(MegaZoomMode)mode
{
	if (!modes) {
		modes = [[NSMutableDictionary alloc] init];
	}
	[modes setObject:[NSNumber numberWithInt:mode] forKey:[NSNumber numberWithInt:[self windowNumber]]];
}

- (void)returnToOriginal
{
	NSRect originalFrame = [[originalFrames objectForKey:[NSNumber numberWithInt:[self windowNumber]]] rectValue];
    [self setAfloat:NOT_AFLOAT];
    [self setBig:NOT_BIG];
    [self setMode:MegaZoomNone];
    [self setShowsResizeIndicator:YES];
    [self setFrame:originalFrame display:YES animate:YES];
    [self setMovableByWindowBackground:[[originalBackgroundMovabilities objectForKey:[NSNumber numberWithInt:[self windowNumber]]] boolValue]];
    if (![NSWindow anyBig]) {
        SetSystemUIMode(kUIModeNormal, 0);
    }
}

- (void)__megazoomer_toggleToolbarShown:sender
{
    if (![self isBig]) {
        [self __appkit_toggleToolbarShown:sender];
    }
}

- (BOOL)__megazoomer_validateMenuItem:(NSMenuItem *)item
{
    if ([self isBig] && ([item action] == @selector(toggleToolbarShown:) || [item action] == @selector(performZoom:) )) {
        return NO;
    }
    if ([self respondsToSelector:@selector(__appkit_validateMenuItem:)]) {
        return [self __appkit_validateMenuItem:item];
    }
    return YES;
}

#define NOT_WHEN_BIG(method) \
- (BOOL)__megazoomer_ ## method \
{ \
    if ([self isBig]) { \
        return NO; \
    } \
    return [self __appkit_ ## method]; \
}

NOT_WHEN_BIG(isResizable)
NOT_WHEN_BIG(isMiniaturizable)
NOT_WHEN_BIG(isZoomable)

- (void)__megazoomer_zoom:sender
{
    if (![self isBig]) {
        [self __appkit_zoom:sender];
    }
}

- (void)__megazoomer_performZoom:sender
{
    if (![self isBig]) {
        [self __appkit_performZoom:sender];
    }
}

- (BOOL)isMegaZoomable
{
    return [self __appkit_isZoomable] || ([MegaZoomer zoomMenuItem] != nil && [self validateMenuItem:[MegaZoomer zoomMenuItem]]);
}

- (void)megaZoom:(MegaZoomMode)mode
{
    NSLog(@"jrk was here!");
    if (![self isMegaZoomable]) {
        return;
    }
    if (![NSWindow anyBig]) {
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
    
    [self setBig:GETTING_BIG];
    [self setMode:mode];
    [self setShowsResizeIndicator:NO];
    [self setFrame:[self megaZoomedFrame:mode] display:YES animate:YES];
    [self setMovableByWindowBackground:NO];
    [self setBig:TOTALLY_BIG];
}

- (void)toggleMegaZoomFull
{
    [self toggleMegaZoom:MegaZoomFullScreen];
}

- (void)toggleMegaZoomVertical
{
    [self toggleMegaZoom:MegaZoomVertical];
}

- (void)toggleMegaZoomLeftHalf
{
    [self toggleMegaZoom:MegaZoomLeftHalf];
}

- (void)toggleMegaZoomRightHalf
{
    [self toggleMegaZoom:MegaZoomRightHalf];
}

- (void)toggleMegaZoom:(MegaZoomMode)mode
{
    // TODO: slightly awkward metaphor for now where ALL megazoom operations undo if ANY are set (there is just one "big" bit), rather than switching modes directly from one zoom to another
    if ([self isBig]) {
        [self returnToOriginal];
    } else {
        [self megaZoom:mode];
    }
}

- (void)toggleAfloat
{
    if ([self isAfloat]) {
        [self setAfloat:NOT_AFLOAT];
		[self setLevel:NSNormalWindowLevel];
    } else {
        [self setAfloat:IS_AFLOAT];
		[self setLevel:NSFloatingWindowLevel];
    }
}


- (BOOL)isAfloat
{
	return [[afloatnesses objectForKey:[NSNumber numberWithInt:[self windowNumber]]] intValue] == IS_AFLOAT;
}

- (BOOL)isBig
{
	return [[bignesses objectForKey:[NSNumber numberWithInt:[self windowNumber]]] intValue] == TOTALLY_BIG;
}
- (BOOL)isGettingBig
{
	return [[bignesses objectForKey:[NSNumber numberWithInt:[self windowNumber]]] intValue] == GETTING_BIG;
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


#if __LP64__

+ (void)swizzle:(Method)custom
{
    SEL custom_sel = method_getName(custom);
    NSString *name = NSStringFromSelector(custom_sel);
    // __megazoomer_ <- 13 characters
    name = [name substringFromIndex:13];
    SEL old_sel = NSSelectorFromString(name);
    SEL new_sel = NSSelectorFromString([NSString stringWithFormat:@"__appkit_%@", name]);
    
    Method old = class_getInstanceMethod([self class], old_sel);
    
    if (old == NULL) {
        return;
    }
    
    class_addMethod([self class], new_sel, method_getImplementation(old), method_getTypeEncoding(old));
    method_exchangeImplementations(custom, old);
}

+ (void)swizzleZoomerMethods
{
    unsigned int count;
    Method *methods = class_copyMethodList([self class], &count);
    
    int i;
    for (i = 0; i < count; i++) {
        NSString *name = NSStringFromSelector(method_getName(methods[i]));
        if ([name hasPrefix:@"__megazoomer_"]) {
            [self swizzle:methods[i]];
        }
    }
    
    free(methods);
}

#else

+ (void)swizzle:(struct objc_method *)custom
{
    SEL custom_sel = custom->method_name;
    NSString *name = NSStringFromSelector(custom_sel);
    // __megazoomer_ <- 13 characters
    name = [name substringFromIndex:13];
    SEL old_sel = NSSelectorFromString(name);
    SEL new_sel = NSSelectorFromString([NSString stringWithFormat:@"__appkit_%@", name]);
    
    struct objc_method *old = class_getInstanceMethod([self class], old_sel);
    
    if (old == NULL) {
        return;
    }
    
    custom->method_name = old_sel;
    old->method_name = new_sel;
}

+ (void)swizzleZoomerMethods
{
    void *iter = 0;
    struct objc_method_list *mlist;
    while ((mlist = class_nextMethodList([self class], &iter))) {
        int i;
        for (i=0; i<mlist->method_count; i++) {
            struct objc_method *m = mlist->method_list + i;
            NSString *name = NSStringFromSelector(m->method_name);
            if ([name hasPrefix:@"__megazoomer_"]) {
                [self swizzle:m];
            }
        }
    }
}

#endif

@end
