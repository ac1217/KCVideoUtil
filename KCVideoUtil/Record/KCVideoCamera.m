//
//  KCVideoCamera.m
//  KChortVideo
//
//  Created by Erica on 2018/8/6.
//  Copyright © 2018年 Erica. All rights reserved.
//

#import "KCVideoCamera.h"
#import <AVFoundation/AVFoundation.h>

@interface KCVideoCamera()<AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate> {
    
    BOOL _isPrepredToCapture;
    
}

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioDataOutput;
@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;
@property (nonatomic, strong) AVCaptureDeviceInput *audioInput;
@property (nonatomic, strong) AVCaptureConnection *videoConnection;


//@property (nonatomic, strong) dispatch_queue_t bufferQueue;

@property (nonatomic, strong) dispatch_queue_t videoQueue;
@property (nonatomic, strong) dispatch_queue_t audioQueue;
@end

@implementation KCVideoCamera

- (void)dealloc
{
    [self stopCapture];
    [self cancelToCapture];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)startCapture
{
        if (!self.captureSession.isRunning) {
            
            [self.captureSession startRunning];
            
            _state = KCVideoCaptureRunning;
        }
    
}

- (void)stopCapture
{
    if (self.captureSession.isRunning) {
        
        [self.captureSession stopRunning];
        
        _state = KCVideoCaptureStopped;
    }
}

- (AVCaptureDevice *)cameraDeviceWithPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devices];
    
    for (AVCaptureDevice *device in devices) {
        if (device.position == position) {
            return device;
        }
    }
    return nil;
}

- (void)setCameraPosition:(AVCaptureDevicePosition)cameraPosition
{
    _cameraPosition = cameraPosition;
    
    if (!_captureSession) {
        return;
    }
    
    AVCaptureDevice *videoDevice = [self cameraDeviceWithPosition:cameraPosition];
    
    NSError *error;
    
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    if (error) {
        return;
    }
    
    [_captureSession beginConfiguration];
    
    [_captureSession removeInput:_videoInput];
    
    if ([_captureSession canAddInput:videoInput]) {
        [_captureSession addInput:videoInput];
    }
    _videoInput = videoInput;
    
    _videoConnection =  [_videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    
    if ([_videoConnection isVideoOrientationSupported]) {
        
        [_videoConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    }
    
    if ([_videoConnection isVideoMirroringSupported]) {
        [_videoConnection setVideoMirrored:self.cameraPosition == AVCaptureDevicePositionFront];
        
    }
    
    [_captureSession commitConfiguration];
    
    
}

- (void)cancelToCapture
{
    
    if (!_isPrepredToCapture) {
        return;
    }
    
    [_captureSession beginConfiguration];
    [_captureSession removeInput:_audioInput];
    [_captureSession removeInput:_videoInput];
    [_captureSession removeOutput:_audioDataOutput];
    [_captureSession removeOutput:_videoDataOutput];
    [_captureSession commitConfiguration];
    
    _captureSession = nil;
    _audioInput = nil;
    _audioDataOutput = nil;
    _videoInput = nil;
    _videoDataOutput = nil;
    
    _isPrepredToCapture = NO;
}


- (void)prepareToCapture
{
    
    if (_isPrepredToCapture) {
        return;
    }
    
    _captureSession = [[AVCaptureSession alloc] init];
    
    [_captureSession beginConfiguration];
    
    _captureSession.sessionPreset = _sessionPreset;
//    _captureSession.sessionPreset = AVCaptureSessionPresetMedium;
    
    AVCaptureDevice *cameraDevice = [self cameraDeviceWithPosition:_cameraPosition];
    _videoInput = [[AVCaptureDeviceInput alloc]initWithDevice:cameraDevice error:nil];
    
    [cameraDevice lockForConfiguration:nil];
    cameraDevice.activeVideoMinFrameDuration = CMTimeMake(1, 30);
    cameraDevice.activeVideoMaxFrameDuration = CMTimeMake(1, 30);
    [cameraDevice unlockForConfiguration];
    
    _videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    
    _videoDataOutput.videoSettings = @{(__bridge id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA)};
    [_videoDataOutput setSampleBufferDelegate:self queue:_videoQueue];
    
    
    _audioInput = [AVCaptureDeviceInput deviceInputWithDevice: [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio] error:nil];
    
    
    _audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
    [_audioDataOutput setSampleBufferDelegate:self queue:_audioQueue];
    
    
    if ([_captureSession canAddInput:_audioInput]) {
        [_captureSession addInput:_audioInput];
    }
    
    if ([_captureSession canAddInput:_videoInput]) {
        
        [_captureSession addInput:_videoInput];
        
    }
    
    if ([_captureSession canAddOutput:_audioDataOutput]) {
        [_captureSession addOutput:_audioDataOutput];
    }
    
    
    if ([_captureSession canAddOutput:_videoDataOutput]) {
        
        [_captureSession addOutput:_videoDataOutput];
        
    }
    
    _videoConnection =  [_videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    //
    if ([_videoConnection isVideoOrientationSupported]) {
        
        [_videoConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    }
    
    if ([_videoConnection isVideoMirroringSupported]) {
        [_videoConnection setVideoMirrored:_cameraPosition == AVCaptureDevicePositionFront];
        
    }
    
    [_captureSession commitConfiguration];
    
    _isPrepredToCapture = YES;
    
}

- (BOOL)isRunning
{
    return _state == KCVideoCaptureRunning;
}

- (instancetype)init
{
    if (self = [super init]) {
        
        _cameraPosition = AVCaptureDevicePositionFront;
        
        _audioQueue = dispatch_queue_create("com.KCvideo.audio", NULL);
        
        _videoQueue = dispatch_queue_create("com.KCvideo.video", NULL);
        
        _sessionPreset = AVCaptureSessionPresetHigh;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(captureSessionInterruptionEndedNotification) name:AVCaptureSessionInterruptionEndedNotification object:nil];
    }
    return self;
    
}

//- (instancetype)initWithCameraPosition:(AVCaptureDevicePosition)position sessionPreset:(AVCaptureSessionPreset)sessionPreset
//{
//
//    if (self = [super init]) {
//
//        _cameraPosition = position;
//
//        _audioQueue = dispatch_queue_create("com.KCvideo.audio", NULL);
//
//        _videoQueue = dispatch_queue_create("com.KCvideo.video", NULL);
//
//        _sessionPreset = sessionPreset;
//
//        //        [self prepareToCapture];
//
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(captureSessionInterruptionEndedNotification) name:AVCaptureSessionInterruptionEndedNotification object:nil];
//
//    }
//    return self;
//
//}
//
//- (instancetype)initWithCameraPosition:(AVCaptureDevicePosition)position
//{
//    return [self initWithCameraPosition:position sessionPreset:AVCaptureSessionPresetHigh];
//}

- (void)captureSessionInterruptionEndedNotification
{
    if (self.isRunning) {
        [self startCapture];
    }
}

- (BOOL)isTorchSupport
{
    return _cameraPosition == AVCaptureDevicePositionBack;
}

- (void)switchTorch
{
    
    switch (self.torchMode) {
        case AVCaptureTorchModeOn:
            
            self.torchMode = AVCaptureTorchModeOff;
            
            break;
        case AVCaptureTorchModeOff:
        case AVCaptureTorchModeAuto:
            
            self.torchMode = AVCaptureTorchModeOn;
            
            break;
            
        default:
            break;
    }
}

- (void)switchCamera
{
    switch (_cameraPosition) {
        case AVCaptureDevicePositionBack:
            self.cameraPosition = AVCaptureDevicePositionFront;
            break;
        case AVCaptureDevicePositionFront:
            self.cameraPosition = AVCaptureDevicePositionBack;
            break;
            
        default:
            break;
    }
}

- (void)setTorchMode:(AVCaptureTorchMode)torchMode
{
    if([_videoInput.device lockForConfiguration:nil]) {
        
        if ([_videoInput.device isTorchModeSupported:torchMode]) {
            [_videoInput.device setTorchMode:torchMode];
        }
        
    }
    [_videoInput.device unlockForConfiguration];
}

- (AVCaptureTorchMode)torchMode
{
    return _videoInput.device.torchMode;
}

- (void)setFocusMode:(AVCaptureFocusMode)focusMode
{
    if([_videoInput.device lockForConfiguration:nil]) {
        
        if ([_videoInput.device isFocusModeSupported:focusMode]) {
            
            [_videoInput.device setFocusMode:focusMode];
        }
        
    }
    [_videoInput.device unlockForConfiguration];
    
}

- (AVCaptureFocusMode)focusMode
{
    return _videoInput.device.focusMode;
}

- (void)setExposureMode:(AVCaptureExposureMode)exposureMode
{
    if([_videoInput.device lockForConfiguration:nil]) {
        
        if ([_videoInput.device isExposureModeSupported:exposureMode]) {
            
            [_videoInput.device setExposureMode:exposureMode];
        }
        
    }
    [_videoInput.device unlockForConfiguration];
    
}

- (AVCaptureExposureMode)exposureMode
{
    return _videoInput.device.exposureMode;
}

- (void)setExposePointOfInterest:(CGPoint)exposePointOfInterest
{
    if([_videoInput.device lockForConfiguration:nil]) {
        
        if ([_videoInput.device isExposurePointOfInterestSupported]) {
            
            [_videoInput.device setExposurePointOfInterest:exposePointOfInterest];
        }
        
    }
    [_videoInput.device unlockForConfiguration];
}

- (CGPoint)exposePointOfInterest
{
    return _videoInput.device.exposurePointOfInterest;
}

- (void)setFocusPointOfInterest:(CGPoint)focusPointOfInterest
{
    
    if([_videoInput.device lockForConfiguration:nil]) {
        
        if ([_videoInput.device isFocusPointOfInterestSupported]) {
            
            
            [_videoInput.device setFocusPointOfInterest:focusPointOfInterest];
        }
        
        
    }
    [_videoInput.device unlockForConfiguration];
}

- (CGPoint)focusPointOfInterest
{
    return _videoInput.device.focusPointOfInterest;
}

- (void)setISORate:(float)ISORate
{
    
    CGFloat minISO = _videoInput.device.activeFormat.minISO;
    CGFloat maxISO = _videoInput.device.activeFormat.maxISO;
    // 调节ISO为全范围的70%
    CGFloat currentISO = (maxISO - minISO) * ISORate + minISO;
    
    if([_videoInput.device lockForConfiguration:nil]) {
        
        [_videoInput.device setExposureModeCustomWithDuration:AVCaptureExposureDurationCurrent ISO:currentISO completionHandler:nil];
    }
    [_videoInput.device unlockForConfiguration];
}

- (float)ISORate
{
    CGFloat minISO = _videoInput.device.activeFormat.minISO;
    CGFloat maxISO = _videoInput.device.activeFormat.maxISO;
    
    
    CGFloat rate = (_videoInput.device.ISO - minISO) / (maxISO - minISO);
    
    if (isnan(rate)) {
        return 0;
    }
    
    return rate;
}


- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    
    if (output == _videoDataOutput) {
        
        if ([self.delegate respondsToSelector:@selector(didOutputVideoSampleBuffer:)]) {
            
            [self.delegate didOutputVideoSampleBuffer:sampleBuffer];
        }
        
    }else if (output == _audioDataOutput) {
        
        if ([self.delegate respondsToSelector:@selector(didOutputAudioSampleBuffer:)]) {
            
            [self.delegate didOutputAudioSampleBuffer:sampleBuffer];
        }
    }
    
}

@end
