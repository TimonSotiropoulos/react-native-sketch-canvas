/*
    This file is part of the PocketSVG package.
    Copyright (c) Ponderwell, Ariel Elkin, Fjölnir Ásgeirsson, and Contributors

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
    THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
 */


#import "SVGBezierPath.h"
#import "SVGEngine.h"


@implementation SVGBezierPath

+ (NSCache<NSURL*, NSArray<SVGBezierPath*>*> *)_svg_pathCache
{
    static NSCache<NSURL*, NSArray<SVGBezierPath*>*> *pathCache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pathCache = [NSCache new];
    });
    return pathCache;
}
+ (void)resetCache
{
    [self._svg_pathCache removeAllObjects];
}

+ (NSArray<SVGBezierPath*> *)pathsFromSVGAtURL:(NSURL *)aURL
{
    NSArray<SVGBezierPath*> *paths = [self.class._svg_pathCache objectForKey:aURL];
    if (!paths) {
        paths =  [self pathsFromSVGString:[NSString stringWithContentsOfURL:aURL
                                                               usedEncoding:NULL
                                                                      error:NULL]];
        if (paths) {
            [self.class._svg_pathCache setObject:paths forKey:aURL];
        }
    }
    return [[NSArray alloc] initWithArray:paths copyItems:YES];
}

+ (NSArray<SVGBezierPath*> *)pathsFromSVGString:(NSString * const)svgString
{
    SVGAttributeSet *cgAttrs;
    NSArray * const pathRefs = CGPathsFromSVGString(svgString, &cgAttrs);
    NSMutableArray<SVGBezierPath*> * const paths = [NSMutableArray arrayWithCapacity:pathRefs.count];
    for(id pathRef in pathRefs) {
        SVGBezierPath * const uiPath = [self bezierPathWithCGPath:(__bridge CGPathRef)pathRef];
        uiPath->_svgAttributes = [cgAttrs attributesForPath:(__bridge CGPathRef)pathRef] ?: @{};
        uiPath.lineWidth = uiPath->_svgAttributes[@"stroke-width"] ? [uiPath->_svgAttributes[@"stroke-width"] doubleValue] : 1.0;
        [paths addObject:uiPath];
    }
    return paths;
}

- (NSString *)SVGRepresentation
{
    SVGMutableAttributeSet *attributes = [SVGMutableAttributeSet new];
    [attributes setAttributes:self.svgAttributes forPath:self.CGPath];
    return SVGStringFromCGPaths(@[(__bridge id)self.CGPath], attributes);
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    SVGBezierPath * const copy = [super copyWithZone:zone];
    copy->_svgAttributes = [_svgAttributes copy];
    return copy;
}

- (SVGBezierPath *)pathBySettingSVGAttributes:(NSDictionary *)attributes
{
    NSParameterAssert(attributes);
    
    SVGBezierPath *path = [self copy];
    if (path) {
        if (path->_svgAttributes.count > 0) {
            path->_svgAttributes = [path->_svgAttributes mutableCopy];
            if (attributes) {
                [(NSMutableDictionary *)path->_svgAttributes setValuesForKeysWithDictionary:attributes];
            }
        } else {
            path->_svgAttributes = [attributes copy];
        }
    }
    return path;
}

+ (instancetype)bezierPathWithCGPath:(CGPathRef)cgPath
{
    if (NSProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 9) {
        return [super bezierPathWithCGPath:cgPath];
    } else {
        // iOS 8 and lower don't return instancetype...
        SVGBezierPath *path = [self new];
        path.CGPath = cgPath;
        return path;
    }
}

extern "C" CGRect SVGBoundingRectForPaths(NSArray<SVGBezierPath*> * const paths)
{
    CGRect bounds = CGRectZero;
    for(SVGBezierPath *path in paths) {
        bounds = CGRectUnion(bounds, path.bounds);
    }
    return bounds;
}

extern "C" void SVGDrawPaths(NSArray<SVGBezierPath*> * const paths,
                             CGContextRef const ctx,
                             CGRect const rect,
                             CGColorRef const defaultFillColor,
                             CGColorRef const defaultStrokeColor)
{
    SVGDrawPathsWithBlock(paths, ctx, rect, ^(SVGBezierPath *path) {
        CGColorRef fillColor = (__bridge CGColorRef)path.svgAttributes[@"fill"]
                            ?: defaultFillColor;
        if (fillColor && CGColorGetAlpha(fillColor) > 0) {
            [[PSVGColor colorWithCGColor:fillColor] setFill];
            [path fill];
        }
        CGColorRef strokeColor = (__bridge CGColorRef)path.svgAttributes[@"stroke"]
                              ?: defaultStrokeColor;
        if (strokeColor && CGColorGetAlpha(strokeColor) > 0) {
            [[PSVGColor colorWithCGColor:strokeColor] setStroke];
            [path stroke];
        }
    });
}
extern "C" void SVGDrawPathsWithBlock(NSArray<SVGBezierPath*> * const paths,
                                      CGContextRef const ctx,
                                      CGRect rect,
                                      void (^drawingBlock)(SVGBezierPath *path))
{
    if (!drawingBlock) {
        return;
    }
    
    CGRect const bounds  = SVGBoundingRectForPaths(paths);
    if (CGRectIsNull(rect)) {
        rect = bounds;
    }
    
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx, rect.origin.x, rect.origin.y);
    CGContextScaleCTM(ctx, rect.size.width  / bounds.size.width, rect.size.height / bounds.size.height);
    UIGraphicsPushContext(ctx);
    for (SVGBezierPath *path in paths) {
        CGContextSaveGState(ctx);
            drawingBlock(path);
        CGContextRestoreGState(ctx);
    }
    UIGraphicsPopContext();
    CGContextRestoreGState(ctx);
}

#ifdef __LP64__
#define _CGFloor floor
#define _CGRound round
#else
#define _CGFloor floorf
#define _CGRound roundf
#endif

extern "C" CGRect SVGAdjustCGRectForContentsGravity(CGRect const aRect, CGSize const aSize, NSString * const aGravity)
{
    if(aSize.width != aRect.size.width || aSize.height != aRect.size.height) {
        if([aGravity isEqualToString:kCAGravityLeft])
            return (CGRect) { aRect.origin.x,
                              aRect.origin.y + _CGFloor(aRect.size.height/2 - aSize.height/2),
                              aSize.width, aSize.height };
        else if([aGravity isEqualToString:kCAGravityRight])
            return (CGRect) { aRect.origin.x + (aRect.size.width - aSize.width),
                              aRect.origin.y + _CGFloor(aRect.size.height/2 - aSize.height/2),
                              aSize.width, aSize.height };
        else if([aGravity isEqualToString:kCAGravityTop])
            return (CGRect) { aRect.origin.x + _CGFloor(aRect.size.width/2 - aSize.width/2),
                              aRect.origin.y,
                              aSize.width, aSize.height };
        else if([aGravity isEqualToString:kCAGravityBottom])
            return (CGRect) { aRect.origin.x + _CGFloor(aRect.size.width/2 - aSize.width/2),
                              aRect.origin.y + _CGFloor(aRect.size.height - aSize.height),
                              aSize.width, aSize.height };
        else if([aGravity isEqualToString:kCAGravityCenter])
            return (CGRect) { aRect.origin.x + _CGRound(aRect.size.width/2 - aSize.width/2),
                              aRect.origin.y + _CGRound(aRect.size.height/2 - aSize.height/2),
                              aSize.width, aSize.height };
        else if([aGravity isEqualToString:kCAGravityBottomLeft])
            return (CGRect) { aRect.origin.x,
                              aRect.origin.y + _CGFloor(aRect.size.height - aSize.height),
                              aSize.width, aSize.height };
        else if([aGravity isEqualToString:kCAGravityBottomRight])
            return (CGRect) { aRect.origin.x + (aRect.size.width - aSize.width),
                              aRect.origin.y + (aRect.size.height - aSize.height),
                              aSize.width, aSize.height };
        else if([aGravity isEqualToString:kCAGravityTopLeft])
            return (CGRect) { aRect.origin.x,
                              aRect.origin.y,
                              aSize.width, aSize.height };
        else if([aGravity isEqualToString:kCAGravityTopRight])
            return (CGRect) { aRect.origin.x + (aRect.size.width - aSize.width),
                              aRect.origin.y,
                              aSize.width, aSize.height };
        else if([aGravity isEqualToString:kCAGravityResizeAspectFill]) {
            CGSize        size      = aSize;
            CGFloat const sizeRatio = size.width / size.height;
            CGFloat const rectRatio = aRect.size.width / aRect.size.height;
            if(sizeRatio > rectRatio) {
                size.width = _CGFloor(sizeRatio * aRect.size.height);
                size.height = aRect.size.height;
            } else {
                size.height = _CGFloor(aRect.size.width / sizeRatio);
                size.width = aRect.size.width;
            }
            return (CGRect) { aRect.origin.x + _CGFloor(aRect.size.width/2 - size.width/2),
                              aRect.origin.y + _CGFloor(aRect.size.height/2 - size.height/2),
                              size.width, size.height };
        } else if([aGravity isEqualToString:kCAGravityResizeAspect]) {
            CGSize size = aSize;
            if((size.height/size.width) < (aRect.size.height/aRect.size.width)) {
                size.height = _CGFloor((size.height/size.width) * aRect.size.width);
                size.width  = aRect.size.width;
            } else {
                size.width = _CGFloor((size.width/size.height) * aRect.size.height);
                size.height = aRect.size.height;
            }
            return (CGRect) { aRect.origin.x + _CGFloor(aRect.size.width/2 - size.width/2),
                              aRect.origin.y + _CGFloor(aRect.size.height/2 - size.height/2),
                              size.width, size.height };
        }
    }
    return aRect;
}
@end
