//
//  MegaZoomer.m
//  megazoomer
//
//  Created by Ian Henderson on 20.09.05.
//  Copyright 2005 Ian Henderson. All rights reserved.
//

#import "MegaZoomer.h"
#import "ZoomableWindow.h"

@interface NSMenu(TopSecretMethods)

- (NSString *)_menuName;

@end

@implementation MegaZoomer

+ (NSMenu *)windowMenu
{
    NSMenu *mainMenu = [NSApp mainMenu];
    NSEnumerator *menuEnumerator = [[mainMenu itemArray] objectEnumerator];
    NSMenu *windowMenu;
    while ((windowMenu = [[menuEnumerator nextObject] submenu]) != nil) {
        // Let's hope Apple doesn't change this...
        if ([[windowMenu _menuName] isEqualToString:@"NSWindowsMenu"]) {
            return windowMenu;
        }
    }
    return windowMenu;
}

+ (NSMenuItem *)zoomMenuItem
{
    NSMenu *windowMenu = [self windowMenu];
    
    int zoomItemIndex = [windowMenu indexOfItemWithTarget:nil andAction:@selector(performZoom:)];
    NSMenuItem *zoomMenuItem = nil;
    if (zoomItemIndex >= 0) {
        [windowMenu itemAtIndex:zoomItemIndex];
    }
    if (zoomMenuItem == nil) {
        zoomMenuItem = [windowMenu itemWithTitle:@"Zoom"];
    }
    return zoomMenuItem;
}

- (void)insertMenu
{
    NSMenu *windowMenu = [[self class] windowMenu];
    
    NSMenuItem *item = [[[NSMenuItem alloc] init] autorelease];
    [item setRepresentedObject:self]; // So I can validate it without having to check the title.
    [item setTitle:@"Mega Zoom: Vertical"];
    [item setAction:@selector(megaZoomVertical:)];
    [item setTarget:self];
    [item setKeyEquivalent:@"\n"];
    [item setKeyEquivalentModifierMask:NSCommandKeyMask];
    [windowMenu insertItem:item atIndex:[windowMenu indexOfItemWithTarget:nil andAction:@selector(performZoom:)]+1];
    
    item = [[[NSMenuItem alloc] init] autorelease];
    [item setRepresentedObject:self]; // So I can validate it without having to check the title.
    [item setTitle:@"Toggle Menu"];
    [item setAction:@selector(toggleHideMenu:)];
    [item setTarget:self];
    [windowMenu insertItem:item atIndex:[windowMenu indexOfItemWithTarget:nil andAction:@selector(performZoom:)]+1];

    item = [[[NSMenuItem alloc] init] autorelease];
    [item setRepresentedObject:self]; // So I can validate it without having to check the title.
    [item setTitle:@"Mega Zoom: Right Half"];
    [item setAction:@selector(megaZoomRightHalf:)];
    [item setTarget:self];
    [windowMenu insertItem:item atIndex:[windowMenu indexOfItemWithTarget:nil andAction:@selector(performZoom:)]+1];
    
    item = [[[NSMenuItem alloc] init] autorelease];
    [item setRepresentedObject:self]; // So I can validate it without having to check the title.
    [item setTitle:@"Mega Zoom: Left Half"];
    [item setAction:@selector(megaZoomLeftHalf:)];
    [item setTarget:self];
    [windowMenu insertItem:item atIndex:[windowMenu indexOfItemWithTarget:nil andAction:@selector(performZoom:)]+1];
    
    item = [[[NSMenuItem alloc] init] autorelease];
    [item setRepresentedObject:self]; // So I can validate it without having to check the title.
    [item setTitle:@"Mega Zoom: Full"];
    [item setAction:@selector(megaZoomFull:)];
    [item setTarget:self];
    [item setKeyEquivalent:@"\n"];
    [item setKeyEquivalentModifierMask:NSCommandKeyMask|NSShiftKeyMask];
    [windowMenu insertItem:item atIndex:[windowMenu indexOfItemWithTarget:nil andAction:@selector(performZoom:)]+1];
    
    item = [[[NSMenuItem alloc] init] autorelease];
    [item setRepresentedObject:self]; // So I can validate it without having to check the title.
    [item setTitle:@"Mega Zoom: Toggle Afloat"];
    [item setAction:@selector(toggleAfloat:)];
    [item setTarget:self];
    [windowMenu insertItem:item atIndex:[windowMenu indexOfItemWithTarget:nil andAction:@selector(performZoom:)]+1];
}

+ (BOOL)megazoomerWorksHere
{
    static NSSet *doesntWork = nil;
    if (doesntWork == nil) {
        doesntWork = [[NSSet alloc] init]; // add bundles that don't work
    }
    return ![doesntWork containsObject:[[NSBundle mainBundle] bundleIdentifier]];
}

+ (void)load
{
    static MegaZoomer *zoomer = nil;
    if (zoomer == nil) {
        zoomer = [[self alloc] init];
        if ([self megazoomerWorksHere]) {
            [zoomer insertMenu];
            [NSWindow swizzleZoomerMethods];
        }
    }
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)item
{
    return [[NSApp keyWindow] isMegaZoomable];
}

- (void)toggleHideMenu:sender
{
    [[NSApp keyWindow] toggleHideMenu];
}


- (void)megaZoomLeftHalf:sender
{
    [[NSApp keyWindow] toggleMegaZoomLeftHalf];
}

- (void)megaZoomRightHalf:sender
{
    [[NSApp keyWindow] toggleMegaZoomRightHalf];
}

- (void)megaZoomVertical:sender
{
    [[NSApp keyWindow] toggleMegaZoomVertical];
}

- (void)megaZoomFull:sender
{
    [[NSApp keyWindow] toggleMegaZoomFull];
}

- (void)toggleAfloat:sender
{
    [[NSApp keyWindow] toggleAfloat];
}

@end
