//
//  KCVideoHelper.m
//  KCVideoUtil
//
//  Created by Erica on 2018/12/19.
//  Copyright © 2018 Erica. All rights reserved.
//

#import "KCVideoHelper.h"

@interface KCVideoHelper()

    
@property (nonatomic,strong) dispatch_queue_t helpQueue;


@end

@implementation KCVideoHelper

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.helpQueue = dispatch_queue_create("com.KCVideoEditor.helpQueue", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

+ (instancetype)sharedHelper {
    
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc]init];
    });
    return _sharedObject;
    
}

- (void)requestInfoWithFilePath:(NSURL *)filePath
                     completion:(void(^)(KCVideoInfo *info))completion
{
    if (!filePath) {
        NSLog(@"filepath 不能为 nil");
        return;
    }
    
    
    AVAsset *asset = [AVAsset assetWithURL:filePath];
    
    [asset loadValuesAsynchronouslyForKeys:@[@"duration", @"tracks"] completionHandler:^{
        
        KCVideoInfo *info = [KCVideoInfo new];
        info.duration = CMTimeGetSeconds(asset.duration);
        AVAssetTrack *videoTrack = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
        
        info.firstFrameImage = [self reqeustImageWithFilePath:filePath atTime:0];
        info.videoSize = videoTrack.naturalSize;
        info.frameRate = videoTrack.minFrameDuration.timescale / videoTrack.minFrameDuration.value;
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
           
            !completion ? : completion(info);
            
        });
        
    }];
    
    
}

// 同步获取某帧图像
- (CGImageRef)copyImageWithFilePath:(NSURL *)filePath atTime:(NSTimeInterval)time
{
    
    AVAsset *asset = [AVURLAsset assetWithURL:filePath];
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
    generator.appliesPreferredTrackTransform = YES;
    
    generator.requestedTimeToleranceBefore = kCMTimeZero;
    generator.requestedTimeToleranceAfter = kCMTimeZero;
    CMTime actualTime;
    
    CGImageRef cgImage = [generator copyCGImageAtTime:CMTimeMake(time * asset.duration.timescale, asset.duration.timescale) actualTime:&actualTime error:nil];
    
    return cgImage;
}

- (UIImage *)reqeustImageWithFilePath:(NSURL *)filePath atTime:(NSTimeInterval)time
{
    
    CGImageRef cgImage = [self copyImageWithFilePath:filePath atTime:time];
        
    UIImage* image = [UIImage imageWithCGImage:cgImage];
        
    CGImageRelease(cgImage);
    
    return image;
    
}

// 导出多帧图像
- (void)reqeustImagesWithFilePath:(NSURL *)filePath
                          atTimes:(NSArray *)times
                       completion:(void(^)(NSArray *images))completion
{
    dispatch_async(self.helpQueue, ^{
        
        NSMutableArray *images = @[].mutableCopy;
        for (NSNumber *t in times) {
            
            NSTimeInterval time = [t doubleValue];
            
            CGImageRef cgImage = [self copyImageWithFilePath:filePath atTime:time];
            
            UIImage* image = [UIImage imageWithCGImage:cgImage];
            
            CGImageRelease(cgImage);
            
            [images addObject:image];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            !completion ? : completion(images);
        });
        
    });
}


- (GLuint)textureWithPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    [GPUImageContext useImageProcessingContext];
    
    int width = CVPixelBufferGetWidth(pixelBuffer);
    int height = CVPixelBufferGetWidth(pixelBuffer);
    
    CVOpenGLESTextureRef textureRef = 0;
    CVReturn cvRet = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                                  [GPUImageContext sharedImageProcessingContext].coreVideoTextureCache,
                                                                  pixelBuffer,
                                                                  NULL,
                                                                  GL_TEXTURE_2D,
                                                                  GL_RGBA,
                                                                  width,
                                                                  height,
                                                                  GL_BGRA,
                                                                  GL_UNSIGNED_BYTE,
                                                                  0,
                                                                  &textureRef);
    
    if (!textureRef || kCVReturnSuccess != cvRet) {
        
        NSLog(@"CVOpenGLESTextureCacheCreateTextureFromImage %d" , cvRet);
        
        return NO;
    }
    
    GLuint texture = CVOpenGLESTextureGetName(textureRef);
    glBindTexture(GL_TEXTURE_2D , texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glBindTexture(GL_TEXTURE_2D, 0);
    
    CFRelease(textureRef);
    
    return texture;
    
}


- (CVPixelBufferRef)createPixelBufferWithImage:(UIImage *)image
{
    
//    NSDictionary *options = @{
//                              (NSString*)kCVPixelBufferCGImageCompatibilityKey : @YES,
//                              (NSString*)kCVPixelBufferCGBitmapContextCompatibilityKey : @YES,
//                              (NSString*)kCVPixelBufferIOSurfacePropertiesKey: [NSDictionary dictionary]
//                              };
    
    CGImageRef cgImage = image.CGImage;
    
    CVPixelBufferRef pxbuffer = NULL;
    
    CGFloat frameWidth = CGImageGetWidth(cgImage);
    CGFloat frameHeight = CGImageGetHeight(cgImage);
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                          frameWidth,
                                          frameHeight,
                                          kCVPixelFormatType_32BGRA,
                                          NULL,
                                          &pxbuffer);
    
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(pxdata,
                                                 frameWidth,
                                                 frameHeight,
                                                 8,
                                                 CVPixelBufferGetBytesPerRow(pxbuffer),
                                                 rgbColorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    CGContextConcatCTM(context, CGAffineTransformIdentity);
    CGContextDrawImage(context, CGRectMake(0,
                                           0,
                                           frameWidth,
                                           frameHeight),
                       cgImage);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
    
}

@end
