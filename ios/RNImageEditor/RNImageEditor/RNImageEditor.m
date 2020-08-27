#import "RNImageEditorManager.h"
#import "RNImageEditor.h"
#import "RNImageEditorData.h"
#import <React/RCTEventDispatcher.h>
#import <React/RCTView.h>
#import <React/UIView+React.h>
#import "RNImageEditorUtility.h"
#import "BackgroundText.h"
#import "entities/base/Enumerations.h"
#import "entities/base/MotionEntity.h"
#import "entities/CircleEntity.h"
#import "entities/RectEntity.h"
#import "entities/TriangleEntity.h"
#import "entities/ArrowEntity.h"
#import "entities/TextEntity.h"
#import "entities/CloudEntity.h"
#import "entities/LineEntity.h"

@implementation RNImageEditor
{
    RCTEventDispatcher *_eventDispatcher;
    NSMutableArray *_paths;
    RNImageEditorData *_currentPath;

    CGSize _lastSize;

    CGContextRef _drawingContext, _translucentDrawingContext;
    CGImageRef _frozenImage, _translucentFrozenImage;
    BOOL _needsFullRedraw;

    UIImage *_backgroundImage;
    UIImage *_backgroundImageScaled;
    NSString *_backgroundImageContentMode;

    NSArray *_arrTextOnSketch, *_arrSketchOnText;
}

- (instancetype)initWithEventDispatcher:(RCTEventDispatcher *)eventDispatcher
{
    self = [super init];
    if (self) {
        _eventDispatcher = eventDispatcher;
        _paths = [NSMutableArray new];
        _needsFullRedraw = YES;

        self.backgroundColor = [UIColor clearColor];
        self.clearsContextBeforeDrawing = YES;

        self.motionEntities = [NSMutableArray new];
        self.selectedEntity = nil;
        self.entityBorderColor = [UIColor clearColor];
        self.entityBorderStyle = DASHED;
        self.entityBorderStrokeWidth = 1.0;
        self.entityStrokeWidth = 5.0;
        self.entityStrokeColor = [UIColor blackColor];

        self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        self.tapGesture.delegate = self;
        self.tapGesture.numberOfTapsRequired = 1;

        self.rotateGesture = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotate:)];
        self.rotateGesture.delegate = self;

        self.moveGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleMove:)];
        self.moveGesture.delegate = self;
        self.moveGesture.minimumNumberOfTouches = 1;
        self.moveGesture.maximumNumberOfTouches = 1;

        self.scaleGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handleScale:)];
        self.scaleGesture.delegate = self;

        [self addGestureRecognizer:self.tapGesture];
        [self addGestureRecognizer:self.rotateGesture];
        [self addGestureRecognizer:self.moveGesture];
        [self addGestureRecognizer:self.scaleGesture];

    }
    return self;
}

- (void)dealloc {
    CGContextRelease(_drawingContext);
    _drawingContext = nil;
    CGImageRelease(_frozenImage);
    _frozenImage = nil;
}


// Make multiple GestureRecognizers work
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return TRUE;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGRect bounds = self.bounds;

    if (_needsFullRedraw) {
        [self setFrozenImageNeedsUpdate];
        CGContextClearRect(_drawingContext, bounds);
        for (RNImageEditorData *path in _paths) {
            [path drawInContext:_drawingContext];
        }
        _needsFullRedraw = NO;
    }

    if (!_frozenImage) {
        _frozenImage = CGBitmapContextCreateImage(_drawingContext);
    }

    if (!_translucentFrozenImage && _currentPath.isTranslucent) {
        _translucentFrozenImage = CGBitmapContextCreateImage(_translucentDrawingContext);
    }

    if (_backgroundImage) {
        if (!_backgroundImageScaled) {
            _backgroundImageScaled = [self scaleImage:_backgroundImage toSize:bounds.size contentMode: _backgroundImageContentMode];
        }

        [_backgroundImageScaled drawInRect:bounds];
    }

    for (BackgroundText *text in _arrSketchOnText) {
        [text.text drawInRect: text.drawRect withAttributes: text.attribute];
    }

    if (_frozenImage) {
        CGContextDrawImage(context, bounds, _frozenImage);
    }

    if (_translucentFrozenImage && _currentPath.isTranslucent) {
        CGContextDrawImage(context, bounds, _translucentFrozenImage);
    }

    for (BackgroundText *text in _arrTextOnSketch) {
        [text.text drawInRect: text.drawRect withAttributes: text.attribute];
    }

    for (MotionEntity *entity in self.motionEntities) {
        [entity updateStrokeSettings:self.entityBorderStyle
                   borderStrokeWidth:self.entityBorderStrokeWidth
                   borderStrokeColor:self.entityBorderColor
                   entityStrokeWidth:self.entityStrokeWidth
                   entityStrokeColor:self.entityStrokeColor];

        if ([entity isSelected]) {
            [self notifyShapeColourUpdate: self.entityStrokeColor];
            [entity setNeedsDisplay];
        }

        [self addSubview:entity];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];

    if (!CGSizeEqualToSize(self.bounds.size, _lastSize)) {
        _lastSize = self.bounds.size;
        CGContextRelease(_drawingContext);
        _drawingContext = nil;
        [self createDrawingContext];
        _needsFullRedraw = YES;
        _backgroundImageScaled = nil;

        for (BackgroundText *text in [_arrTextOnSketch arrayByAddingObjectsFromArray: _arrSketchOnText]) {
            CGPoint position = text.position;
            if (!text.isAbsoluteCoordinate) {
                position.x *= self.bounds.size.width;
                position.y *= self.bounds.size.height;
            }
            position.x -= text.drawRect.size.width * text.anchor.x;
            position.y -= text.drawRect.size.height * text.anchor.y;
            text.drawRect = CGRectMake(position.x, position.y, text.drawRect.size.width, text.drawRect.size.height);
        }

        [self setNeedsDisplay];
    }
}

- (void)createDrawingContext {
    CGFloat scale = self.window.screen.scale;
    CGSize size = self.bounds.size;
    size.width *= scale;
    size.height *= scale;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    _drawingContext = CGBitmapContextCreate(nil, size.width, size.height, 8, 0, colorSpace, kCGImageAlphaPremultipliedLast);
    _translucentDrawingContext = CGBitmapContextCreate(nil, size.width, size.height, 8, 0, colorSpace, kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colorSpace);

    CGContextConcatCTM(_drawingContext, CGAffineTransformMakeScale(scale, scale));
    CGContextConcatCTM(_translucentDrawingContext, CGAffineTransformMakeScale(scale, scale));
}

- (void)setFrozenImageNeedsUpdate {
    CGImageRelease(_frozenImage);
    CGImageRelease(_translucentFrozenImage);
    _frozenImage = nil;
    _translucentFrozenImage = nil;
}

- (BOOL)openSketchFile:(NSString *)filename directory:(NSString*) directory contentMode:(NSString*)mode {
    if (filename) {
        UIImage *image = [UIImage imageWithContentsOfFile: [directory stringByAppendingPathComponent: filename]];
        image = image ? image : [UIImage imageNamed: filename];
        if(image) {
            if (image.imageOrientation != UIImageOrientationUp) {
                UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
                [image drawInRect:(CGRect){0, 0, image.size}];
                UIImage *normalizedImage = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
                image = normalizedImage;
            }
            _backgroundImage = image;
            _backgroundImageScaled = nil;
            _backgroundImageContentMode = mode;
            [self setNeedsDisplay];

            return YES;
        }
    }
    return NO;
}

- (void)setCanvasText:(NSArray *)aText {
    NSMutableArray *arrTextOnSketch = [NSMutableArray new];
    NSMutableArray *arrSketchOnText = [NSMutableArray new];
    NSDictionary *alignments = @{
                                 @"Left": [NSNumber numberWithInteger:NSTextAlignmentLeft],
                                 @"Center": [NSNumber numberWithInteger:NSTextAlignmentCenter],
                                 @"Right": [NSNumber numberWithInteger:NSTextAlignmentRight]
                                 };

    for (NSDictionary *property in aText) {
        if (property[@"text"]) {
            NSMutableArray *arr = [@"TextOnSketch" isEqualToString: property[@"overlay"]] ? arrTextOnSketch : arrSketchOnText;
            BackgroundText *text = [BackgroundText new];
            text.text = property[@"text"];
            UIFont *font = nil;
            if (property[@"font"]) {
                font = [UIFont fontWithName: property[@"font"] size: property[@"fontSize"] == nil ? 12 : [property[@"fontSize"] floatValue]];
                font = font == nil ? [UIFont systemFontOfSize: property[@"fontSize"] == nil ? 12 : [property[@"fontSize"] floatValue]] : font;
            } else if (property[@"fontSize"]) {
                font = [UIFont systemFontOfSize: [property[@"fontSize"] floatValue]];
            } else {
                font = [UIFont systemFontOfSize: 12];
            }
            text.font = font;
            text.anchor = property[@"anchor"] == nil ?
                CGPointMake(0, 0) :
                CGPointMake([property[@"anchor"][@"x"] floatValue], [property[@"anchor"][@"y"] floatValue]);
            text.position = property[@"position"] == nil ?
                CGPointMake(0, 0) :
                CGPointMake([property[@"position"][@"x"] floatValue], [property[@"position"][@"y"] floatValue]);
            long color = property[@"fontColor"] == nil ? 0xFF000000 : [property[@"fontColor"] longValue];
            UIColor *fontColor =
            [UIColor colorWithRed:(CGFloat)((color & 0x00FF0000) >> 16) / 0xFF
                            green:(CGFloat)((color & 0x0000FF00) >> 8) / 0xFF
                             blue:(CGFloat)((color & 0x000000FF)) / 0xFF
                            alpha:(CGFloat)((color & 0xFF000000) >> 24) / 0xFF];
            NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
            NSString *a = property[@"alignment"] ? property[@"alignment"] : @"Left";
            style.alignment = [alignments[a] integerValue];
            style.lineHeightMultiple = property[@"lineHeightMultiple"] ? [property[@"lineHeightMultiple"] floatValue] : 1.0;
            text.attribute = @{
                               NSFontAttributeName:font,
                               NSForegroundColorAttributeName:fontColor,
                               NSParagraphStyleAttributeName:style
                               };
            text.isAbsoluteCoordinate = ![@"Ratio" isEqualToString:property[@"coordinate"]];
            CGSize textSize = [text.text sizeWithAttributes:text.attribute];

            CGPoint position = text.position;
            if (!text.isAbsoluteCoordinate) {
                position.x *= self.bounds.size.width;
                position.y *= self.bounds.size.height;
            }
            position.x -= textSize.width * text.anchor.x;
            position.y -= textSize.height * text.anchor.y;
            text.drawRect = CGRectMake(position.x, position.y, textSize.width, textSize.height);
            [arr addObject: text];
        }
    }
    _arrTextOnSketch = [arrTextOnSketch copy];
    _arrSketchOnText = [arrSketchOnText copy];
    [self setNeedsDisplay];
}

- (void)newPath:(int) pathId strokeColor:(UIColor*) strokeColor strokeWidth:(int) strokeWidth {
    if (CGColorGetComponents(strokeColor.CGColor)[3] != 0.0) {
        self.entityStrokeColor = strokeColor;
    }
    self.entityStrokeWidth = strokeWidth;

    _currentPath = [[RNImageEditorData alloc]
                    initWithId: pathId
                    strokeColor: strokeColor
                    strokeWidth: strokeWidth];
    [_paths addObject: _currentPath];
}

- (void) addPath:(int) pathId strokeColor:(UIColor*) strokeColor strokeWidth:(int) strokeWidth points:(NSArray*) points {
    if (CGColorGetComponents(strokeColor.CGColor)[3] != 0.0) {
        self.entityStrokeColor = strokeColor;
    }

    bool exist = false;
    for(int i=0; i<_paths.count; i++) {
        if (((RNImageEditorData*)_paths[i]).pathId == pathId) {
            exist = true;
            break;
        }
    }

    if (!exist) {
        RNImageEditorData *data = [[RNImageEditorData alloc] initWithId: pathId
                                                  strokeColor: strokeColor
                                                  strokeWidth: strokeWidth
                                                       points: points];
        [_paths addObject: data];
        [data drawInContext:_drawingContext];
        [self setFrozenImageNeedsUpdate];
        [self setNeedsDisplay];
        [self notifyPathsUpdate];
    }
}

- (void)deletePath:(int) pathId {
    int index = -1;
    for(int i=0; i<_paths.count; i++) {
        if (((RNImageEditorData*)_paths[i]).pathId == pathId) {
            index = i;
            break;
        }
    }

    if (index > -1) {
        [_paths removeObjectAtIndex: index];
        _needsFullRedraw = YES;
        [self setNeedsDisplay];
        [self notifyPathsUpdate];
    }
}

- (void)addPointX: (float)x Y: (float)y isMove:(BOOL)isMove {
    if (!self.selectedEntity && (![self findEntityAtPointX:x andY:y] || isMove)) {
        CGPoint newPoint = CGPointMake(x, y);
        CGRect updateRect = [_currentPath addPoint: newPoint];

        if (_currentPath.isTranslucent) {
            CGContextClearRect(_translucentDrawingContext, self.bounds);
            [_currentPath drawInContext:_translucentDrawingContext];
        } else {
            [_currentPath drawLastPointInContext:_drawingContext];
        }

        [self setFrozenImageNeedsUpdate];
        [self setNeedsDisplayInRect:updateRect];
    }
}

- (void)endPath {
    if (_currentPath.isTranslucent) {
        [_currentPath drawInContext:_drawingContext];
    }
    _currentPath = nil;
}

- (void) clear {
    [_paths removeAllObjects];
    _currentPath = nil;
    _needsFullRedraw = YES;
    [self setNeedsDisplay];
    [self notifyPathsUpdate];
}

- (UIImage*)createImageWithTransparentBackground: (BOOL) transparent includeImage:(BOOL)includeImage includeText:(BOOL)includeText cropToImageSize:(BOOL)cropToImageSize {
    if (_backgroundImage && cropToImageSize) {
        CGRect rect = CGRectMake(0, 0, _backgroundImage.size.width, _backgroundImage.size.height);
        UIGraphicsBeginImageContextWithOptions(rect.size, !transparent, 1);
        CGContextRef context = UIGraphicsGetCurrentContext();
        if (!transparent) {
            CGContextSetRGBFillColor(context, 1.0f, 1.0f, 1.0f, 1.0f);
            CGContextFillRect(context, rect);
        }
        CGRect targetRect = [RNImageEditorUtility fillImageWithSize:self.bounds.size toSize:rect.size contentMode:@"AspectFill"];
        CGFloat scaleFactor = [RNImageEditorUtility getScaleDifference:self.bounds.size toSize:rect.size contentMode:@"AspectFill"];
        if (includeImage) {
            [_backgroundImage drawInRect:rect];
        }

        if (includeText) {
            for (BackgroundText *text in _arrSketchOnText) {
                [text.text drawInRect: text.drawRect withAttributes: text.attribute];
            }
        }

        CGContextDrawImage(context, targetRect, _frozenImage);
        CGContextDrawImage(context, targetRect, _translucentFrozenImage);

        if (includeText) {
            for (BackgroundText *text in _arrTextOnSketch) {
                [text.text drawInRect: text.drawRect withAttributes: text.attribute];
            }
        }

        for (MotionEntity *entity in self.motionEntities) {
            CGContextSaveGState(context);

            // Scale shapes because we cropToImageSize
            CGContextScaleCTM(context, scaleFactor, scaleFactor);

            // Center the context around the view's anchor point
            CGContextTranslateCTM(context, [entity center].x, [entity center].y);

            // Apply the view's transform about the anchor point
            CGContextConcatCTM(context, [entity transform]);

            // Offset by the portion of the bounds left of and above the anchor point
            CGContextTranslateCTM(context, -[entity bounds].size.width * [[entity layer] anchorPoint].x, -[entity bounds].size.height * [[entity layer] anchorPoint].y);

            // Render the entity
            [entity.layer renderInContext:context];

            CGContextRestoreGState(context);
        }

        UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

        return img;
    } else {
        CGRect rect = self.bounds;
        UIGraphicsBeginImageContextWithOptions(rect.size, !transparent, 0);
        CGContextRef context = UIGraphicsGetCurrentContext();
        if (!transparent) {
            CGContextSetRGBFillColor(context, 1.0f, 1.0f, 1.0f, 1.0f);
            CGContextFillRect(context, rect);
        }
        if (_backgroundImage && includeImage) {
            CGRect targetRect = [RNImageEditorUtility fillImageWithSize:_backgroundImage.size toSize:rect.size contentMode:_backgroundImageContentMode];
            [_backgroundImage drawInRect:targetRect];
        }

        if (includeText) {
            for (BackgroundText *text in _arrSketchOnText) {
                [text.text drawInRect: text.drawRect withAttributes: text.attribute];
            }
        }

        CGContextDrawImage(context, rect, _frozenImage);
        CGContextDrawImage(context, rect, _translucentFrozenImage);

        if (includeText) {
            for (BackgroundText *text in _arrTextOnSketch) {
                [text.text drawInRect: text.drawRect withAttributes: text.attribute];
            }
        }

        for (MotionEntity *entity in self.motionEntities) {
            CGContextSaveGState(context);

            // Center the context around the view's anchor point
            CGContextTranslateCTM(context, [entity center].x, [entity center].y);

            // Apply the view's transform about the anchor point
            CGContextConcatCTM(context, [entity transform]);

            // Offset by the portion of the bounds left of and above the anchor point
            CGContextTranslateCTM(context, -[entity bounds].size.width * [[entity layer] anchorPoint].x, -[entity bounds].size.height * [[entity layer] anchorPoint].y);

            // Render the entity
            [entity.layer renderInContext:context];

            CGContextRestoreGState(context);
        }

        UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

        return img;
    }
}

- (void)saveImageOfType:(NSString*) type folder:(NSString*) folder filename:(NSString*) filename withTransparentBackground:(BOOL) transparent includeImage:(BOOL)includeImage includeText:(BOOL)includeText cropToImageSize:(BOOL)cropToImageSize {
    UIImage *img = [self createImageWithTransparentBackground:transparent includeImage:includeImage includeText:(BOOL)includeText cropToImageSize:cropToImageSize];

    if (folder != nil && filename != nil) {
        NSURL *tempDir = [[NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES] URLByAppendingPathComponent: folder];
        NSError * error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:[tempDir path]
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error];
        if (error == nil) {
            NSURL *fileURL = [[tempDir URLByAppendingPathComponent: filename] URLByAppendingPathExtension: type];
            NSData *imageData = [self getImageData:img type:type];
            [imageData writeToURL:fileURL atomically:YES];

            if (_onChange) {
                _onChange(@{ @"success": @YES, @"path": [fileURL path]});
            }
        } else {
            if (_onChange) {
                _onChange(@{ @"success": @NO, @"path": [NSNull null]});
            }
        }
    } else {
        if ([type isEqualToString: @"png"]) {
            img = [UIImage imageWithData: UIImagePNGRepresentation(img)];
        }
        UIImageWriteToSavedPhotosAlbum(img, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    }
}

- (UIImage *)scaleImage:(UIImage *)image toSize:(CGSize)size contentMode: (NSString*)mode
{
    CGFloat scale = MAX(size.width/image.size.width, size.height/image.size.height);
    CGFloat width = image.size.width * scale;
    CGFloat height = image.size.height * scale;
    CGRect imageRect = CGRectMake((size.width - width)/2.0f,
                                  (size.height - height)/2.0f,
                                  width,
                                  height);

    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    [image drawInRect:imageRect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}
- (NSString*) transferToBase64OfType: (NSString*) type withTransparentBackground: (BOOL) transparent includeImage:(BOOL)includeImage includeText:(BOOL)includeText cropToImageSize:(BOOL)cropToImageSize {
    UIImage *img = [self createImageWithTransparentBackground:transparent includeImage:includeImage includeText:(BOOL)includeText cropToImageSize:cropToImageSize];
    NSData *data = [self getImageData:img type:type];
    return [data base64EncodedStringWithOptions: NSDataBase64Encoding64CharacterLineLength];
}

- (NSData*)getImageData:(UIImage*)img type:(NSString*) type {
    NSData *data;
    if ([type isEqualToString: @"jpg"]) {
        data = UIImageJPEGRepresentation(img, 1.0);
    } else {
        data = UIImagePNGRepresentation(img);
    }
    return data;
}

#pragma mark - MotionEntites related code
- (void)setShapeConfiguration:(NSDictionary *)dict {
    if (![dict[@"shapeBorderColor"] isEqual:[NSNull null]]) {
        long shapeBorderColorLong = [dict[@"shapeBorderColor"] longValue];
        UIColor *shapeBorderColor = [UIColor colorWithRed:(CGFloat)((shapeBorderColorLong & 0x00FF0000) >> 16) / 0xFF
                                                    green:(CGFloat)((shapeBorderColorLong & 0x0000FF00) >> 8) / 0xFF
                                                     blue:(CGFloat)((shapeBorderColorLong & 0x000000FF)) / 0xFF
                                                    alpha:(CGFloat)((shapeBorderColorLong & 0xFF000000) >> 24) / 0xFF];
        if (CGColorGetComponents(shapeBorderColor.CGColor)[3] != 0.0) {
            self.entityBorderColor = shapeBorderColor;
        }
    }

    if (![dict[@"shapeBorderStyle"] isEqual:[NSNull null]]) {
        NSString *borderStyle = dict[@"shapeBorderStyle"];
        switch ([@[@"Dashed", @"Solid"] indexOfObject: borderStyle]) {
            case 0:
                self.entityBorderStyle = DASHED;
                break;
            case 1:
                self.entityBorderStyle = SOLID;
            case NSNotFound:
            default: {
                self.entityBorderStyle = DASHED;
                break;
            }
        }
    }

    if (![dict[@"shapeBorderStrokeWidth"] isEqual:[NSNull null]]) {
        self.entityBorderStrokeWidth = [dict[@"shapeBorderStrokeWidth"] doubleValue];
    }

    if (![dict[@"shapeColor"] isEqual:[NSNull null]]) {
        long shapeColorLong = [dict[@"shapeColor"] longValue];
        UIColor *shapeColor = [UIColor colorWithRed:(CGFloat)((shapeColorLong & 0x00FF0000) >> 16) / 0xFF
                                              green:(CGFloat)((shapeColorLong & 0x0000FF00) >> 8) / 0xFF
                                               blue:(CGFloat)((shapeColorLong & 0x000000FF)) / 0xFF
                                              alpha:(CGFloat)((shapeColorLong & 0xFF000000) >> 24) / 0xFF];
        if (CGColorGetComponents(shapeColor.CGColor)[3] != 0.0) {
            self.entityStrokeColor = shapeColor;
        }
    }

    if (![dict[@"shapeStrokeWidth"] isEqual:[NSNull null]]) {
        self.entityStrokeWidth = [dict[@"shapeStrokeWidth"] doubleValue];
    }
}

- (void)addEntityWithId:(NSString *)entityId entityType:(NSString *)entityType textShapeFontType:(NSString *)textShapeFontType textShapeFontSize:(NSNumber *)textShapeFontSize textShapeText:(NSString *)textShapeText imageShapeAsset:(NSString *)imageShapeAsset transform:(NSString *)transform center:(NSString *)center colour:(UIColor *) colour {

    if ( colour != nil ) {
       self.entityStrokeColor = colour;
    }

    switch ([@[@"Circle", @"Rect", @"Square", @"Triangle", @"Arrow", @"Text", @"Image", @"Cloud", @"Line"] indexOfObject: entityType]) {
        case 1:
            [self addRectEntity:entityId width:300 andHeight:150];
            break;
        case 2:
            [self addRectEntity:entityId width:300 andHeight:300];
            break;
        case 3:
            [self addTriangleEntity: entityId];
            break;
        case 4:
            [self addArrowEntity: entityId];
            break;
        case 5:
            [self addTextEntity:entityId fontType:textShapeFontType withFontSize:textShapeFontSize withText:textShapeText];
            break;
        case 6:
            // TODO: ImageEntity Doesn't exist yet
        case 7:
            [self addCloudEntity:entityId width:300 andHeight:300];
            break;
        case 8:
            [self addLineEntity:entityId width:300 andHeight:50];
            break;
        case 0:
        case NSNotFound:
        default: {
            [self addCircleEntity: entityId];
            break;
        }
    }

    // lets try to hijack the selected entite here and just transform it if there is a transform value
    if ( transform != nil ) {
        self.selectedEntity.transform = CGAffineTransformFromString(transform);
    }



}

- (void)addCircleEntity:(NSString *)entityId {
    CGFloat centerX = CGRectGetMidX(self.bounds);
    CGFloat centerY = CGRectGetMidY(self.bounds);

    CircleEntity *entity = [[CircleEntity alloc]
                            initAndSetupWithParent:self.bounds.size.width
                            parentHeight:self.bounds.size.height
                            parentCenterX:centerX
                            parentCenterY:centerY
                            parentScreenScale:self.window.screen.scale
                            width:300
                            height:300
                            bordersPadding:5.0f
                            borderStyle:self.entityBorderStyle
                            borderStrokeWidth:self.entityBorderStrokeWidth
                            borderStrokeColor:self.entityBorderColor
                            entityStrokeWidth:self.entityStrokeWidth
                            entityStrokeColor:self.entityStrokeColor
                            entityId: entityId];

    [self.motionEntities addObject:entity];
    [self onShapeSelectionChanged:entity];
    [self selectEntity:entity];
}

- (void)addRectEntity:(NSString *)entityId width:(NSInteger)width andHeight: (NSInteger)height {
    CGFloat centerX = CGRectGetMidX(self.bounds);
    CGFloat centerY = CGRectGetMidY(self.bounds);

    RectEntity *entity = [[RectEntity alloc]
                          initAndSetupWithParent:self.bounds.size.width
                          parentHeight:self.bounds.size.height
                          parentCenterX:centerX
                          parentCenterY:centerY
                          parentScreenScale:self.window.screen.scale
                          width:width
                          height:height
                          bordersPadding:5.0f
                          borderStyle:self.entityBorderStyle
                          borderStrokeWidth:self.entityBorderStrokeWidth
                          borderStrokeColor:self.entityBorderColor
                          entityStrokeWidth:self.entityStrokeWidth
                          entityStrokeColor:self.entityStrokeColor
                          entityId: entityId];

    [self.motionEntities addObject:entity];
    [self onShapeSelectionChanged:entity];
    [self selectEntity:entity];
}

- (void)addLineEntity:(NSString *)entityId width:(NSInteger)width andHeight: (NSInteger)height {
    CGFloat centerX = CGRectGetMidX(self.bounds);
    CGFloat centerY = CGRectGetMidY(self.bounds);

    LineEntity *entity = [[LineEntity alloc]
                          initAndSetupWithParent:self.bounds.size.width
                          parentHeight:self.bounds.size.height
                          parentCenterX:centerX
                          parentCenterY:centerY
                          parentScreenScale:self.window.screen.scale
                          width:width
                          height:height
                          bordersPadding:5.0f
                          borderStyle:self.entityBorderStyle
                          borderStrokeWidth:self.entityBorderStrokeWidth
                          borderStrokeColor:self.entityBorderColor
                          entityStrokeWidth:self.entityStrokeWidth
                          entityStrokeColor:self.entityStrokeColor
                          entityId: entityId];

    [self.motionEntities addObject:entity];
    [self onShapeSelectionChanged:entity];
    [self selectEntity:entity];
}

- (void)addCloudEntity:(NSString *)entityId width:(NSInteger)width andHeight: (NSInteger)height {
    CGFloat centerX = CGRectGetMidX(self.bounds);
    CGFloat centerY = CGRectGetMidY(self.bounds);

    CloudEntity *entity = [[CloudEntity alloc]
                          initAndSetupWithParent:self.bounds.size.width
                          parentHeight:self.bounds.size.height
                          parentCenterX:centerX
                          parentCenterY:centerY
                          parentScreenScale:self.window.screen.scale
                          width:width
                          height:height
                          bordersPadding:5.0f
                          borderStyle:self.entityBorderStyle
                          borderStrokeWidth:self.entityBorderStrokeWidth
                          borderStrokeColor:self.entityBorderColor
                          entityStrokeWidth:self.entityStrokeWidth
                          entityStrokeColor:self.entityStrokeColor
                          entityId: entityId];

    [self.motionEntities addObject:entity];
    [self onShapeSelectionChanged:entity];
    [self selectEntity:entity];
}

- (void)addTriangleEntity:(NSString *)entityId {
    CGFloat centerX = CGRectGetMidX(self.bounds);
    CGFloat centerY = CGRectGetMidY(self.bounds);

    TriangleEntity *entity = [[TriangleEntity alloc]
                              initAndSetupWithParent:self.bounds.size.width
                              parentHeight:self.bounds.size.height
                              parentCenterX:centerX
                              parentCenterY:centerY
                              parentScreenScale:self.window.screen.scale
                              width:300
                              height:300
                              bordersPadding:5.0f
                              borderStyle:self.entityBorderStyle
                              borderStrokeWidth:self.entityBorderStrokeWidth
                              borderStrokeColor:self.entityBorderColor
                              entityStrokeWidth:self.entityStrokeWidth
                              entityStrokeColor:self.entityStrokeColor
                              entityId: entityId];

    [self.motionEntities addObject:entity];
    [self onShapeSelectionChanged:entity];
    [self selectEntity:entity];
}

- (void)addArrowEntity:(NSString *)entityId {
    CGFloat centerX = CGRectGetMidX(self.bounds);
    CGFloat centerY = CGRectGetMidY(self.bounds);

    ArrowEntity *entity = [[ArrowEntity alloc]
                              initAndSetupWithParent:self.bounds.size.width
                              parentHeight:self.bounds.size.height
                              parentCenterX:centerX
                              parentCenterY:centerY
                              parentScreenScale:self.window.screen.scale
                              width:300
                              height:300
                              bordersPadding:5.0f
                              borderStyle:self.entityBorderStyle
                              borderStrokeWidth:self.entityBorderStrokeWidth
                              borderStrokeColor:self.entityBorderColor
                              entityStrokeWidth:self.entityStrokeWidth
                              entityStrokeColor:self.entityStrokeColor
                              entityId: entityId];

    [self.motionEntities addObject:entity];
    [self onShapeSelectionChanged:entity];
    [self selectEntity:entity];
}

- (void)addTextEntity:(NSString *)entityId fontType:(NSString *)fontType withFontSize: (NSNumber *)fontSize withText: (NSString *)text {
    CGFloat centerX = CGRectGetMidX(self.bounds);
    CGFloat centerY = CGRectGetMidY(self.bounds);

    TextEntity *entity = [[TextEntity alloc]
                           initAndSetupWithParent:self.bounds.size.width
                           parentHeight:self.bounds.size.height
                           parentCenterX:centerX
                           parentCenterY:centerY
                           parentScreenScale:self.window.screen.scale
                           text:text
                           fontType:fontType
                           fontSize:[fontSize floatValue]
                           bordersPadding:5.0f
                           borderStyle:self.entityBorderStyle
                           borderStrokeWidth:self.entityBorderStrokeWidth
                           borderStrokeColor:self.entityBorderColor
                           entityStrokeWidth:self.entityStrokeWidth
                           entityStrokeColor:self.entityStrokeColor
                           entityId: entityId];

    [self.motionEntities addObject:entity];
    [self onShapeSelectionChanged:entity];
    [self selectEntity:entity];
}

- (void)selectEntity:(MotionEntity *)entity {
    if (self.selectedEntity) {
        [self.selectedEntity setIsSelected:NO];
        [self.selectedEntity setNeedsDisplay];
    }
    if (entity) {
        [entity setIsSelected:YES];
        [entity setNeedsDisplay];
        [self setFrozenImageNeedsUpdate];
        [self setNeedsDisplayInRect:entity.bounds];
    } else {
        [self setNeedsDisplay];
    }
    self.selectedEntity = entity;
}

- (void)positionSelectedEntity:(CGPoint)point {
    if (self.selectedEntity) {
        [self.selectedEntity moveEntityTo:point];
    }
}

- (void)updateSelectionOnTapWithLocationPoint:(CGPoint)tapLocation {
    MotionEntity *nextEntity = [self findEntityAtPointX:tapLocation.x andY:tapLocation.y];
    [self onShapeSelectionChanged:nextEntity];
    [self selectEntity:nextEntity];
}

- (MotionEntity *)findEntityAtPointX:(CGFloat)x andY: (CGFloat)y {
    MotionEntity *nextEntity = nil;
    CGPoint point = CGPointMake(x, y);
    for (MotionEntity *entity in self.motionEntities) {
        if ([entity isPointInEntity:point]) {
            nextEntity = entity;
            break;
        }
    }
    return nextEntity;
}

- (void)releaseSelectedEntity {
    MotionEntity *entityToRemove = nil;
    for (MotionEntity *entity in self.motionEntities) {
        if ([entity isSelected]) {
            entityToRemove = entity;
            break;
        }
    }
    if (entityToRemove) {
        [self.motionEntities removeObject:entityToRemove];
        [entityToRemove removeFromSuperview];
        entityToRemove = nil;
        [self selectEntity:entityToRemove];
        [self onShapeSelectionChanged:nil];
    }
}

- (void)deleteEntityById: (NSString *)entityId {
    MotionEntity *entityToRemove = nil;
    for (MotionEntity *entity in self.motionEntities) {
        if ([entity entityHasId:entityId]) {
            entityToRemove = entity;
            break;
        }
    }
    if (entityToRemove) {
        [self.motionEntities removeObject:entityToRemove];
        [entityToRemove removeFromSuperview];
        entityToRemove = nil;
        [self selectEntity:entityToRemove];
        [self onShapeSelectionChanged:nil];
    }
}

- (void)unselectShape {
    [self selectEntity:nil];
}

- (void)increaseTextEntityFontSize {
    TextEntity *textEntity = [self getSelectedTextEntity];
    if (textEntity) {
        [textEntity updateFontSize:textEntity.fontSize + 1];
        [textEntity setNeedsDisplay];
    }
}

- (void)decreaseTextEntityFontSize {
    TextEntity *textEntity = [self getSelectedTextEntity];
    if (textEntity) {
        [textEntity updateFontSize:textEntity.fontSize - 1];
        [textEntity setNeedsDisplay];
    }
}

- (void)setTextEntityText:(NSString *)newText {
    TextEntity *textEntity = [self getSelectedTextEntity];
    if (textEntity && newText && [newText length] > 0) {
        [textEntity updateText:newText];
        [textEntity setNeedsDisplay];
    }
}

- (TextEntity *)getSelectedTextEntity {
    if (self.selectedEntity && [self.selectedEntity isKindOfClass:[TextEntity class]]) {
        return (TextEntity *)self.selectedEntity;
    } else {
        return nil;
    }
}

#pragma mark - UIGestureRecognizers
- (void)handleTap:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        CGPoint tapLocation = [sender locationInView:sender.view];
        [self updateSelectionOnTapWithLocationPoint:tapLocation];
    }
}

- (void)handleRotate:(UIRotationGestureRecognizer *)sender {
    UIGestureRecognizerState state = [sender state];
    if (state == UIGestureRecognizerStateBegan || state == UIGestureRecognizerStateChanged) {
        if (self.selectedEntity) {
            [self.selectedEntity rotateEntityBy:sender.rotation];
            NSString *transformString = NSStringFromCGAffineTransform(self.selectedEntity.transform);
            NSString *centerString = NSStringFromCGPoint(self.selectedEntity.center);
            [self notifyShapePositionUpdate: transformString center: centerString];
            [self setNeedsDisplayInRect:self.selectedEntity.bounds];
        }
        [sender setRotation:0.0];
    }
}

- (void)handleMove:(UIPanGestureRecognizer *)sender {
    UIGestureRecognizerState state = [sender state];
    if (self.selectedEntity) {
        if (state != UIGestureRecognizerStateCancelled) {
            CGPoint nextPosition = [sender translationInView:self.selectedEntity];
            [self.selectedEntity moveEntityTo: nextPosition];
            NSString *transformString = NSStringFromCGAffineTransform(self.selectedEntity.transform);
            NSString *centerString = NSStringFromCGPoint(self.selectedEntity.center);
            [self notifyShapePositionUpdate: transformString center: centerString];
            [sender setTranslation:CGPointZero inView:sender.view];
            [self setNeedsDisplayInRect:self.selectedEntity.bounds];
        }
    }
}

// Via https://stackoverflow.com/a/18048582/1297243
- (void) handleScale:(UIPinchGestureRecognizer *)pinchRecognizer
{
    if ([pinchRecognizer state] == UIGestureRecognizerStateBegan || [pinchRecognizer state] == UIGestureRecognizerStateChanged) {

        if ([pinchRecognizer numberOfTouches] > 1) {

            UIView *theView = [pinchRecognizer view];

            CGPoint locationOne = [pinchRecognizer locationOfTouch:0 inView:theView];
            CGPoint locationTwo = [pinchRecognizer locationOfTouch:1 inView:theView];

            double slope = 0;
            if (locationOne.x == locationTwo.x) {
                // perfect vertical line
                // not likely, but to avoid dividing by 0 in the slope equation
                slope = 1000.0;
            } else if (locationOne.y == locationTwo.y) {
                // perfect horz line
                // not likely, but to avoid any problems in the slope equation
                slope = 0.0;
            } else {
                slope = (locationTwo.y - locationOne.y)/(locationTwo.x - locationOne.x);
            }
            double abSlope = ABS(slope);

            if (abSlope < 0.5) {
                if (self.selectedEntity) {
                    [self.selectedEntity scaleEntityByX:pinchRecognizer.scale y:1.0];
                    [self setNeedsDisplayInRect:self.selectedEntity.bounds];
                }
                [pinchRecognizer setScale:1.0];
            } else if (abSlope > 1.7) {
                if (self.selectedEntity) {
                    [self.selectedEntity scaleEntityByX:1.0 y:pinchRecognizer.scale];
                    [self setNeedsDisplayInRect:self.selectedEntity.bounds];
                }
                [pinchRecognizer setScale:1.0];
            } else {
                if (self.selectedEntity) {
                    [self.selectedEntity scaleEntityByX:pinchRecognizer.scale y:pinchRecognizer.scale];
                    [self setNeedsDisplayInRect:self.selectedEntity.bounds];
                }
                [pinchRecognizer setScale:1.0];
            }  // else for diagonal pinch
            NSString *transformString = NSStringFromCGAffineTransform(self.selectedEntity.transform);
            NSString *centerString = NSStringFromCGPoint(self.selectedEntity.center);
            [self notifyShapePositionUpdate: transformString center: centerString];
        }  // if numberOfTouches
    }  // StateBegan if
}

- (NSString *) colorToString:(UIColor *) color {
    CGFloat red, green, blue, alpha;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    return [NSString stringWithFormat:@"#%02x%02x%02x", (int)(red * 255), (int)(green * 255) , (int)(blue * 255)];
}

#pragma mark - Outgoing events
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo: (void *) contextInfo {
    if (_onChange) {
        _onChange(@{ @"success": error != nil ? @NO : @YES });
    }
}

- (void)notifyPathsUpdate {
    if (_onChange) {
        _onChange(@{ @"pathsUpdate": @(_paths.count) });
    }
}

- (void)notifyShapePositionUpdate: (NSString *)transform center:(NSString *)center {
    if (_onChange) {
        _onChange(@{@"shapePositionUpdate": @YES, @"shapeID": _selectedEntity.entityId, @"transform": transform, @"center": center});
    }
}

- (void)notifyShapeColourUpdate: (UIColor *)colour {
    if (_onChange && _selectedEntity) {
        NSString* colourString = [self colorToString: colour];
        _onChange(@{@"shapeColourUpdate": @YES, @"shapeID": _selectedEntity.entityId, @"colour": colourString});
    }
}

- (void)onShapeSelectionChanged:(MotionEntity *)nextEntity {
    BOOL isShapeSelected = NO;
    if (nextEntity) {
        isShapeSelected = YES;
    }
    if (_onChange) {
        if (isShapeSelected) {
            _onChange(@{ @"isShapeSelected": @YES });
        } else {
            // Add delay!
            _onChange(@{ @"isShapeSelected": @NO });
        }
    }
}

@end
