//
//  YUGPUImageCVPixelBufferInput.h
//  Pods
//
//  Created by YuAo on 3/28/16.
//
//
#import <Foundation/Foundation.h>
#import "GPUImageContext.h"
#import "GPUImageOutput.h"
#import "GPUImageFilter.h"
#import "GPUImageMovieWriter.h"

@interface GPUImagePixelBufferOutput : NSObject<GPUImageInput>{
    
    CVPixelBufferRef renderTarget;
    CVOpenGLESTextureRef renderTexture;
    
    CGSize videoSize;
    GPUImageRotationMode inputRotation;
}

@property(nonatomic) BOOL enabled;
//- (void)setVideoSizde:(CGSize)size;

@property(readonly) CVPixelBufferRef pixelBuffer;

@property(nonatomic, copy) void(^newFrameAvailableBlock)(CMTime frameTime);

@end
