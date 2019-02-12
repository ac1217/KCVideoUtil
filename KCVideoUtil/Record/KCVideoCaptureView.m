//
//  KCPreview.m
//  KCVideoUtil
//
//  Created by Erica on 2018/8/13.
//  Copyright © 2018年 Erica. All rights reserved.
//

#import "KCVideoCaptureView.h"

@interface KCVideoCaptureView()

//@property (nonatomic,strong) UIVisualEffectView *blurView;

@end

@implementation KCVideoCaptureView

//- (UIVisualEffectView *)blurView
//{
//    if (!_blurView) {
//
//        UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
//
//
//        _blurView = [[UIVisualEffectView alloc] initWithEffect:blur];
//        _blurView.alpha = 0;
//    }
//    return _blurView;
//}

//- (void)layoutSubviews
//{
//    [super layoutSubviews];

//    self.blurView.frame = self.bounds;
//}

+ (Class)layerClass
{
    return [AVSampleBufferDisplayLayer class];
}

- (AVSampleBufferDisplayLayer *)displayLayer
{
    return (AVSampleBufferDisplayLayer *)self.layer;
}


- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
//        [self addSubview:self.blurView];
        
        self.displayLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
    return self;
}

- (void)renderSampleBuffer:(CMSampleBufferRef)ref
{
//    CFRetain(ref);
//    dispatch_async(dispatch_get_main_queue(), ^{
    
        if (self.displayLayer.status == AVQueuedSampleBufferRenderingStatusFailed) {
            
            [self.displayLayer flush];
            
        }
        
        if (self.displayLayer.isReadyForMoreMediaData) {
            
            [self.displayLayer enqueueSampleBuffer:ref];
        }
        
//        CFRelease(ref);
//    });
    
}

- (void)renderPixelBuffer:(CVPixelBufferRef)ref forTime:(CMTime)time
{
    CMSampleBufferRef outputSampleBuffer = NULL;
    CMSampleTimingInfo timingInfo = {0,};
    timingInfo.duration = kCMTimeInvalid;
    timingInfo.decodeTimeStamp = kCMTimeInvalid;
    timingInfo.presentationTimeStamp = time;
    
    CMFormatDescriptionRef outputFormatDescription = NULL;
    CMVideoFormatDescriptionCreateForImageBuffer( kCFAllocatorDefault, ref, &outputFormatDescription );
    
    CMSampleBufferCreateForImageBuffer( kCFAllocatorDefault, ref, true, NULL, NULL, outputFormatDescription, &timingInfo, &outputSampleBuffer );
    
    [self renderSampleBuffer:outputSampleBuffer];
    
    if (outputFormatDescription) {
        
        CFRelease(outputFormatDescription);
    }
    
    if (outputSampleBuffer) {
        
        CFRelease(outputSampleBuffer);
    }
    
}

//- (void)startBlur
//{
//    [UIView animateWithDuration:0.25 animations:^{
//        self.blurView.alpha = 1;
//    }];
//}
//
//- (void)stopBlur
//{
//    [UIView animateWithDuration:0.25 animations:^{
//        self.blurView.alpha = 0;
//    }];
//}

@end
