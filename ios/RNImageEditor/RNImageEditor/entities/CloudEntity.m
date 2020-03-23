//;''
//  CloudEntity.m
//  RNImageEditor
//
//  Created by Daniel Siemens on 19.03.20
//

#import <Foundation/Foundation.h>
#import "base/MotionEntity.h"
#import "CloudEntity.h"

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
    
    return self;
}

- (UIBezierPath *)getPath {
    UIBezierPath *path = [[UIBezierPath alloc] init];
    [path moveToPoint:CGPointMake(408.2, 68.0)];
//    shape.addCurve(to: CGPoint(x: 446.7, y: 106.5), controlPoint1: CGPoint(x: 21.2, y: 0), controlPoint2: CGPoint(x: 38.5, y: 17.3))
    [path addCurveToPoint:CGPointMake(446.7, 106.5) controlPoint1:CGPointMake(21.2, 0) controlPoint2:CGPointMake(38.5, 17.3)];
//    shape.addCurve(to: CGPoint(x: 431.8, y: 136.9), controlPoint1: CGPoint(x: 0, y: 12), controlPoint2: CGPoint(x: -5.4, y: 23))
    [path addCurveToPoint:CGPointMake(431.8, 136.9) controlPoint1:CGPointMake(0, 12) controlPoint2:CGPointMake(-5.4, 23)];
//    shape.addLine(to: CGPoint(x: 421.8, y: 144.7))
    [path addLineToPoint:CGPointMake(421.8, 144.7)];
//    shape.addLine(to: CGPoint(x: 431.7, y: 152.6))
    [path addLineToPoint:CGPointMake(431.7, 152.7)];
//    shape.addCurve(to: CGPoint(x: 446.1, y: 182.6), controlPoint1: CGPoint(x: 9.1, y: 7.4), controlPoint2: CGPoint(x: 14.4, y: 18.3))
    [path addCurveToPoint:CGPointMake(446.1, 182.6) controlPoint1:CGPointMake(9.1, 7.4) controlPoint2:CGPointMake(14.4, 18.3)];
//    shape.addCurve(to: CGPoint(x: 431.8, y: 212.5), controlPoint1: CGPoint(x: 0, y: 11.7), controlPoint2: CGPoint(x: -5.2, y: 22.5))
    [path addCurveToPoint:CGPointMake(431.8, 212.5) controlPoint1:CGPointMake(0, 11.7) controlPoint2:CGPointMake(-5.2, 22.5)];
//    shape.addLine(to: CGPoint(x: 422.2, y: 220.3))
    [path addLineToPoint:CGPointMake(422.2, 220.3)];
//    shape.addLine(to: CGPoint(x: 431.8, y: 228.1))
    [path addLineToPoint:CGPointMake(431.8, 228.1)];
//    shape.addCurve(to: CGPoint(x: 446.1, y: 258), controlPoint1: CGPoint(x: 9.1, y: 7.4), controlPoint2: CGPoint(x: 14.3, y: 18.2))
//    shape.addCurve(to: CGPoint(x: 431.8, y: 287.9), controlPoint1: CGPoint(x: 0, y: 11.7), controlPoint2: CGPoint(x: -5.2, y: 22.5))
//    shape.addLine(to: CGPoint(x: 422.2, y: 295.7))
//    shape.addLine(to: CGPoint(x: 431.8, y: 303.5))
//    shape.addCurve(to: CGPoint(x: 446.1, y: 333.4), controlPoint1: CGPoint(x: 9.1, y: 7.3), controlPoint2: CGPoint(x: 14.3, y: 18.2))
//    shape.addCurve(to: CGPoint(x: 433, y: 362.3), controlPoint1: CGPoint(x: 0, y: 11), controlPoint2: CGPoint(x: -4.8, y: 21.6))
//    shape.addLine(to: CGPoint(x: 424.3, y: 369.9))
//    shape.addLine(to: CGPoint(x: 433.1, y: 377.4))
//    shape.addCurve(to: CGPoint(x: 446.7, y: 406.7), controlPoint1: CGPoint(x: 8.6, y: 7.3), controlPoint2: CGPoint(x: 13.6, y: 18))
//    shape.addCurve(to: CGPoint(x: 408.2, y: 445.2), controlPoint1: CGPoint(x: 0, y: 21.2), controlPoint2: CGPoint(x: -17.3, y: 38.5))
//    shape.addCurve(to: CGPoint(x: 378.3, y: 430.9), controlPoint1: CGPoint(x: -11.7, y: 0), controlPoint2: CGPoint(x: -22.5, y: -5.2))
//    shape.addLine(to: CGPoint(x: 370.5, y: 421.3))
//    shape.addLine(to: CGPoint(x: 362.7, y: 430.9))
//    shape.addCurve(to: CGPoint(x: 332.8, y: 445.2), controlPoint1: CGPoint(x: -7.3, y: 9.1), controlPoint2: CGPoint(x: -18.2, y: 14.3))
//    shape.addCurve(to: CGPoint(x: 302.9, y: 430.9), controlPoint1: CGPoint(x: -11.7, y: 0), controlPoint2: CGPoint(x: -22.5, y: -5.2))
//    shape.addLine(to: CGPoint(x: 295.1, y: 421.3))
//    shape.addLine(to: CGPoint(x: 287.3, y: 430.9))
//    shape.addCurve(to: CGPoint(x: 257.4, y: 445.2), controlPoint1: CGPoint(x: -7.3, y: 9.1), controlPoint2: CGPoint(x: -18.2, y: 14.3))
//    shape.addCurve(to: CGPoint(x: 227.5, y: 430.9), controlPoint1: CGPoint(x: -11.7, y: 0), controlPoint2: CGPoint(x: -22.5, y: -5.2))
//    shape.addLine(to: CGPoint(x: 219.7, y: 421.3))
//    shape.addLine(to: CGPoint(x: 211.9, y: 430.9))
//    shape.addCurve(to: CGPoint(x: 182, y: 445.2), controlPoint1: CGPoint(x: -7.4, y: 9.1), controlPoint2: CGPoint(x: -18.2, y: 14.3))
//    shape.addCurve(to: CGPoint(x: 152.1, y: 430.9), controlPoint1: CGPoint(x: -11.7, y: 0), controlPoint2: CGPoint(x: -22.5, y: -5.2))
//    shape.addLine(to: CGPoint(x: 144.3, y: 421.3))
//    shape.addLine(to: CGPoint(x: 136.5, y: 430.9))
//    shape.addCurve(to: CGPoint(x: 106.6, y: 445.2), controlPoint1: CGPoint(x: -7.3, y: 9.1), controlPoint2: CGPoint(x: -18.2, y: 14.3))
//    shape.addCurve(to: CGPoint(x: 68.1, y: 406.7), controlPoint1: CGPoint(x: -21.2, y: 0), controlPoint2: CGPoint(x: -38.5, y: -17.3))
//    shape.addCurve(to: CGPoint(x: 80.7, y: 378.3), controlPoint1: CGPoint(x: 0, y: -10.8), controlPoint2: CGPoint(x: 4.6, y: -21.1))
//    shape.addLine(to: CGPoint(x: 89.3, y: 370.5))
//    shape.addLine(to: CGPoint(x: 80.3, y: 363.2))
//    shape.addCurve(to: CGPoint(x: 66.2, y: 333.4), controlPoint1: CGPoint(x: -9, y: -7.3), controlPoint2: CGPoint(x: -14.1, y: -18.2))
//    shape.addCurve(to: CGPoint(x: 80.5, y: 303.5), controlPoint1: CGPoint(x: 0, y: -11.7), controlPoint2: CGPoint(x: 5.2, y: -22.5))
//    shape.addLine(to: CGPoint(x: 90.1, y: 295.7))
//    shape.addLine(to: CGPoint(x: 80.5, y: 287.9))
//    shape.addCurve(to: CGPoint(x: 66.2, y: 258), controlPoint1: CGPoint(x: -9.1, y: -7.3), controlPoint2: CGPoint(x: -14.3, y: -18.2))
//    shape.addCurve(to: CGPoint(x: 80.5, y: 228.1), controlPoint1: CGPoint(x: 0, y: -11.7), controlPoint2: CGPoint(x: 5.2, y: -22.5))
//    shape.addLine(to: CGPoint(x: 90.1, y: 220.3))
//    shape.addLine(to: CGPoint(x: 80.5, y: 212.5))
//    shape.addCurve(to: CGPoint(x: 66.2, y: 182.6), controlPoint1: CGPoint(x: -9.1, y: -7.3), controlPoint2: CGPoint(x: -14.3, y: -18.2))
//    shape.addCurve(to: CGPoint(x: 81.6, y: 151.8), controlPoint1: CGPoint(x: 0, y: -12.2), controlPoint2: CGPoint(x: 5.6, y: -23.5))
//    shape.addLine(to: CGPoint(x: 91.7, y: 144.2))
//    shape.addLine(to: CGPoint(x: 82, y: 136.1))
//    shape.addCurve(to: CGPoint(x: 68.1, y: 106.5), controlPoint1: CGPoint(x: -8.8, y: -7.3), controlPoint2: CGPoint(x: -13.9, y: -18.1))
//    shape.addCurve(to: CGPoint(x: 106.6, y: 68), controlPoint1: CGPoint(x: 0, y: -21.2), controlPoint2: CGPoint(x: 17.3, y: -38.5))
//    shape.addCurve(to: CGPoint(x: 136.5, y: 82.3), controlPoint1: CGPoint(x: 11.7, y: 0), controlPoint2: CGPoint(x: 22.5, y: 5.2))
//    shape.addLine(to: CGPoint(x: 144.3, y: 91.9))
//    shape.addLine(to: CGPoint(x: 152.1, y: 82.3))
//    shape.addCurve(to: CGPoint(x: 182, y: 68), controlPoint1: CGPoint(x: 7.4, y: -9.1), controlPoint2: CGPoint(x: 18.2, y: -14.3))
//    shape.addCurve(to: CGPoint(x: 211.9, y: 82.3), controlPoint1: CGPoint(x: 11.7, y: 0), controlPoint2: CGPoint(x: 22.5, y: 5.2))
//    shape.addLine(to: CGPoint(x: 219.7, y: 91.9))
//    shape.addLine(to: CGPoint(x: 227.5, y: 82.3))
//    shape.addCurve(to: CGPoint(x: 257.4, y: 68), controlPoint1: CGPoint(x: 7.4, y: -9.1), controlPoint2: CGPoint(x: 18.2, y: -14.3))
//    shape.addCurve(to: CGPoint(x: 287.3, y: 82.3), controlPoint1: CGPoint(x: 11.7, y: 0), controlPoint2: CGPoint(x: 22.5, y: 5.2))
//    shape.addLine(to: CGPoint(x: 295.1, y: 91.9))
//    shape.addLine(to: CGPoint(x: 302.9, y: 82.3))
//    shape.addCurve(to: CGPoint(x: 332.8, y: 68), controlPoint1: CGPoint(x: 7.4, y: -9.1), controlPoint2: CGPoint(x: 18.2, y: -14.3))
//    shape.addCurve(to: CGPoint(x: 362.7, y: 82.3), controlPoint1: CGPoint(x: 11.7, y: 0), controlPoint2: CGPoint(x: 22.5, y: 5.2))
//    shape.addLine(to: CGPoint(x: 370.5, y: 91.9))
//    shape.addLine(to: CGPoint(x: 378.3, y: 82.3))
//    shape.addCurve(to: CGPoint(x: 408.2, y: 68), controlPoint1: CGPoint(x: 385.6, y: 73.2), controlPoint2: CGPoint(x: 396.5, y: 68))
//    shape.move(to: CGPoint(x: 408.2, y: 58))
//    shape.addCurve(to: CGPoint(x: 370.5, y: 76), controlPoint1: CGPoint(x: -15.2, y: 0), controlPoint2: CGPoint(x: -28.8, y: 7))
//    shape.addCurve(to: CGPoint(x: 332.8, y: 58), controlPoint1: CGPoint(x: -8.9, y: -11), controlPoint2: CGPoint(x: -22.5, y: -18))
//    shape.addCurve(to: CGPoint(x: 295.1, y: 76), controlPoint1: CGPoint(x: -15.2, y: 0), controlPoint2: CGPoint(x: -28.8, y: 7))
//    shape.addCurve(to: CGPoint(x: 257.4, y: 58), controlPoint1: CGPoint(x: -8.9, y: -11), controlPoint2: CGPoint(x: -22.5, y: -18))
//    shape.addCurve(to: CGPoint(x: 219.7, y: 76), controlPoint1: CGPoint(x: -15.2, y: 0), controlPoint2: CGPoint(x: -28.8, y: 7))
//    shape.addCurve(to: CGPoint(x: 182, y: 58), controlPoint1: CGPoint(x: -8.9, y: -11), controlPoint2: CGPoint(x: -22.5, y: -18))
//    shape.addCurve(to: CGPoint(x: 144.3, y: 76), controlPoint1: CGPoint(x: -15.2, y: 0), controlPoint2: CGPoint(x: -28.8, y: 7))
//    shape.addCurve(to: CGPoint(x: 106.6, y: 58), controlPoint1: CGPoint(x: -8.9, y: -11), controlPoint2: CGPoint(x: -22.5, y: -18))
//    shape.addCurve(to: CGPoint(x: 58.1, y: 106.5), controlPoint1: CGPoint(x: -26.8, y: 0), controlPoint2: CGPoint(x: -48.5, y: 21.7))
//    shape.addCurve(to: CGPoint(x: 75.6, y: 143.7), controlPoint1: CGPoint(x: 0, y: 15), controlPoint2: CGPoint(x: 6.8, y: 28.4))
//    shape.addCurve(to: CGPoint(x: 56.1, y: 182.5), controlPoint1: CGPoint(x: -11.8, y: 8.8), controlPoint2: CGPoint(x: -19.5, y: 22.9))
//    shape.addCurve(to: CGPoint(x: 74.1, y: 220.2), controlPoint1: CGPoint(x: 0, y: 15.2), controlPoint2: CGPoint(x: 7, y: 28.8))
//    shape.addCurve(to: CGPoint(x: 56.1, y: 257.9), controlPoint1: CGPoint(x: -11, y: 8.9), controlPoint2: CGPoint(x: -18, y: 22.5))
//    shape.addCurve(to: CGPoint(x: 74.1, y: 295.6), controlPoint1: CGPoint(x: 0, y: 15.2), controlPoint2: CGPoint(x: 7, y: 28.8))
//    shape.addCurve(to: CGPoint(x: 56.1, y: 333.3), controlPoint1: CGPoint(x: -11, y: 8.9), controlPoint2: CGPoint(x: -18, y: 22.5))
//    shape.addCurve(to: CGPoint(x: 73.9, y: 370.8), controlPoint1: CGPoint(x: 0, y: 15.1), controlPoint2: CGPoint(x: 6.9, y: 28.6))
//    shape.addCurve(to: CGPoint(x: 58.1, y: 406.6), controlPoint1: CGPoint(x: -9.7, y: 8.9), controlPoint2: CGPoint(x: -15.8, y: 21.6))
//    shape.addCurve(to: CGPoint(x: 106.6, y: 455.1), controlPoint1: CGPoint(x: 0, y: 26.8), controlPoint2: CGPoint(x: 21.7, y: 48.5))
//    shape.addCurve(to: CGPoint(x: 144.3, y: 437.1), controlPoint1: CGPoint(x: 15.2, y: 0), controlPoint2: CGPoint(x: 28.8, y: -7))
//    shape.addCurve(to: CGPoint(x: 182, y: 455.1), controlPoint1: CGPoint(x: 8.9, y: 11), controlPoint2: CGPoint(x: 22.5, y: 18))
//    shape.addCurve(to: CGPoint(x: 219.7, y: 437.1), controlPoint1: CGPoint(x: 15.2, y: 0), controlPoint2: CGPoint(x: 28.8, y: -7))
//    shape.addCurve(to: CGPoint(x: 257.4, y: 455.1), controlPoint1: CGPoint(x: 8.9, y: 11), controlPoint2: CGPoint(x: 22.5, y: 18))
//    shape.addCurve(to: CGPoint(x: 295.1, y: 437.1), controlPoint1: CGPoint(x: 15.2, y: 0), controlPoint2: CGPoint(x: 28.8, y: -7))
//    shape.addCurve(to: CGPoint(x: 332.8, y: 455.1), controlPoint1: CGPoint(x: 8.9, y: 11), controlPoint2: CGPoint(x: 22.5, y: 18))
//    shape.addCurve(to: CGPoint(x: 370.5, y: 437.1), controlPoint1: CGPoint(x: 15.2, y: 0), controlPoint2: CGPoint(x: 28.8, y: -7))
//    shape.addCurve(to: CGPoint(x: 408.2, y: 455.1), controlPoint1: CGPoint(x: 8.9, y: 11), controlPoint2: CGPoint(x: 22.5, y: 18))
//    shape.addCurve(to: CGPoint(x: 456.7, y: 406.6), controlPoint1: CGPoint(x: 26.8, y: 0), controlPoint2: CGPoint(x: 48.5, y: -21.7))
//    shape.addCurve(to: CGPoint(x: 439.6, y: 369.6), controlPoint1: CGPoint(x: 0, y: -14.8), controlPoint2: CGPoint(x: -6.7, y: -28.1))
//    shape.addCurve(to: CGPoint(x: 456.1, y: 333.2), controlPoint1: CGPoint(x: 10.1, y: -8.9), controlPoint2: CGPoint(x: 16.5, y: -21.9))
//    shape.addCurve(to: CGPoint(x: 438.1, y: 295.5), controlPoint1: CGPoint(x: 0, y: -15.2), controlPoint2: CGPoint(x: -7, y: -28.8))
//    shape.addCurve(to: CGPoint(x: 456.1, y: 257.8), controlPoint1: CGPoint(x: 11, y: -8.9), controlPoint2: CGPoint(x: 18, y: -22.5))
//    shape.addCurve(to: CGPoint(x: 438.1, y: 220.1), controlPoint1: CGPoint(x: 0, y: -15.2), controlPoint2: CGPoint(x: -7, y: -28.8))
//    shape.addCurve(to: CGPoint(x: 456.1, y: 182.4), controlPoint1: CGPoint(x: 11, y: -8.9), controlPoint2: CGPoint(x: 18, y: -22.5))
//    shape.addCurve(to: CGPoint(x: 438, y: 144.6), controlPoint1: CGPoint(x: 0, y: -15.3), controlPoint2: CGPoint(x: -7.1, y: -28.9))
//    shape.addCurve(to: CGPoint(x: 456.8, y: 106.3), controlPoint1: CGPoint(x: 11.4, y: -8.9), controlPoint2: CGPoint(x: 18.8, y: -22.7))
//    shape.addCurve(to: CGPoint(x: 408.2, y: 58), controlPoint1: CGPoint(x: 456.6, y: 79.7), controlPoint2: CGPoint(x: 434.9, y: 58))
//    shape.addLine(to: CGPoint(x: 408.2, y: 58))
    return path;
}

- (void)drawContent:(CGRect)rect withinContext:(CGContextRef)contextRef {
    CGFloat lineWidth = self.entityStrokeWidth / self.scale;
    CGContextSetLineWidth(contextRef, self.entityStrokeWidth / self.scale);
    CGContextSetStrokeColorWithColor(contextRef, [self.entityStrokeColor CGColor]);
    CGContextSetLineCap(contextRef, kCGLineCapRound);
    CGContextSetLineJoin(contextRef, kCGLineJoinRound);
    CGContextBeginPath(contextRef);
    
    // CGRect entityRect = CGRectMake(0, 0, rect.size.width, rect.size.height);
    // CGFloat padding = (self.bordersPadding + self.entityStrokeWidth) / self.scale;
    // entityRect = CGRectInset(entityRect, padding , padding);
    // [[UIColor redColor] setFill];
    // UIRectFill(entityRect);
    
    // CGFloat radius = rect.size.width / 2;
    
    // CGRect circleRect = CGRectMake(0, 0, radius, radius);
    // circleRect = CGRectInset(circleRect, padding , padding);
    
    // CGContextStrokeEllipseInRect(contextRef, circleRect);
    // CGContextStrokeRect(contextRef, entityRect);

    // CGContextRef context = UIGraphicsGetCurrentContext();
    UIBezierPath *path = [self getPath];
    CGContextAddPath(contextRef, path.CGPath);
    
    // CALayer *layer = [[CALayer alloc] init];
    // CAShapeLayer *shapeLayer = [[CAShapeLayer alloc] init];
    // [shapeLayer setPath:[path CGPath]];
    // [shapeLayer setFillColor:[self.entityStrokeColor CGColor]];
    // [shapeLayer setLineWidth:lineWidth];
    // [layer addSublayer:shapeLayer];
    // CGFloat wRatio = layer.frame.size.width / rect.size.width;
    // CGFloat hRatio = layer.frame.size.height / rect.size.height;
    // CATransform3D transform = CATransform3DMakeScale(wRatio, hRatio, 1.0);
    // [layer setTransform:transform];
    // [layer renderInContext:contextRef];
    
    CGContextDrawPath(contextRef, kCGPathStroke);
}

@end
