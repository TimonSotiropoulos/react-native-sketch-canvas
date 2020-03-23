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


#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

#ifdef __cplusplus
extern "C" {
#endif

@class SVGAttributeSet;


/*!
 * @brief Returns an array of CGPathRefs contained within the passed SVG string.
 *
 * @param svgString The string containing the SVG formatted path.
 * @param attributes An optional pointer for storing a map table containing SVG attributes for the paths
 *
 * @return An array of CGPathRef objects or nil if none are found
 *
 */
NSArray *CGPathsFromSVGString(NSString *svgString, SVGAttributeSet **attributes);

/*!
 * @brief Returns a single CGPathRef parsed from the contents of a single string formatted like the d attribute inside a path element
 *
 * @param svgString The string containing the SVG formatted path, this is just the path string from the d attribute and no xml
 *
 * @return A single CGPathRef object
 *
 */
CGPathRef CGPathFromSVGPathString(NSString *svgString);

/*!
 * @brief Returns SVG representing `paths`
 *
 * @param paths An array of CGPathRefs to construct the SVG from
 * @param attributes An optional map table of SVG attributes for the paths
 *
 * @return SVG representing `paths`
 *
 */
NSString *SVGStringFromCGPaths(NSArray *paths, SVGAttributeSet *attributes);

@interface SVGAttributeSet : NSObject <NSCopying, NSMutableCopying>
- (NSDictionary<NSString*,id> *)attributesForPath:(CGPathRef)path;
@end
@interface SVGMutableAttributeSet : SVGAttributeSet
- (void)setAttributes:(NSDictionary<NSString*,id> *)attributes forPath:(CGPathRef)path;
@end

@interface NSValue (PocketSVG)
+ (instancetype)svg_valueWithCGAffineTransform:(CGAffineTransform)aTransform;
- (CGAffineTransform)svg_CGAffineTransformValue;
@end

#ifdef __cplusplus
};
#endif
