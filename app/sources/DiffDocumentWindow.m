//
//  DiffDocumentWindow.m
//  HexFiend_2
//
//  Copyright 2010 ridiculous_fish. All rights reserved.
//

#if !__has_feature(objc_arc)
#error ARC required
#endif

#import "DiffDocumentWindow.h"
#import "DiffDocument.h"

@implementation DiffDocumentWindow

- (void)sendEvent:(NSEvent *)event {
    /* Give our DiffDocument a chance to handle the event. */
    if (! [(DiffDocument *)[self delegate] handleEvent:event]) {
        [super sendEvent:event];
    }
}

@end
