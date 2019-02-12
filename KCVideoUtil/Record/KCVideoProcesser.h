//
//  KCVideoProcesser.h
//  KChortVideo
//
//  Created by Erica on 2018/8/7.
//  Copyright © 2018年 Erica. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import "KCVideoMacro.h"
#import <GPUImage/GPUImageFramework.h>

@class KCVideoProcesser;

@protocol KCVideoProcesserDelegate <NSObject>

@optional
- (void)didProcessSampleBuffer:(CMSampleBufferRef)sampleBuffer;
- (void)didProcessPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end

@interface KCVideoProcesser : NSObject<KCVideoEffect>

@property (nonatomic,strong) GPUImagePixelBufferInput *pixelBufferInput;
@property (nonatomic,strong) GPUImagePixelBufferOutput *pixelBufferOutput;

@property (nonatomic,weak) id<KCVideoProcesserDelegate> delegate;

- (void)processPixelBuffer:(CVPixelBufferRef)pixelBuffer forTime:(CMTime)time;

- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer;

//- (void)freeResource;

@end
