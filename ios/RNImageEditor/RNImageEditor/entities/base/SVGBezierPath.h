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


#import "SVGPortability.h"

NS_ASSUME_NONNULL_BEGIN

@class SVGBezierPath;

FOUNDATION_EXTERN CGRect SVGAdjustCGRectForContentsGravity(CGRect aRect, CGSize aSize, NSString *aGravity);
FOUNDATION_EXTERN CGRect SVGBoundingRectForPaths(NSArray<SVGBezierPath*> *paths);
FOUNDATION_EXTERN void SVGDrawPaths(NSArray<SVGBezierPath*> *paths, CGContextRef ctx, CGRect rect,
                                    __nullable CGColorRef defaultFillColor,
                                    __nullable CGColorRef defaultStrokeColor);
FOUNDATION_EXTERN void SVGDrawPathsWithBlock(NSArray<SVGBezierPath*> * const paths,
                                             CGContextRef const ctx,
                                             CGRect rect,
                                             void (^drawingBlock)(SVGBezierPath *path));

/// A NSBezierPath or UIBezierPath subclass that represents an SVG path
/// and its SVG attributes
@interface SVGBezierPath : PSVGBezierPath


/*!
 * @brief A set of paths and their attributes.
 *
 */
@property(nonatomic, readonly) NSDictionary<NSString*, id> *svgAttributes;


/*!
 * @brief The string representation of an SVG.
 *
 */
@property(nonatomic, readonly) NSString *SVGRepresentation;



/*!
 * @brief Returns an array of SVGBezierPaths given an SVG's URL.
 *
 * @param aURL The URL from which to load an SVG.
 *
 */
+ (NSArray<SVGBezierPath*> *)pathsFromSVGAtURL:(NSURL *)aURL;


/*!
 * @brief Returns an array of paths given the XML string of an SVG.
 *
 */
+ (NSArray<SVGBezierPath*> *)pathsFromSVGString:(NSString *)svgString;

/*!
 * @brief Returns a new path with the values of `attributes` added to `svgAttributes`
 *
 * @param attributes A dictionary of SVG attributes to set.
 *
 */
- (SVGBezierPath *)pathBySettingSVGAttributes:(NSDictionary *)attributes;

+ (void)resetCache;

@end
NS_ASSUME_NONNULL_END