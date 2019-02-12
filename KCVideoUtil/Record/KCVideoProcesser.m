//
//  KCVideoProcesser.m
//  KChortVideo
//
//  Created by Erica on 2018/8/7.
//  Copyright © 2018年 Erica. All rights reserved.
//

#import "KCVideoProcesser.h"
#import "KCVideoEffectFilter.h"

@interface KCVideoProcesser() {
    CVPixelBufferPoolRef _pixelBufferPool;
}

@property (nonatomic,strong) CIContext *context;


@property (nonatomic,strong) KCVideoEffectFilter *effectFilter;

@end

@implementation KCVideoProcesser

- (void)dealloc
{
    [self freeResource];
    
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        EAGLContext *glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
        CIContext *context = [CIContext contextWithEAGLContext:glContext];
        self.context = context;
        
        self.effectFilter = [[KCVideoEffectFilter alloc] init];
        [self.effectFilter setEffectType:KCVideoEffectTypeBeauty | KCVideoEffectTypeStyle | KCVideoEffectTypeCrop];
    
        self.pixelBufferInput = [[GPUImagePixelBufferInput alloc] init];
        [self.pixelBufferInput addTarget:self.effectFilter];
        
        self.pixelBufferOutput = [[GPUImagePixelBufferOutput alloc] init];
        [self.effectFilter addTarget:self.pixelBufferOutput];
        
        __weak typeof(self) weakSelf = self;
        [self.pixelBufferOutput setNewFrameAvailableBlock:^(CMTime frameTime) {
            
            if ([weakSelf.delegate respondsToSelector:@selector(didProcessPixelBuffer:)]) {
                
                CVPixelBufferRef outputPixelBuffer = weakSelf.pixelBufferOutput.pixelBuffer;
                
                [weakSelf.delegate didProcessPixelBuffer:outputPixelBuffer];
            }
            
            if ([weakSelf.delegate respondsToSelector:@selector(didProcessSampleBuffer:)]) {
                
                CVPixelBufferRef outputPixelBuffer = weakSelf.pixelBufferOutput.pixelBuffer;
                
                CMSampleBufferRef outputSampleBuffer = NULL;
                CMSampleTimingInfo timingInfo = {0,};
                timingInfo.duration = kCMTimeInvalid;
                timingInfo.decodeTimeStamp = kCMTimeInvalid;
                timingInfo.presentationTimeStamp = frameTime;
                
                CMFormatDescriptionRef outputFormatDescription = NULL;
                CMVideoFormatDescriptionCreateForImageBuffer( kCFAllocatorDefault, outputPixelBuffer, &outputFormatDescription );
                
                CMSampleBufferCreateForImageBuffer( kCFAllocatorDefault, outputPixelBuffer, true, NULL, NULL, outputFormatDescription, &timingInfo, &outputSampleBuffer );
                
                
                [weakSelf.delegate didProcessSampleBuffer:outputSampleBuffer];
                
                
                if (outputFormatDescription) {
                    
                    CFRelease(outputFormatDescription);
                }
                
                if (outputSampleBuffer) {
                    
                    CFRelease(outputSampleBuffer);
                }
                
            }
            
            
            
        }];
        
        
        
    }
    return self;
}


- (void)createResourceWithPixelBuffer:(CVPixelBufferRef)pixelBuffer {

    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
    
    NSMutableDictionary*     attributes;
    attributes = [NSMutableDictionary dictionary];
    
    [attributes setObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(NSString*)kCVPixelBufferPixelFormatTypeKey];
    [attributes setObject:[NSNumber numberWithInt:width] forKey: (NSString*)kCVPixelBufferWidthKey];
    [attributes setObject:[NSNumber numberWithInt:height] forKey: (NSString*)kCVPixelBufferHeightKey];
    [attributes setObject:@(bytesPerRow) forKey:(NSString*)kCVPixelBufferBytesPerRowAlignmentKey];
    [attributes setObject:[NSDictionary dictionary] forKey:(NSString*)kCVPixelBufferIOSurfacePropertiesKey];
    
    CVPixelBufferPoolRef bufferPool = NULL;
    CVPixelBufferPoolCreate(kCFAllocatorDefault, NULL,  (__bridge CFDictionaryRef) attributes, &bufferPool);
    
    _pixelBufferPool = bufferPool;
    
    
}

- (void)freeResource
{
    if (_pixelBufferPool) {
        CVPixelBufferPoolRelease(_pixelBufferPool);
        _pixelBufferPool = NULL;
    }
}


- (void)processPixelBuffer:(CVPixelBufferRef)pixelBuffer forTime:(CMTime)time
{
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
//    CGSize size = CGSizeMake(CVPixelBufferGetBytesPerRow(pixelBuffer)/4, CVPixelBufferGetHeight(pixelBuffer));
    
//    [self.pixelBufferOutput setVideoSizde:size];
    
    [self.pixelBufferInput processCVPixelBuffer:pixelBuffer frameTime:time];
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
}

- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CMTime frameTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    [self processPixelBuffer:pixelBuffer forTime:frameTime];
    
}

/*
- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    if (_pixelBufferPool == NULL) {
        [self createResourceWithPixelBuffer:pixelBuffer];
    }
    
    CVPixelBufferRef outputPixelBuffer = NULL;
    CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, _pixelBufferPool, &outputPixelBuffer);
    
    CIImage *image = [CIImage imageWithCVImageBuffer:pixelBuffer];
    
//    [self.gammaFilter setValue:image forKey:kCIInputImageKey];
//    [self.gammaFilter setValue:@(2) forKey:@"inputPower"];
//    CIFilter *filter = self.filters.lastObject;
//    [filter setValue:image forKey:kCIInputImageKey];
    
//    [self.beautyFilter setValue:image forKey:kCIInputImageKey];
//
//    image = self.beautyFilter.outputImage;
    
    [self.context render:image toCVPixelBuffer:outputPixelBuffer];
    
    [self.context clearCaches];
    
    CMTime frameTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    
    CMSampleBufferRef outputSampleBuffer = NULL;
    
    CMSampleTimingInfo timingInfo = {0,};
    timingInfo.duration = kCMTimeInvalid;
    timingInfo.decodeTimeStamp = kCMTimeInvalid;
    timingInfo.presentationTimeStamp = frameTime;
    
    CMFormatDescriptionRef outputFormatDescription = NULL;
    CMVideoFormatDescriptionCreateForImageBuffer( kCFAllocatorDefault, outputPixelBuffer, &outputFormatDescription );
    
    CMSampleBufferCreateForImageBuffer( kCFAllocatorDefault, outputPixelBuffer, true, NULL, NULL, outputFormatDescription, &timingInfo, &outputSampleBuffer );
 
 if ([self.delegate respondsToSelector:@selector(didProcessSampleBuffer:)]) {
     [self.delegate didProcessSampleBuffer:outputSampleBuffer];
 }
    
    if (outputPixelBuffer) {
        
        CFRelease(outputPixelBuffer);
    }
    
    if (outputFormatDescription) {

        CFRelease(outputFormatDescription);
    }
    
    if (outputSampleBuffer) {
        
        CFRelease(outputSampleBuffer);
    }
    
}*/


- (void)setCropRegion:(CGRect)cropRegion
{
    [self.effectFilter setCropRegion:cropRegion];
}

- (void)setBeauty:(CGFloat)strength
{
    [self.effectFilter setBeauty:strength];
    
}

- (void)setBasic:(CGFloat)strength
{
    
    [self.effectFilter setBasic:strength];
}

// 设置脸萌贴纸
- (void)setStickers:(KCVideoStickers *)m
{
    [self.effectFilter setStickers:m];
}


- (void)setEffectType:(KCVideoEffectType)effectType
{
    [self.effectFilter setEffectType:effectType];
}

- (void)setVideoStyle:(KCVideoStyle *)m
{
    [self.effectFilter removeTarget:self.pixelBufferOutput];
    [self.effectFilter setVideoStyle:m];
    [self.effectFilter addTarget:self.pixelBufferOutput];
}

@end
