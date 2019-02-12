//
//  KCVideoManager.m
//  KCVideoUtil
//
//  Created by Erica on 2018/8/8.
//  Copyright © 2018年 Erica. All rights reserved.
//

#import "KCVideoRecorder.h"

#import "KCVideoCamera.h"
#import "KCVideoWriter.h"
#import "KCVideoCaptureView.h"
#import "KCVideoProcesser.h"

@interface KCVideoRecorder()<KCVideoCameraDelegate, KCVideoWriterDelegate, KCVideoProcesserDelegate>
{
    KCVideoCaptureView *_preview;
}
@property (nonatomic,strong) KCVideoCamera *videoCamera;
@property (nonatomic,strong) KCVideoWriter *videoWriter;
@property (nonatomic,strong) KCVideoProcesser *videoProcessor;

@end

@implementation KCVideoRecorder

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSTimeInterval)currentRecordDuration
{
    
    return self.videoWriter.duration;
    
}

- (BOOL)isRecording
{
    return _recordState == KCVideoRecordRecording;
}

- (void)startPreview
{

    [self.videoCamera startCapture];
    
}

- (void)stopPreview
{
    [self.videoCamera stopCapture];
}

- (void)startRecordVideo:(NSURL *)url
{
    
    if (self.isRecording) {
        return;
    }
    
    unlink(url.path.UTF8String);
    [self.videoWriter startWriting:url];
    
    _recordState = KCVideoRecordRecording;
    !self.recordStatusDidChangedBlock ? : self.recordStatusDidChangedBlock(self, self.isRecording);
    
}

- (void)stopRecordVideo:(void(^)(NSTimeInterval duration))completion {
    
    if (_recordState == KCVideoRecordStopped) {
        return;
    }
    
    __weak __typeof(&*self)weakSelf = self;
    
    [self.videoWriter finishWriting:^(NSTimeInterval duration) {
        dispatch_async(dispatch_get_main_queue(), ^{

            !completion ? : completion(duration);

            if (weakSelf.currentRecordDuration >= weakSelf.maxRecordDuration) {

                !weakSelf.recordDidCompletedBlock ? : weakSelf.recordDidCompletedBlock(self);
            }


        });
    }];
    
    
        _recordState = KCVideoRecordStopped;
        !self.recordStatusDidChangedBlock ? : self.recordStatusDidChangedBlock(self, self.isRecording);
}

- (instancetype)initWithSessionPreset:(AVCaptureSessionPreset)sessionPreset
{
    if (self = [super init]) {
        
        self.videoCamera = [[KCVideoCamera alloc] init];
        self.videoCamera.sessionPreset = sessionPreset;
        [self.videoCamera prepareToCapture];
        self.videoCamera.delegate = self;
        self.videoWriter = [[KCVideoWriter alloc] init];
        self.videoWriter.delegate = self;
        self.videoProcessor = [[KCVideoProcesser alloc] init];
        self.videoProcessor.delegate = self;
        _preview = [[KCVideoCaptureView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        
        _preferedVideoSize = CGSizeMake(720, 1280);
        self.frameRate = 20;
        self.bitRate =  1024 * 1024;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActiveNotification) name:UIApplicationWillResignActiveNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActiveNotification) name:UIApplicationDidBecomeActiveNotification object:nil];
        
    }
    return self;
}

- (instancetype)init
{
//    self = [super init];
//    if (self) {
//
//
//        self.videoCamera = [[KCVideoCamera alloc] init];
////        self.videoCamera.sessionPreset = self.sessionPreset;
//        [self.videoCamera prepareToCapture];
//        self.videoCamera.delegate = self;
//        self.videoWriter = [[KCVideoWriter alloc] init];
//        self.videoWriter.delegate = self;
//        self.videoProcessor = [[KCVideoProcesser alloc] init];
//        self.videoProcessor.delegate = self;
//        _preview = [[KCVideoCaptureView alloc] initWithFrame:[UIScreen mainScreen].bounds];
//
//        _preferedVideoSize = CGSizeMake(720, 1280);
//        self.frameRate = 20;
//        self.bitRate =  1024 * 1024;
//
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActiveNotification) name:UIApplicationWillResignActiveNotification object:nil];
//
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActiveNotification) name:UIApplicationDidBecomeActiveNotification object:nil];
//
//
//    }
    return [self initWithSessionPreset:AVCaptureSessionPresetHigh];
}

- (void)applicationDidBecomeActiveNotification
{
    [self startPreview];
}

- (void)applicationWillResignActiveNotification
{
    [self stopPreview];
}


- (BOOL)isTorchSupport
{
    return self.videoCamera.isTorchSupport;
}

- (void)switchTorch
{
    [self.videoCamera switchTorch];
   
}

- (void)switchCamera
{
//    [_preview startBlur];
    
    [self.videoCamera switchCamera];
    
//    [_preview stopBlur];
}

- (void)setPreferedVideoSize:(CGSize)preferedVideoSize
{
    _preferedVideoSize = preferedVideoSize;
    
    self.videoWriter.preferedVideoSize = preferedVideoSize;
    
    CGRect orginRect = CGRectMake(0, 0, 1080, 1920);
    CGRect rect = AVMakeRectWithAspectRatioInsideRect(preferedVideoSize, orginRect);

    CGFloat x = rect.origin.x / orginRect.size.width;
    CGFloat y = rect.origin.y / orginRect.size.height;
    CGFloat w = rect.size.width / orginRect.size.width;
    CGFloat h = rect.size.height / orginRect.size.height;

    [self.videoProcessor setCropRegion:CGRectMake(x, y, w, h)];
    
    
}

- (void)setFrameRate:(NSInteger)frameRate
{
    self.videoWriter.preferedFrameRate = frameRate;
}
- (NSInteger)frameRate
{
    return self.videoWriter.preferedFrameRate;
}
- (void)setBitRate:(NSInteger)bitRate
{
    self.videoWriter.preferedBitRate = bitRate;
}
- (NSInteger)bitRate
{
    return self.videoWriter.preferedBitRate;
}

- (void)setTorchMode:(AVCaptureTorchMode)torchMode
{
    self.videoCamera.torchMode = torchMode;
   
}

- (AVCaptureTorchMode)torchMode
{
    return self.videoCamera.torchMode;
}

- (void)setFocusMode:(AVCaptureFocusMode)focusMode
{
    
    self.videoCamera.focusMode = focusMode;
    
}

- (AVCaptureFocusMode)focusMode
{
    return self.videoCamera.focusMode;
}

- (void)setExposureMode:(AVCaptureExposureMode)exposureMode
{
    
    self.videoCamera.exposureMode = exposureMode;
    
    
}

- (AVCaptureExposureMode)exposureMode
{
    return self.videoCamera.exposureMode;
}

- (void)setExposePointOfInterest:(CGPoint)exposePointOfInterest
{
    self.videoCamera.exposePointOfInterest = exposePointOfInterest;
    
}

- (CGPoint)exposePointOfInterest
{
    return self.videoCamera.exposePointOfInterest;
}

- (void)setFocusPointOfInterest:(CGPoint)focusPointOfInterest
{
    
    self.videoCamera.focusPointOfInterest = focusPointOfInterest;
}

- (CGPoint)focusPointOfInterest
{
    return self.videoCamera.focusPointOfInterest;
}

- (void)setISORate:(float)ISORate
{
    
    self.videoCamera.ISORate = ISORate;
   
}

- (float)ISORate
{
    
    return self.videoCamera.ISORate;
  
}

- (AVCaptureDevicePosition)cameraPosition
{
    return self.videoCamera.cameraPosition;
}

- (void)setCropRegion:(CGRect)cropRegion
{
    [self.videoProcessor setCropRegion:cropRegion];
}

- (void)setBeauty:(CGFloat)strength
{
    
    [self.videoProcessor setBeauty:strength];
}

- (void)setBasic:(CGFloat)strength
{
    
    [self.videoProcessor setBasic:strength];
}

// 设置脸萌贴纸
- (void)setStickers:(KCVideoStickers *)m
{
    
    [self.videoProcessor setStickers:m];
}


- (void)setEffectType:(KCVideoEffectType)effectType
{
    
    [self.videoProcessor setEffectType:effectType];
}

- (void)setVideoStyle:(KCVideoStyle *)m
{

    [self.videoProcessor setVideoStyle:m];
}

#pragma mark -KCVideoProcesserDelegate
- (void)didProcessSampleBuffer:(CMSampleBufferRef)sam
{
    
    [_preview renderSampleBuffer:sam];
    
    if (self.videoWriter.writing) {
        [self.videoWriter appendVideoSampleBuffer:sam];
    }
}

#pragma mark -KCVideoCameraDelegate
- (void)didOutputAudioSampleBuffer:(CMSampleBufferRef)ref
{
    
    if (self.videoWriter.writing) {
        [self.videoWriter appendAudioSampleBuffer:ref];
    }
    
}

- (void)didOutputVideoSampleBuffer:(CMSampleBufferRef)ref
{
    
    [self.videoProcessor processSampleBuffer:ref];
    
}

#pragma mark -writerDelegate
- (void)updateWriteDuration:(NSTimeInterval)duration
{
    
    [self updateRecordDuration:duration];
}

- (void)updateRecordDuration:(NSTimeInterval)second
{
    
    if (!self.isRecording) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        !self.recordDurationDidChangedBlock ? : self.recordDurationDidChangedBlock(self, self.maxRecordDuration, self.currentRecordDuration);
        
    });
    
    if (self.maxRecordDuration && self.currentRecordDuration >= self.maxRecordDuration) {
        
        [self stopRecordVideo:nil];
        
    }
    
}

- (void)pauseRecordVideo
{
    if (!self.isRecording) {
        return;
    }
    self.videoWriter.writing = NO;
    _recordState = KCVideoRecordPaused;
    !self.recordStatusDidChangedBlock ? : self.recordStatusDidChangedBlock(self, self.isRecording);
}
- (void)resumeRecordVideo
{
    if (self.isRecording) {
        return;
    }
    self.videoWriter.writing = YES;
    _recordState = KCVideoRecordRecording;
    !self.recordStatusDidChangedBlock ? : self.recordStatusDidChangedBlock(self, self.isRecording);
}


@end
