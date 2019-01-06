//
//  HFColumnRepresenter.m
//  HexFiend_2
//
//  Created by Kevin Wojniak on 1/1/19.
//  Copyright © 2019 ridiculous_fish. All rights reserved.
//

#import "HFColumnRepresenter.h"
#import <HexFiend/HFHexGlyphTable.h>

static const CGFloat kShadowHeight = 6;

@interface HFColumnView : NSView

@property (weak) HFColumnRepresenter *representer;
@property BOOL registeredForAppNotifications;
@property CGFloat lineCountingWidth;
@property HFHexGlyphTable *glyphTable;

@end

@implementation HFColumnView

- (void)dealloc {
    HFUnregisterViewForWindowAppearanceChanges(self, self.registeredForAppNotifications);
}

- (void)windowDidChangeKeyStatus:(NSNotification *)note {
    USE(note);
    [self setNeedsDisplay:YES];
}

- (void)viewDidMoveToWindow {
    HFRegisterViewForWindowAppearanceChanges(self, @selector(windowDidChangeKeyStatus:), !self.registeredForAppNotifications);
    self.registeredForAppNotifications = YES;
    [super viewDidMoveToWindow];
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow {
    HFUnregisterViewForWindowAppearanceChanges(self, NO);
    [super viewWillMoveToWindow:newWindow];
}

- (NSColor *)borderColor {
    if (@available(macOS 10.14, *)) {
        return [NSColor separatorColor];
    }
    return [NSColor darkGrayColor];
}

- (NSColor *)backgroundColor {
    if (HFDarkModeEnabled()) {
        return [NSColor colorWithCalibratedWhite:0.13 alpha:1];
    }
    return [NSColor colorWithCalibratedWhite:0.87 alpha:1];
}

- (NSColor *)foregroundColor {
    if (@available(macOS 10.10, *)) {
        return [NSColor secondaryLabelColor];
    } else {
        return [NSColor colorWithCalibratedWhite:(CGFloat).1 alpha:(CGFloat).8];
    }
}

- (NSRect)offsetBounds {
    NSRect bounds = self.bounds;
    bounds.origin.x += self.lineCountingWidth;
    bounds.size.width -= self.lineCountingWidth;
    return bounds;
}

- (void)drawBackground {
    [self.backgroundColor set];
    NSRectFillUsingOperation(self.bounds, NSCompositeSourceOver);

    const NSRect bounds = self.offsetBounds;
#if 1
    [self.borderColor set];
    NSRect lineRect = bounds;
    lineRect.origin.x -= 1; lineRect.size.width += 1;
    lineRect.size.height = 1;
    lineRect.origin.y = 0;
    NSRectFillUsingOperation(lineRect, NSCompositeSourceOver);
#endif
}

- (void)drawText {
    const NSRect bounds = self.offsetBounds;

    HFController *controller = self.representer.controller;
    CTFontRef font = (__bridge CTFontRef)controller.font;
    const CGFloat descent = ceil(fabs(CTFontGetDescent(font)));
    const NSUInteger bytesPerColumn = controller.bytesPerColumn;
    const NSUInteger bytesPerLine = controller.bytesPerLine;
    const CGFloat lineHeight = controller.lineHeight;
    const CGFloat horizontalContainerInset = 4; // matches what HFRepresenterTextView uses
    const HFHexGlyphTable *glyphTable = self.glyphTable;
    const CGFloat advancement = glyphTable.advancement;
    const CGGlyph *table = glyphTable.table;
    const size_t numGlyphs = bytesPerLine*2;

    NSUInteger bytesInColumn = 0;
    CGFloat x = bounds.origin.x + horizontalContainerInset;
    CGGlyph glyphs[numGlyphs];
    CGPoint positions[numGlyphs];
    for (unsigned i = 0; i < (unsigned)bytesPerLine; i++) {
        const size_t offset0 = i*2;
        const size_t offset1 = offset0 + 1;
        glyphs[offset0] = table[i / 16];
        glyphs[offset1] = table[i % 16];
        positions[offset0].y = descent;
        positions[offset1].y = descent;
        positions[offset0].x = x;
        positions[offset1].x = x + advancement;
        x += (advancement * 2);

        ++bytesInColumn;
        if (bytesInColumn == bytesPerColumn) {
            x += advancement;
            bytesInColumn = 0;
        }
    }

    [self.foregroundColor set];
    CGContextRef ctx = HFGraphicsGetCurrentContext();
    CTFontDrawGlyphs(font, glyphs, positions, numGlyphs, ctx);
}

- (void)drawRect:(NSRect __unused)dirtyRect {
    [self drawBackground];
    [self drawText];
}

@end

@implementation HFColumnRepresenter

- (NSView *)createView {
    NSRect frame = NSMakeRect(0, 0, 10, 16/*HFLineHeightForFont(self.controller.font)*/);
    HFColumnView *result = [[HFColumnView alloc] initWithFrame:frame];
    result.representer = self;
    result.autoresizingMask = NSViewWidthSizable;
    return result;
}

+ (NSPoint)defaultLayoutPosition {
    return NSMakePoint(0, 1);
}

- (void)controllerDidChange:(HFControllerPropertyBits)bits {
    if (bits & HFControllerFont) {
        HFColumnView *view = self.view;
        view.glyphTable = [[HFHexGlyphTable alloc] initWithFont:self.controller.font];
        [view setNeedsDisplay:YES];
    }
    if (bits & (HFControllerFont|HFControllerLineHeight|HFControllerBytesPerLine|HFControllerBytesPerColumn)) {
        HFColumnView *view = self.view;
        [view setNeedsDisplay:YES];
    }
}

- (void)setLineCountingWidth:(CGFloat)width {
    HFColumnView *view = self.view;
    if (view.lineCountingWidth != width) {
        view.lineCountingWidth = width;
        [view setNeedsDisplay:YES];
    }
}

@end
