//
//  ZoomableWindow.h
//  megazoomer
//
//  Created by Ian Henderson on 20.09.05.
//  Copyright 2005 Ian Henderson. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ZoomableWindow : NSWindow {

}

+ (BOOL)anyBig;

- (BOOL)isMegaZoomable;

- (BOOL)isBig;

- (void)megaZoom;
- (void)returnToOriginal;

- (void)toggleMegaZoom;

- (NSRect)megaZoomedFrame;

@end
