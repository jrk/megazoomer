//
//  ZoomedWindowDelegate.h
//  megazoomer
//
//  Created by Ian Henderson on 24 Mar 06.
//  Copyright 2006 Ian Henderson. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ZoomedWindowDelegate : NSObject {
    id realDelegate;
}

- (id)initWithRealDelegate:(id)delegate;

- (id)realDelegate;

@end
