//
//  KCVideoWriter.m
//  KChortVideo
//
//  Created by Erica on 2018/8/6.
//  Copyright © 2018年 Erica. All rights reserved.
//

#import "KCVideoWriter.h"
#import <AVFoundation/AVFoundation.h>

@interface KCVideoWriter()

@property (nonatomic, strong) AVAssetWriter *writer;

@property (nonatomic, strong) AVAssetWriterInput *audioInput;
@property (nonatomic, strong) AVAssetWriterInput *videoInput;

@property (nonatomic,strong) NSURL *path;

@property (nonatomic,assign) BOOL startSession;
@property (nonatomic,strong) dispatch_queue_t writeQueue;

@property (nonatomic,assign) CMTime startTime;
@property (nonatomic,assign) CMTime videoTime;


@property (nonatomic,strong) NSMutableArray *audioSampleBufferCache;
@end

@implementation KCVideoWriter

- (NSTimeInterval)duration
{
    CMTime duration = CMTimeSubtract(self.videoTime, self.startTime);
    
    if (CMTIME_IS_VALID(duration)) {
        
        return CMTimeGetSeconds(duration);
    }else {
        
        return 0;
    }
    
}

- (NSMutableArray *)audioSampleBufferCache
{
    if (!_audioSampleBufferCache) {
        _audioSampleBufferCache = @[].mutableCopy;
    }
    return _audioSampleBufferCache;
}

- (void)writeSampleBuffer:(CMSampleBufferRef)sampleBuffer mediaType:(NSString *)mediaType
{
    // check for completion state
    if ( self.writer.status == AVAssetWriterStatusFailed ) {
        NSLog(@"video writer failure, (%@)", self.writer.error.localizedDescription);
        return;
    }
    
    if (self.writer.status == AVAssetWriterStatusCancelled) {
        NSLog(@"video writer cancelled");
        return;
    }
    
    if ( self.writer.status == AVAssetWriterStatusCompleted) {
        NSLog(@"video writer completed");
        return;
    }
    
    CFRetain(sampleBuffer);
    dispatch_async( self.writeQueue, ^{
        
            CMTime time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        
            if (self.startSession == NO && mediaType == AVMediaTypeVideo) {
                
                [self.writer startSessionAtSourceTime:time];
                self.startTime = time;
//                self.videoTime = time;
                self.startSession = YES;
                
            }
        
            if (self.startSession) {
                
                if (mediaType == AVMediaTypeVideo) {
                    
                    self.videoTime = time;
                    if ( self.videoInput.isReadyForMoreMediaData )
                    {
                        
                        BOOL success = [self.videoInput appendSampleBuffer:sampleBuffer];
                        if (!success) {
                            
                            NSLog(@"video sampleBuffer写入失败");
                            
                        }else {
                            //                            NSLog(@"%f", self.duration);
                            if ([self.delegate respondsToSelector:@selector(updateWriteDuration:)]) {
                                [self.delegate updateWriteDuration:self.duration];
                            }
                            
                        }
                    }
                    
                }else {
                    
                    if (sampleBuffer) {
                        
                        [self.audioSampleBufferCache insertObject:(__bridge id _Nonnull)(sampleBuffer) atIndex:0];
                        
                    }
                    
                    [self writeAudioSampleBufferFromCache];
                    
                    
                }
                
            }
        
            CFRelease( sampleBuffer );
        
    });
    
    
    
}

- (void)writeAudioSampleBufferFromCache
{
    CMSampleBufferRef sb;
    while ((sb = (__bridge CMSampleBufferRef)(self.audioSampleBufferCache.lastObject)) != NULL) {
        
        CMTime time =  CMSampleBufferGetPresentationTimeStamp(sb);
        
        if (CMTimeCompare(time, self.videoTime) == 1) {
            
            break;
        }
        
        if ( self.audioInput.isReadyForMoreMediaData )
        {
            BOOL success = [self.audioInput appendSampleBuffer:sb];
            
            if (!success){
                
                NSLog(@"audio sampleBuffer写入失败");
            }
            
            [self.audioSampleBufferCache removeLastObject];
        }
        
    }
}

- (void)appendAudioSampleBuffer:(CMSampleBufferRef)ref
{
    if (!_writing) {
        return;
    }
    
    if (!self.writer || !self.audioInput) {
        [self setupAudioInput];
    }
    
    
    [self writeSampleBuffer:ref mediaType:AVMediaTypeAudio];
}

- (void)appendVideoSampleBuffer:(CMSampleBufferRef)ref
{
    if (!_writing) {
        return;
    }
    
    if (!self.writer || !self.videoInput) {
        NSLog(@"videoInput 初始化失败");
        return;
    }
    
    [self writeSampleBuffer:ref mediaType:AVMediaTypeVideo];
}

- (void)setupVideoInput
{
    
    NSDictionary *videoSettings = nil;
    
//    if (!videoSettings) {
    
        int width = self.preferedVideoSize.width;
        int height = self.preferedVideoSize.height;
        videoSettings = @{ AVVideoCodecKey : AVVideoCodecH264,
                                     AVVideoScalingModeKey : AVVideoScalingModeResizeAspectFill,
                                     AVVideoWidthKey : @(width),
                                     AVVideoHeightKey : @(height),
                                     AVVideoCompressionPropertiesKey : @{
                                              AVVideoAverageBitRateKey : @(self.preferedBitRate),
                                             AVVideoExpectedSourceFrameRateKey : @(self.preferedFrameRate),
                                             AVVideoMaxKeyFrameIntervalKey : @(self.preferedFrameRate)
                                             }
                                     };
    
//    }
    if ([self.writer canApplyOutputSettings:videoSettings forMediaType:AVMediaTypeVideo]) {
        
        self.videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
        
        self.videoInput.expectsMediaDataInRealTime = YES;
        
        if ([self.writer canAddInput:self.videoInput]) {
            [self.writer addInput:self.videoInput];
        }
        
    }
    
}

- (void)setupAudioInput
{
    
    NSDictionary *audioSettings = nil;
    
//    if (!audioSettings) {
    
        audioSettings = @{ AVFormatIDKey : @(kAudioFormatMPEG4AAC),
                                         AVNumberOfChannelsKey : @(2),
                                         AVSampleRateKey :  @(44100),
                                         AVEncoderBitRateKey : @(64000)
                                         };
        
//    }
    
    if ([self.writer canApplyOutputSettings:audioSettings forMediaType:AVMediaTypeAudio]) {
        
        self.audioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioSettings];
        
        self.audioInput.expectsMediaDataInRealTime = YES;
        
        if ([self.writer canAddInput:self.audioInput]) {
            [self.writer addInput:self.audioInput];
        }
        
    }
    
}

- (void)setupWriter
{
    
    NSError *error;
    self.writer = [AVAssetWriter assetWriterWithURL:self.path fileType:AVFileTypeMPEG4 error:&error];
    
//    self.writer.movieFragmentInterval = kCMTimeInvalid;
    self.writer.shouldOptimizeForNetworkUse = YES;
    self.writer.metadata = self.metadata;
    if (error) {
        NSLog(@"error = %@", error.localizedDescription);
    }else {
        
    }
    
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.writeQueue = dispatch_queue_create( "KCVideoWriter.writing", DISPATCH_QUEUE_SERIAL );
        self.preferedVideoSize = CGSizeMake(720, 1280);
        self.preferedFrameRate = 20;
        self.preferedBitRate = 1024 * 1024;
//        self.videoTime = kCMTimeZero;
//        self.startTime = kCMTimeZero;
    }
    return self;
}

- (void)startWriting:(NSURL *)path
{
    
    dispatch_async( self.writeQueue, ^{
        if (self.writing) {
            return;
        }
    
        self.path = path;
        [self setupWriter];
        [self setupVideoInput];
        [self setupAudioInput];
        [self.writer startWriting];
        _writing = YES;
        
        
    });
    
    
}

- (void)finishWriting:(void (^)(NSTimeInterval duration))completion
{
    dispatch_async( self.writeQueue, ^{
        if (!self.writing) {
            return;
        }
        
        _writing = NO;
        
        [self writeAudioSampleBufferFromCache];
        
        [self.videoInput markAsFinished];
        [self.audioInput markAsFinished];
        [self.writer finishWriting];
        
        !completion ?  : completion(CMTimeGetSeconds(CMTimeSubtract(self.videoTime, self.startTime)));
    
        self.writer = nil;
        self.videoInput = nil;
        self.audioInput = nil;
        self.startSession = NO;
//        self.videoTime = kCMTimeZero;
//        self.startTime = kCMTimeZero;
        [self.audioSampleBufferCache removeAllObjects];
        
        
    });
}

- (void)cancelWriting
{
    dispatch_async( self.writeQueue, ^{
        if (!self.writing) {
            return;
        }
        _writing = NO;
        
        [self.videoInput markAsFinished];
        [self.audioInput markAsFinished];
        [self.writer cancelWriting];
        self.writer = nil;
        self.videoInput = nil;
        self.audioInput = nil;
        self.startSession = NO;
        [self.audioSampleBufferCache removeAllObjects];
//        self.videoTime = kCMTimeZero;
//        self.startTime = kCMTimeZero;
    });
}


@end
