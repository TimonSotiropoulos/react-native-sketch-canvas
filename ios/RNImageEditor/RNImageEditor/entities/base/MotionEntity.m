//
//  MotionEntity.m
//  RNImageEditor
//
//  Created by Thomas Steinbrüchel on 24.10.18.
//  Copyright © 2018 Terry. All rights reserved.
//

#import "MotionEntity.h"

@implementation MotionEntity
{
}

- (instancetype)initAndSetupWithParent: (NSInteger)parentWidth
                          parentHeight: (NSInteger)parentHeight
                         parentCenterX: (CGFloat)parentCenterX
                         parentCenterY: (CGFloat)parentCenterY
                     parentScreenScale: (CGFloat)parentScreenScale
                                 width: (NSInteger)width
                                height: (NSInteger)height
                        bordersPadding: (CGFloat)bordersPadding
                           borderStyle: (enum BorderStyle)borderStyle
                     borderStrokeWidth: (CGFloat)borderStrokeWidth
                     borderStrokeColor: (UIColor *)borderStrokeColor
                     entityStrokeWidth: (CGFloat)entityStrokeWidth
                     entityStrokeColor: (UIColor *)entityStrokeColor
                     entityId: (NSString *)entityId {

    self = [super initWithFrame:CGRectMake(parentCenterX, parentCenterY, width, height)];

    if (self) {
        self.parentWidth = parentWidth;
        self.parentHeight = parentHeight;
        self.isSelected = false;
        self.centerPoint = CGPointMake(parentCenterX, parentCenterY);
        self.scale = 1.0;
        self.scaleX = 1.0;
        self.scaleY = 1.0;
        self.MIN_SCALE = 0.15f;
        self.MAX_SCALE = 4.5f;
        self.parentScreenScale = parentScreenScale;
        self.borderStyle = borderStyle;
        self.borderStrokeWidth = borderStrokeWidth;
        self.bordersPadding = bordersPadding;
        self.borderStrokeColor = borderStrokeColor;
        self.entityStrokeWidth = entityStrokeWidth;
        self.entityStrokeColor = entityStrokeColor;
        self.entityId = entityId;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (BOOL)isEntitySelected {
    return self.isSelected;
}

- (BOOL)entityHasId:(NSString *)entityId {
    return [self.entityId isEqualToString: entityId];
}

- (BOOL)isPointInEntity:(CGPoint)point {
    return CGRectContainsPoint(self.frame, point);
}

- (void)setIsSelected:(BOOL)isSelected {
    _isSelected = isSelected;
}

- (void)rotateEntityBy:(CGFloat)rotationInRadians {
    [self setTransform:CGAffineTransformRotate(self.transform, rotationInRadians)];
}

- (void)moveEntityTo:(CGPoint)locationDiff {
    [self setTransform:CGAffineTransformTranslate(self.transform, locationDiff.x, locationDiff.y)];
    self.centerPoint = self.center;
}

- (void)scaleEntityBy:(CGFloat)newScale {
    CGFloat absoluteScale = self.scale * newScale;
    if (absoluteScale >= self.MIN_SCALE && absoluteScale <= self.MAX_SCALE) {
        self.scale *= newScale;
        [self setTransform:CGAffineTransformScale(self.transform, newScale, newScale)];
        [self setContentScaleFactor:self.parentScreenScale * self.scale]; // Make it sharp :-)
    }
}

- (void)scaleEntityByX:(CGFloat)xScale y:(CGFloat)yScale {
    CGFloat xScaleAbs = self.scale * xScale;
    CGFloat yScaleAbs = self.scale * yScale;
    if (xScaleAbs >= self.MIN_SCALE && yScaleAbs >= self.MIN_SCALE && xScaleAbs <= self.MAX_SCALE && yScaleAbs <= self.MAX_SCALE) {
        self.scaleX *= xScale;
        self.scaleY *= yScale;
        [self setTransform:CGAffineTransformScale(self.transform, xScale, yScale)];
        [self setContentScaleFactor:self.parentScreenScale * ((self.scaleX + self.scaleY) / 2)]; // Make it sharp :-)
    }
}

- (void)updateStrokeSettings: (enum BorderStyle)borderStyle
           borderStrokeWidth: (CGFloat)borderStrokeWidth
           borderStrokeColor: (UIColor *)borderStrokeColor
           entityStrokeWidth: (CGFloat)entityStrokeWidth
           entityStrokeColor: (UIColor *)entityStrokeColor {

    if (self.isSelected) {
        self.borderStyle = borderStyle;
        self.borderStrokeWidth = borderStrokeWidth;
        self.borderStrokeColor = borderStrokeColor;
        self.entityStrokeWidth = entityStrokeWidth;
        self.entityStrokeColor = entityStrokeColor;
    }
}

- (void)drawRect:(CGRect)rect {
    CGContextRef contextRef = UIGraphicsGetCurrentContext();
    if (contextRef) {
        CGContextSaveGState(contextRef);
        if ([self respondsToSelector:@selector(drawContent:withinContext:)]) {
            [self drawContent:rect withinContext:contextRef];
        }
        CGContextRestoreGState(contextRef);
    }

    // Draw Border
    if (self.isSelected) {
        if (contextRef) {
            CGContextSaveGState(contextRef);

            CGContextSetLineWidth(contextRef, self.borderStrokeWidth / self.scale);
            CGContextSetStrokeColorWithColor(contextRef, [self.borderStrokeColor CGColor]);
            if (self.borderStyle == DASHED) {
                CGFloat dashPattern[]= {2.5, 2.5};
                CGContextSetLineDash(contextRef, 0.0, dashPattern, 2);
            }
            CGContextStrokeRect(contextRef, rect);

            CGContextRestoreGState(contextRef);
        }
    }
}

- (void)drawContent:(CGRect)rect withinContext:(CGContextRef)contextRef {
    NSAssert(NO, @"This is an abstract method and should be overridden");
}

@end
