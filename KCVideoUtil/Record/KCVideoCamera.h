//
//  KCVideoCamera.h
//  KChortVideo
//
//  Created by Erica on 2018/8/6.
//  Copyright © 2018年 Erica. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSInteger, KCVideoCaptureState) {
    KCVideoCaptureStopped,
    KCVideoCaptureRunning,
    KCVideoCapturePaused
};


@class KCVideoCamera;
@protocol KCVideoCameraDelegate<NSObject>
@optional

- (void)didOutputVideoSampleBuffer:(CMSampleBufferRef)ref;
- (void)didOutputAudioSampleBuffer:(CMSampleBufferRef)ref;


@end

@interface KCVideoCamera : NSObject

@property (nonatomic, assign) id<KCVideoCameraDelegate> delegate;

- (void)prepareToCapture;
- (void)cancelToCapture;
@property (nonatomic, assign) KCVideoCaptureState state;
@property (nonatomic, assign, readonly) BOOL isRunning;

//- (instancetype)initWithCameraPosition:(AVCaptureDevicePosition)position;
//- (instancetype)initWithCameraPosition:(AVCaptureDevicePosition)position sessionPreset:(AVCaptureSessionPreset)sessionPreset;

- (void)startCapture;

- (void)stopCapture;


@property(nonatomic, copy) AVCaptureSessionPreset sessionPreset;

@property (nonatomic, assign) AVCaptureDevicePosition cameraPosition;
@property(nonatomic) AVCaptureTorchMode torchMode;
@property(nonatomic) AVCaptureExposureMode exposureMode;
@property(nonatomic) AVCaptureFocusMode focusMode;
@property(nonatomic) CGPoint focusPointOfInterest;
@property(nonatomic) CGPoint exposePointOfInterest;
@property(nonatomic) float ISORate;

@property (nonatomic,assign, readonly) BOOL isTorchSupport;

// 切换手电筒
- (void)switchTorch;
- (void)switchCamera;

@end
