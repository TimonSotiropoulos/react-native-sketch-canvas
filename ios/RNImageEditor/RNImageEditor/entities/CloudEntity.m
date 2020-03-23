//;''
//  CloudEntity.m
//  RNImageEditor
//
//  Created by Daniel Siemens on 19.03.20
//

#import <Foundation/Foundation.h>
#import "base/MotionEntity.h"
#import "CloudEntity.h"
@import PocketSVG;

@implementation CloudEntity
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
                     entityId: (NSString *) entityId {
    
    CGFloat realParentCenterX = parentCenterX - width / 4;
    CGFloat realParentCenterY = parentCenterY - height / 4;
    CGFloat realWidth = width / 2;
    CGFloat realHeight = height / 2;
    
    self = [super initAndSetupWithParent:parentWidth
                            parentHeight:parentHeight
                           parentCenterX:realParentCenterX
                           parentCenterY:realParentCenterY
                       parentScreenScale:parentScreenScale
                                   width:realWidth
                                  height:realHeight
                          bordersPadding:bordersPadding
                             borderStyle:borderStyle
                       borderStrokeWidth:borderStrokeWidth
                       borderStrokeColor:borderStrokeColor
                       entityStrokeWidth:entityStrokeWidth
                       entityStrokeColor:entityStrokeColor
                       entityId: entityId];
    
    if (self) {
        self.MIN_SCALE = 0.3f;
    }
    
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"cloud" withExtension:@"svg"];
    if (url == nil) {
        NSLog(@"SKETCH ERR: url not found");
    } else {
        NSLog(@"%@", [url absoluteString]);
//        [self setSvgPaths:[SVGBezierPath pathsFromSVGAtURL:url]];
    }
    
    return self;
}

- (void)drawContent:(CGRect)rect withinContext:(CGContextRef)contextRef {
    CGFloat lineWidth = self.entityStrokeWidth / self.scale;
    CGContextSetLineWidth(contextRef, self.entityStrokeWidth / self.scale);
    CGContextSetStrokeColorWithColor(contextRef, [self.entityStrokeColor CGColor]);

    if ([self hasSvgPaths]) {
        CALayer *layer = [[CALayer alloc] init];
        for (UIBezierPath *path in self.svgPaths) {
            CAShapeLayer *shapeLayer = [[CAShapeLayer alloc] init];
            [shapeLayer setPath:[path CGPath]];
            [shapeLayer setFillColor:[self.entityStrokeColor CGColor]];
            [shapeLayer setLineWidth:lineWidth];
            [layer addSublayer:shapeLayer];
        }
        CGFloat wRatio = layer.frame.size.width / rect.size.width;
        CGFloat hRatio = layer.frame.size.height / rect.size.height;
        CATransform3D transform = CATransform3DMakeScale(wRatio, hRatio, 1.0);
        [layer setTransform:transform];
        [layer renderInContext:contextRef];
    }

    CGContextDrawPath(contextRef, kCGPathStroke);
}

@end
