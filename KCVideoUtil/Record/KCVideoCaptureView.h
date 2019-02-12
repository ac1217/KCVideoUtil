//
//  KCVideoPreview.h
//  KChortVideo
//
//  Created by Erica on 2018/8/6.
//  Copyright © 2018年 Erica. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface KCVideoCaptureView : UIView

- (void)renderSampleBuffer:(CMSampleBufferRef)ref;

- (void)renderPixelBuffer:(CVPixelBufferRef)ref forTime:(CMTime)time;

//- (void)startBlur;
//- (void)stopBlur;

@end
