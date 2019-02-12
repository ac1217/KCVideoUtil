//
//  KCVideoEditor.m
//  KuShow
//
//  Created by Rex Wei on 2017/5/15.
//  Copyright © 2017年 Rex. All rights reserved.
//

#import "KCVideoEditor.h"
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import <GPUImage/GPUImageFramework.h>
//#import "KCVideoAnimation.h"
#import "KCVideoFuseFilter.h"
#import "KCVideoFuse.h"
#import "KCVideoHelper.h"

@interface KCVideoEditor ()
@property (nonatomic,strong) dispatch_queue_t editQueue;
@end

@implementation KCVideoEditor

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.editQueue = dispatch_queue_create("com.KCVideoEditor.editQueue", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

+ (instancetype)sharedEditor {
    
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc]init];
    });
    return _sharedObject;
    
}


// 压缩裁剪
- (void)compressAndCutWithFilePath:(NSURL *)filePath
                  videoProgressive:(NSInteger)videoProgressive
                         frameRate:(NSInteger)frameRate
                           bitRate:(NSInteger)bitRate
                         startTime:(NSTimeInterval)startTime
                          duration:(NSTimeInterval)duration
                        outputPath:(NSURL *)outputPath
                          progress:(void(^)(float))progress
                        completion:(void(^)(NSError *error))completion
{
    
    AVAsset *asset = [AVAsset assetWithURL:filePath];
    
//    NSTimeInterval duration = CMTimeGetSeconds(asset.duration);
    
    AVAssetTrack *videoTrack = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
    
//    NSLog(@"%f", videoTrack.estimatedDataRate);
    
    AVAssetTrack *audioTrack = [asset tracksWithMediaType:AVMediaTypeAudio].firstObject;
    
    CMTimeRange videoTimeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(startTime, videoTrack.timeRange.duration.timescale),CMTimeMakeWithSeconds(duration, videoTrack.timeRange.duration.timescale));
    //        NSError *error = nil;
    AVAssetReader *reader = [AVAssetReader assetReaderWithAsset:asset error:nil];
    reader.timeRange = videoTimeRange;
    unlink(outputPath.path.UTF8String);
    AVAssetWriter *writer = [[AVAssetWriter alloc] initWithURL:outputPath fileType:AVFileTypeMPEG4 error:nil];
    
    CGSize videoSize = videoTrack.naturalSize;
    
    NSTimeInterval d = duration;
    if (d > CMTimeGetSeconds(asset.duration)) {
        d = CMTimeGetSeconds(asset.duration);
    }
    
    if (videoSize.width > videoSize.height) {
        
        if (videoSize.height > videoProgressive) {
            CGFloat videoH = videoProgressive;
            CGFloat videoW = videoH * videoSize.width / videoSize.height;
            videoSize = CGSizeMake(videoW, videoH);
        }
        
    }else if (videoSize.width < videoSize.height) {
        
        if (videoSize.width > videoProgressive) {
            CGFloat videoW = videoProgressive;
            CGFloat videoH = videoW * videoSize.height / videoSize.width;
            videoSize = CGSizeMake(videoW, videoH);
        }
        
    }else {
        
        if (videoSize.width > videoProgressive) {
            videoSize = CGSizeMake(videoProgressive, videoProgressive);
        }
        
    }
    
    NSInteger fr = videoTrack.minFrameDuration.timescale / videoTrack.minFrameDuration.value;
    
    if (frameRate > 0) {
        
        fr = MIN(frameRate, fr);
    }
    
    fr = MIN(fr, 20);
    
    NSInteger br = 2*1024*1024;
    if (bitRate > 0) {
        
        br = MIN(br,bitRate);
    }
    
    NSDictionary *videoInputSetting = @{
                                        AVVideoCodecKey:AVVideoCodecH264,
                                        AVVideoWidthKey:@(videoSize.width),
                                        AVVideoHeightKey:@(videoSize.height),
                                        AVVideoCompressionPropertiesKey: @{
                                                AVVideoAverageBitRateKey : @(br),
                                                AVVideoExpectedSourceFrameRateKey : @(fr),
                                                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
                                                
                                                },
                                        AVVideoScalingModeKey: AVVideoScalingModeResizeAspectFill
                                        
                                        };
    
    AudioChannelLayout channelLayout = {
        .mChannelLayoutTag = kAudioChannelLayoutTag_Stereo,
        .mChannelBitmap = 0,
        .mNumberChannelDescriptions = 0
    };
    
    
    NSData *channelLayoutData = [NSData dataWithBytes:&channelLayout length:offsetof(AudioChannelLayout, mChannelDescriptions)];
    
    NSDictionary *audioInputSetting = @{
                                        AVFormatIDKey: @(kAudioFormatMPEG4AAC),
                                        AVEncoderBitRateKey:@96000,
                                        AVSampleRateKey:@44100,
                                        AVChannelLayoutKey: channelLayoutData,
                                        AVNumberOfChannelsKey:@2
                                        };
    
    
    NSDictionary *videoOutputSetting = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey, nil];
    AVAssetReaderTrackOutput *videoOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:videoTrack outputSettings:videoOutputSetting];
    //        videoOutput.alwaysCopiesSampleData = NO;
    AVAssetWriterInput *videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoInputSetting];
    videoInput.transform = videoTrack.preferredTransform;
    if ([reader canAddOutput:videoOutput]) {
        [reader addOutput:videoOutput];
    }
    
    if ([writer canAddInput:videoInput]) {
        [writer addInput:videoInput];
    }
    
    
    NSDictionary *audioOutputSetting =@{AVFormatIDKey: @(kAudioFormatLinearPCM)};
    AVAssetReaderTrackOutput *audioOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:audioTrack outputSettings:audioOutputSetting];
    //        audioOutput.alwaysCopiesSampleData = NO;
    AVAssetWriterInput *audioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioInputSetting];
    
    if ([reader canAddOutput:audioOutput]) {
        [reader addOutput:audioOutput];
    }
    
    if ([writer canAddInput:audioInput]) {
        [writer addInput:audioInput];
    }
    
    [reader startReading];
    [writer startWriting];
    
    __block BOOL start = NO;
    
    dispatch_group_t group = dispatch_group_create();
    
    dispatch_group_async(group, self.editQueue, ^{
        
        CMSampleBufferRef sampleBuffer;
        while(reader.status == AVAssetReaderStatusReading && (sampleBuffer = [videoOutput copyNextSampleBuffer])) {
            
            while (!videoInput.readyForMoreMediaData) {
                [NSThread sleepForTimeInterval:0.1];
            }
            
            CMTime currentTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
            if (!start) {
                [writer startSessionAtSourceTime:currentTime];
                start = YES;
            }
            
            [videoInput appendSampleBuffer:sampleBuffer];
            CFRelease(sampleBuffer);
            dispatch_async(dispatch_get_main_queue(), ^{
                
                !progress ? : progress((CMTimeGetSeconds(currentTime) - startTime)/d);
            });
            
        }
        [videoInput markAsFinished];
    });
    
    dispatch_group_async(group, self.editQueue, ^{
        
        while (!start) {
            [NSThread sleepForTimeInterval:0.1];
        }
        
        CMSampleBufferRef sampleBuffer;
        while(reader.status == AVAssetReaderStatusReading && (sampleBuffer = [audioOutput copyNextSampleBuffer])) {
            
            while (!audioInput.readyForMoreMediaData) {
                [NSThread sleepForTimeInterval:0.1];
            }
            
            [audioInput appendSampleBuffer:sampleBuffer];
            
            CFRelease(sampleBuffer);
        }
        
        [audioInput markAsFinished];
        
    });
    dispatch_group_notify(group, self.editQueue, ^{
        
        [reader cancelReading];
        [writer finishWriting];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            !completion ? : completion(writer.error);
        });
        
    });
    
    
}

// 压缩
- (void)compressWithFilePath:(NSURL *)filePath
            videoProgressive:(NSInteger)videoProgressive
                   frameRate:(NSInteger)frameRate
                     bitRate:(NSInteger)bitRate
                  outputPath:(NSURL *)outputPath
                    progress:(void(^)(float))progress
                  completion:(void(^)(NSError *error))completion
{
    
    
        AVAsset *asset = [AVAsset assetWithURL:filePath];
    [self compressAndCutWithFilePath:filePath videoProgressive:videoProgressive frameRate:frameRate bitRate:bitRate startTime:0 duration:CMTimeGetSeconds(asset.duration) outputPath:outputPath progress:progress completion:completion];
    
}

- (void)replaceAudioWithFilePath:(NSURL *)filePath audioFilePath:(NSURL *)audioFilePath audioStartTime:(NSTimeInterval)audioStartTime outputPath:(NSURL *)outputPath completion:(void(^)(NSError *error))completion
{
    dispatch_queue_t queue = self.editQueue;
    
    dispatch_async(queue, ^{
        
        AVAsset *videoAsset = [AVAsset assetWithURL:filePath];
        AVAsset *audioAsset = [AVAsset assetWithURL:audioFilePath];
        
        AVMutableComposition *composition = [AVMutableComposition composition];
        
        AVMutableCompositionTrack *compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        
        AVMutableCompositionTrack *compositionAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        
        AVAssetTrack *videoTrack = [videoAsset tracksWithMediaType:AVMediaTypeVideo].firstObject;
        CMTimeRange videoTimeRange = videoTrack.timeRange;
        
        [compositionVideoTrack insertTimeRange:videoTimeRange ofTrack:videoTrack atTime:kCMTimeInvalid error:nil];
        
        AVAssetTrack *audioTrack = [audioAsset tracksWithMediaType:AVMediaTypeVideo].firstObject;
        
        CMTimeRange audioTimeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(audioStartTime, audioAsset.duration.timescale), videoTimeRange.duration);
        
        [compositionAudioTrack insertTimeRange:audioTimeRange ofTrack:audioTrack atTime:kCMTimeInvalid error:nil];
        
        [self exportWithComposition:composition videoComposition:nil audioMix:nil outputPath:outputPath progress:nil completion:completion];
        
        
    });
}


// 裁剪
- (void)cutWithStartTime:(NSTimeInterval)startTime
                duration:(NSTimeInterval)duration
                filePath:(NSURL *)filePath
              outputPath:(NSURL *)outputPath
                progress:(void(^)(float p))progress
              completion:(void(^)(NSError *error))completion
{
    if (duration <= 0 || startTime < 0) {
        NSLog(@"开始和裁剪时长必须大于0");
        return;
    }
    
    dispatch_queue_t queue = self.editQueue;
    
    dispatch_async(queue, ^{
        
        AVAsset *videoAsset = [AVAsset assetWithURL:filePath];
        
        AVMutableComposition *composition = [AVMutableComposition composition];
        
        AVMutableCompositionTrack *compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        
        AVAssetTrack *videoTrack = [videoAsset tracksWithMediaType:AVMediaTypeVideo].firstObject;
        compositionVideoTrack.preferredTransform = videoTrack.preferredTransform;
        
//        CMTime d = kCMTimeIndefinite;
//        if (duration + startTime <= CMTimeGetSeconds(videoTrack.timeRange.duration)) {
//            d = CMTimeMakeWithSeconds(duration, videoTrack.timeRange.duration.timescale)
//        }
        
        CMTimeRange videoTimeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(startTime, videoTrack.timeRange.duration.timescale),CMTimeMakeWithSeconds(duration, videoTrack.timeRange.duration.timescale));
        
        [compositionVideoTrack insertTimeRange:videoTimeRange ofTrack:videoTrack atTime:kCMTimeInvalid error:nil];
        
        AVMutableCompositionTrack *compositionVoiceTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];

        AVAssetTrack *voiceTrack = [videoAsset tracksWithMediaType:AVMediaTypeAudio].firstObject;
        CMTimeRange voiceTimeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(startTime, voiceTrack.timeRange.duration.timescale), CMTimeMakeWithSeconds(duration, voiceTrack.timeRange.duration.timescale));

        [compositionVoiceTrack insertTimeRange:voiceTimeRange ofTrack:voiceTrack atTime:kCMTimeInvalid error:nil];
        
//        AVMutableVideoComposition* videoComposition = [AVMutableVideoComposition videoComposition];
//        videoComposition.renderSize = videoTrack.naturalSize;
//        videoComposition.frameDuration = CMTimeMake(1, 30);
//        AVMutableVideoCompositionInstruction* instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
//        instruction.timeRange = compositionVideoTrack.timeRange;
//        AVMutableVideoCompositionLayerInstruction* layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTrack];
//        instruction.layerInstructions = @[layerInstruction];
//        videoComposition.instructions = @[instruction];
        
        [self exportWithComposition:composition videoComposition:nil audioMix:nil outputPath:outputPath progress:progress completion:completion];
        
    });
}

- (void)addAudioWithFilePath:(NSURL *)filePath audioFilePath:(NSURL *)audioFilePath audioStartTime:(NSTimeInterval)audioStartTime outputPath:(NSURL *)outputPath completion:(void(^)(NSError *error))completion
{
    dispatch_queue_t queue = self.editQueue;
    
    dispatch_async(queue, ^{
        
        AVAsset *videoAsset = [AVAsset assetWithURL:filePath];
        AVAsset *audioAsset = [AVAsset assetWithURL:audioFilePath];
        
        AVMutableComposition *composition = [AVMutableComposition composition];
        
        AVMutableCompositionTrack *compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        
        AVMutableCompositionTrack *compositionVoiceTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        
        AVMutableCompositionTrack *compositionAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        
        AVAssetTrack *voiceTrack = [videoAsset tracksWithMediaType:AVMediaTypeAudio].firstObject;
        AVAssetTrack *videoTrack = [videoAsset tracksWithMediaType:AVMediaTypeVideo].firstObject;
        CMTimeRange videoTimeRange = videoTrack.timeRange;
        
        [compositionVideoTrack insertTimeRange:videoTimeRange ofTrack:videoTrack atTime:kCMTimeInvalid error:nil];
        
        [compositionVoiceTrack insertTimeRange:videoTimeRange ofTrack:voiceTrack atTime:kCMTimeInvalid error:nil];
        
        AVAssetTrack *audioTrack = [audioAsset tracksWithMediaType:AVMediaTypeAudio].firstObject;
        
        CMTimeRange audioTimeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(audioStartTime, audioAsset.duration.timescale), videoTimeRange.duration);
        
        [compositionAudioTrack insertTimeRange:audioTimeRange ofTrack:audioTrack atTime:kCMTimeInvalid error:nil];
        
        
        [self exportWithComposition:composition videoComposition:nil audioMix:nil outputPath:outputPath progress:nil completion:completion];
        
    });
    
}

- (void)revertWithFilePath:(NSURL *)filePath outputPath:(NSURL *)outputPath progress:(void(^)(float))progress completion:(void(^)(NSError *error))completion
{
    
    dispatch_queue_t queue = self.editQueue;
    
    dispatch_async(queue, ^{
        
        __block NSError *error;
        
        AVAsset *asset = [AVAsset assetWithURL:filePath];
        
        AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
        AVAssetTrack *audioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
        
        
        AVAssetReader *reader = [[AVAssetReader alloc] initWithAsset:asset error:&error];
        
        NSDictionary *readerVideoOutputSettings = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange], kCVPixelBufferPixelFormatTypeKey, nil];
        AVAssetReaderTrackOutput* readerVideoOutput;
        if (videoTrack) {
            
            readerVideoOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:videoTrack
                                                                           outputSettings:readerVideoOutputSettings];
        }
        
        AVAssetReaderTrackOutput* readerAudioOutput;
        if (audioTrack) {
            AudioChannelLayout acl;
            
            bzero( &acl, sizeof(acl));
            
            acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
            
            readerAudioOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:audioTrack
                                                                           outputSettings:@{AVFormatIDKey: @(kAudioFormatLinearPCM)}];
        }
        
        if (readerVideoOutput) {
            
            [reader addOutput:readerVideoOutput];
        }
        if (readerAudioOutput) {
            
            [reader addOutput:readerAudioOutput];
        }
        
        [reader startReading];
        
        
        unlink([outputPath.path UTF8String]);
        
        NSURL *outputURL = outputPath;
        AVAssetWriter *writer = [[AVAssetWriter alloc] initWithURL:outputURL
                                                          fileType:AVFileTypeMPEG4
                                                             error:&error];
        writer.shouldOptimizeForNetworkUse = YES;
        writer.metadata = self.metadata;
        
        AVAssetWriterInput *writerAudioInput;
        if (audioTrack) {
            
            AudioChannelLayout acl;
            
            bzero( &acl, sizeof(acl));
            
            acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
            
            NSDictionary *writerAudioOutputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                                       
                                                       [ NSNumber numberWithInt: kAudioFormatMPEG4AAC], AVFormatIDKey,
                                                       
                                                       [ NSNumber numberWithInt: 1 ], AVNumberOfChannelsKey,
                                                       
                                                       [ NSNumber numberWithFloat: [AVAudioSession sharedInstance].sampleRate], AVSampleRateKey,
                                                       
                                                       [ NSData dataWithBytes: &acl length: sizeof( acl ) ], AVChannelLayoutKey,
                                                       
                                                       [ NSNumber numberWithInt: 64000 ], AVEncoderBitRateKey,
                                                       
                                                       nil];
            writerAudioInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:writerAudioOutputSettings];
            [writerAudioInput setExpectsMediaDataInRealTime:YES];
            
            
        }
        
        AVAssetWriterInput *writerVideoInput;
        AVAssetWriterInputPixelBufferAdaptor *pixelBufferAdaptor;
        if (videoTrack) {
            NSDictionary *videoCompressionProps = [NSDictionary dictionaryWithObjectsAndKeys:
                                                   @(videoTrack.estimatedDataRate), AVVideoAverageBitRateKey,
                                                   nil];
            NSDictionary *writerVideoOutputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                                       AVVideoCodecH264, AVVideoCodecKey,
                                                       [NSNumber numberWithInt:videoTrack.naturalSize.width], AVVideoWidthKey,
                                                       [NSNumber numberWithInt:videoTrack.naturalSize.height], AVVideoHeightKey,
                                                       videoCompressionProps, AVVideoCompressionPropertiesKey,
                                                       nil];
            
            
            
            writerVideoInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo
                                                              outputSettings:writerVideoOutputSettings
                                                            sourceFormatHint:(__bridge CMFormatDescriptionRef)[videoTrack.formatDescriptions lastObject]];
            
            
            [writerVideoInput setExpectsMediaDataInRealTime:YES];
            
            writerVideoInput.transform = videoTrack.preferredTransform;
            pixelBufferAdaptor = [[AVAssetWriterInputPixelBufferAdaptor alloc] initWithAssetWriterInput:writerVideoInput sourcePixelBufferAttributes:nil];
            
        }
        
        if (writerVideoInput) {
            
            [writer addInput:writerVideoInput];
        }
        if (writerAudioInput) {
            
            [writer addInput:writerAudioInput];
        }
        
        [writer startWriting];
        
        __block CMSampleBufferRef videoSample;
        __block CMTime sampleTime = kCMTimeZero;
        while((videoSample = [readerVideoOutput copyNextSampleBuffer])) {
            CMTime videoTime =  CMSampleBufferGetPresentationTimeStamp(videoSample);
      
            sampleTime = videoTime;
            CFRelease(videoSample);
            break;
            
        }
        
        [writer startSessionAtSourceTime:sampleTime];
        
        
        dispatch_group_t group = dispatch_group_create();
        
        
            dispatch_group_enter(group);
            dispatch_async(queue, ^{
                
                CMSampleBufferRef audioSample;
                while((audioSample = [readerAudioOutput copyNextSampleBuffer])) {
                    
                    while (!writerAudioInput.readyForMoreMediaData) {
                        [NSThread sleepForTimeInterval:0.1];
                    }
                    
                    [writerAudioInput appendSampleBuffer:audioSample];
                    
                    CFRelease(audioSample);
                }
                [writerAudioInput markAsFinished];
                dispatch_group_leave(group);
              
            });
        
            CMTime duration = videoTrack.timeRange.duration;
            
            NSInteger length = 5;
            
            CMTime endTime = duration;
            
            CMTime lengthDuration =  CMTimeMakeWithSeconds(length, duration.timescale);
            
            NSMutableArray *videoSamples = @[].mutableCopy;
            
            for (NSInteger i = 0; i < CMTimeGetSeconds(duration); i+=length) {
                
                CMTimeRange timeRange = CMTimeRangeMake(CMTimeSubtract(endTime, lengthDuration), lengthDuration);
                
//                NSLog(@"start = %f--- end = %f", CMTimeGetSeconds(timeRange.start), CMTimeGetSeconds(endTime));
                
                if (!CMTimeRangeContainsTimeRange(videoTrack.timeRange, timeRange)) {
                    
                    timeRange = CMTimeRangeMake(kCMTimeZero, endTime);
                }
                
                AVMutableComposition *subAsset = [[AVMutableComposition alloc]init];
                AVMutableCompositionTrack *subTrack =   [subAsset addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
                
                [subTrack insertTimeRange:timeRange ofTrack:videoTrack atTime:kCMTimeZero error:nil];
                
                AVAssetReaderOutput *inReaderOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:subTrack outputSettings:readerVideoOutputSettings];
                
                AVAssetReader *inReader = [[AVAssetReader alloc] initWithAsset:subAsset error:&error];
                if([inReader canAddOutput:inReaderOutput]){
                    [inReader addOutput:inReaderOutput];
                } else {
                    continue;
                }
                [inReader startReading];
                
                CMSampleBufferRef sample;
                while((sample = [inReaderOutput copyNextSampleBuffer])) {
                    
                    [videoSamples addObject:(__bridge id _Nonnull)(sample)];
                    
                    CFRelease(sample);
                }
                
                for (NSInteger i = videoSamples.count - 1; i >= 0; i--) {
                    
                    CMTime time =  sampleTime;
                    
                    CMSampleBufferRef sample = (__bridge CMSampleBufferRef)(videoSamples[i]);
                    
                    CVPixelBufferRef imageBufferRef = CMSampleBufferGetImageBuffer(sample);
                    
                    while (!writerVideoInput.readyForMoreMediaData) {
                        [NSThread sleepForTimeInterval:0.1];
                    }
                    
                    [pixelBufferAdaptor appendPixelBuffer:imageBufferRef withPresentationTime:time];
                    
                    if ((videoSample = [readerVideoOutput copyNextSampleBuffer])) {
                        
                        sampleTime =  CMSampleBufferGetPresentationTimeStamp(videoSample);
                        CFRelease(videoSample);
                    }else {
                        break;
                    }
                    
                    
                }
                
                [videoSamples removeAllObjects];
                
                endTime = timeRange.start;
                
            }
        [writerVideoInput markAsFinished];
        
    
        dispatch_group_notify(group, queue, ^{
        
         [writer finishWriting];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(writer.error);
            });
            
            
        });
    
    });
    
}



// 导出融合MV


// 导出融合MV
/*
- (void)exportWithVideoFuses:(NSArray *)vfs
                   videoSize:(CGSize)videoSize
            placeholderImage:(UIImage *)placeholderImage
                    isCancel:(BOOL *)isCancel
                  outputPath:(NSURL *)outputPath
                    progress:(void(^)(float p))progress
                  completion:(void(^)(NSError *error))completion
{
    
    //    dispatch_async(self.editQueue, ^{
    
    
    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"KCVideoUtil_VideoFuseTemp.mp4"];
    
    NSURL *tempURL = [NSURL fileURLWithPath:tempPath];
    unlink(tempURL.path.UTF8String);
    
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_async(group, self.editQueue, ^{
        KCVideoFuseFilter *filter = [[KCVideoFuseFilter alloc] init];
        filter.coordinates = [vfs valueForKeyPath:@"coordinate"];
        [filter forceProcessingAtSize:videoSize];
        
        GPUImageFilter *rotationFilter = [[GPUImageFilter alloc] init];
        
        NSMutableArray *readers = @[].mutableCopy;
        NSMutableArray *readerVideoTrackOutputs = @[].mutableCopy;
        NSMutableArray *fillModes = @[].mutableCopy;
        NSTimeInterval maxDuration = 0;
        filter.fillModes = fillModes;
        //            CVPixelBufferRef placeholderPixelBuffer = [self pixelBufferWithImage:placeholderImage];
        CVPixelBufferRef placeholderPixelBuffer = NULL;
        
        UIImage *pi = placeholderImage;
        
        if (!pi) {
            
            CGRect rect = CGRectMake(0, 0, 1, 1);
            
            UIGraphicsBeginImageContext(rect.size);
            
            CGContextRef context  = UIGraphicsGetCurrentContext();
            CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
            CGContextFillRect(context, rect);
            UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            pi = img;
        }
        
        //            if (placeholderImage) {
        
        GPUImagePicture *pic = [[GPUImagePicture alloc] initWithImage:pi];
        
        GPUImageRawDataOutput *output = [[GPUImageRawDataOutput alloc] initWithImageSize:pi.size resultsInBGRAFormat:YES];
        
        [pic addTarget:output];
        [pic processImage];
        [output lockFramebufferForReading];
        
        //从 GPUImageRawDataOutput 中获取 CVPixelBufferRef
        GLubyte *outputBytes = [output rawBytesForImage];
        NSInteger bytesPerRow = [output bytesPerRowInOutput];
        
        
        CVPixelBufferRef pixelBuffer = NULL;
        //            CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, [pixelBufferInput pixelBufferPool], &pixelBuffer);
        CVPixelBufferCreateWithBytes(kCFAllocatorDefault, pi.size.width, pi.size.height, kCVPixelFormatType_32BGRA, outputBytes, bytesPerRow, nil, nil, nil, &pixelBuffer);
        
        [output unlockFramebufferAfterReading];
        
        placeholderPixelBuffer = pixelBuffer;
        //            }else {
        //
        //            }
        
        for (int i = 0; i < vfs.count; i++) {
            KCVideoFuse *vf = vfs[i];
            
            if (vf.URL) {
                AVAsset *asset = [AVAsset assetWithURL:vf.URL];
                NSError *error = nil;
                AVAssetReader *assetReader = [AVAssetReader assetReaderWithAsset:asset error:&error];
                NSTimeInterval duration = CMTimeGetSeconds(asset.duration);
                if (duration > maxDuration) {
                    maxDuration = duration;
                }
                
                NSMutableDictionary *videoOutputSettings = [NSMutableDictionary dictionary];
                [videoOutputSettings setObject:@(kCVPixelFormatType_32BGRA) forKey:(id)kCVPixelBufferPixelFormatTypeKey];
                
                AVAssetReaderTrackOutput *readerVideoTrackOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:[[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] outputSettings:videoOutputSettings];
                
                readerVideoTrackOutput.alwaysCopiesSampleData = NO;
                [assetReader addOutput:readerVideoTrackOutput];
                [readerVideoTrackOutputs addObject:readerVideoTrackOutput];
                [readers addObject:assetReader];
                
                [assetReader startReading];
                
                [fillModes addObject:@(kGPUImageFillModePreserveAspectRatioAndFill)];
            }else {
                
                [readerVideoTrackOutputs addObject:@""];
                [readers addObject:@""];
                [fillModes addObject:@(-1)];
                
            }
            
            
        }
        
        AVAssetWriter *writer = [[AVAssetWriter alloc] initWithURL:tempURL fileType:AVFileTypeMPEG4 error:nil];
        
        //        NSMutableDictionary *settings = [[NSMutableDictionary alloc] init];
        //        [settings setObject:AVVideoCodecH264 forKey:AVVideoCodecKey];
        //        [settings setObject:[NSNumber numberWithInt:videoSize.width] forKey:AVVideoWidthKey];
        //        [settings setObject:[NSNumber numberWithInt:videoSize.height] forKey:AVVideoHeightKey];
        
        NSDictionary *videoSettings = @{ AVVideoCodecKey : AVVideoCodecH264,
                                         AVVideoScalingModeKey : AVVideoScalingModeResizeAspectFill,
                                         AVVideoWidthKey : @(videoSize.width),
                                         AVVideoHeightKey : @(videoSize.height),
                                         AVVideoCompressionPropertiesKey : @{
                                                 AVVideoAverageBitRateKey : @(2*1024*1024),
                                                 AVVideoExpectedSourceFrameRateKey : @(30),
                                                 AVVideoMaxKeyFrameIntervalKey : @(30)
                                                 }
                                         };
        
        
        AVAssetWriterInput *videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
        
        videoInput.expectsMediaDataInRealTime = YES;
        // You need to use BGRA for the video in order to get realtime encoding. I use a color-swizzling shader to line up glReadPixels' normal RGBA output with the movie input's BGRA.
        NSDictionary *sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey,
                                                               [NSNumber numberWithInt:videoSize.width], kCVPixelBufferWidthKey,
                                                               [NSNumber numberWithInt:videoSize.height], kCVPixelBufferHeightKey,
                                                               nil];
        
        AVAssetWriterInputPixelBufferAdaptor *pixelBufferInput = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoInput sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
        
        [writer addInput:videoInput];
        
        [writer startWriting];
        
        GPUImageRawDataInput *rawDataInput;
        
        GPUImageRawDataOutput *rawDataOutput = [[GPUImageRawDataOutput alloc] initWithImageSize:videoSize resultsInBGRAFormat:YES];
        
        [filter addTarget:rawDataOutput];
        
        
        __block BOOL isStart = NO;
        __weak GPUImageRawDataOutput *weakOutput = rawDataOutput;
        //        __weak typeof(self) wself = self;
        [rawDataOutput setNewFrameAvailableBlock:^(CMTime frameTime){
            
            __strong GPUImageRawDataOutput *strongOutput = weakOutput;
            //            __strong typeof(wself) strongSelf = wself;
            [strongOutput lockFramebufferForReading];
            
            //从 GPUImageRawDataOutput 中获取 CVPixelBufferRef
            GLubyte *outputBytes = [strongOutput rawBytesForImage];
            NSInteger bytesPerRow = [strongOutput bytesPerRowInOutput];
            
            
            CVPixelBufferRef pixelBuffer = NULL;
            //            CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, [pixelBufferInput pixelBufferPool], &pixelBuffer);
            CVPixelBufferCreateWithBytes(kCFAllocatorDefault, videoSize.width, videoSize.height, kCVPixelFormatType_32BGRA, outputBytes, bytesPerRow, nil, nil, nil, &pixelBuffer);
            
            [strongOutput unlockFramebufferAfterReading];
            
            if(pixelBuffer == NULL) {
                return ;
            }
            
            if (!isStart) {
                [writer startSessionAtSourceTime:frameTime];
                isStart = YES;
                
            }
            
            
            while (!videoInput.readyForMoreMediaData) {
                [NSThread sleepForTimeInterval:0.1];
            }
            
            
            [pixelBufferInput appendPixelBuffer:pixelBuffer withPresentationTime:frameTime];
            
            CFRelease(pixelBuffer);
            
        }];
        
        NSMutableArray *sampleBuffers = [NSMutableArray arrayWithCapacity:vfs.count];
        
        NSTimeInterval time = 0;
        
        while (time <= maxDuration) {
            
            if (isCancel && *isCancel) {
                break;
            }
            
            BOOL nextRound = YES;
            
            for (int i = 0; i < readerVideoTrackOutputs.count; i++) {
                
                AVAssetReaderTrackOutput *op = readerVideoTrackOutputs[i];
                
                CMSampleBufferRef ref = NULL;
                CVPixelBufferRef pixelRef = NULL;
                
                if ([op isKindOfClass:[AVAssetReaderTrackOutput class]]) {
                    
                    AVAssetReader *reader = readers[i];
                    if (reader.status != AVAssetReaderStatusReading && sampleBuffers.count > i) {
                        
                        ref = (__bridge CMSampleBufferRef)(sampleBuffers[i]);
                        
                    }else {
                        if (sampleBuffers.count > i) {
                            
                            ref = (__bridge CMSampleBufferRef)(sampleBuffers[i]);
                            
                            CMTime frameTime = CMSampleBufferGetPresentationTimeStamp(ref);
                            
                            if (time > CMTimeGetSeconds(frameTime)) {
                                
                                ref = [op copyNextSampleBuffer];
                                
                                if (ref) {
                                    if (time > CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(ref))) {
                                        nextRound = NO;
                                    }
                                    CMSampleBufferRef preRef = (__bridge CMSampleBufferRef)(sampleBuffers[i]);
                                    CFRelease(preRef);
                                    sampleBuffers[i] = (__bridge id _Nonnull)(ref);
                                }else {
                                    
                                    ref = (__bridge CMSampleBufferRef)(sampleBuffers[i]);
                                }
                                
                            }
                            
                        }else {
                            
                            ref = [op copyNextSampleBuffer];
                            if (ref) {
                                
                                sampleBuffers[i] = (__bridge id _Nonnull)(ref);
                            }
                            
                        }
                    }
                    
                    if (ref != NULL) {
                        
                        pixelRef = CMSampleBufferGetImageBuffer(ref);
                    }
                    
                }else {
                    
                    
                    pixelRef = placeholderPixelBuffer;
                    sampleBuffers[i] = @"";
                    
                }
                
                if (pixelRef != NULL) {
                    
                    CVPixelBufferRef pixelBuffer = pixelRef;
                    
                    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
                    
                    CGSize size = CGSizeMake(CVPixelBufferGetBytesPerRow(pixelBuffer)/4, CVPixelBufferGetHeight(pixelBuffer));
                    
                    if (!rawDataInput) {
                        rawDataInput = [[GPUImageRawDataInput alloc] initWithBytes:CVPixelBufferGetBaseAddress(pixelBuffer) size:size];
                    }else {
                        [rawDataInput updateDataFromBytes:CVPixelBufferGetBaseAddress(pixelBuffer) size:size];
                    }
                    
                    if ([op isKindOfClass:[AVAssetReaderTrackOutput class]]) {
                        
                        CGAffineTransform t = op.track.preferredTransform;
                        if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0){
                            // Portrait
                            [rotationFilter setInputRotation:kGPUImageRotateRight atIndex:0];
                            //                            item.rotationMode = kGPUImageRotateRight;
                            
                        }else if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0){
                            // PortraitUpsideDown
                            [rotationFilter setInputRotation:kGPUImageRotateLeft atIndex:0];
                            //                            item.rotationMode = kGPUImageRotateLeft;
                            
                        }else if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0){
                            // LandscapeLeft
                            
                            [rotationFilter setInputRotation:kGPUImageRotate180 atIndex:0];
                            
                        }else {
                            
                            [rotationFilter setInputRotation:kGPUImageNoRotation atIndex:0];
                        }
                    }else {
                        
                        [rotationFilter setInputRotation:kGPUImageNoRotation atIndex:0];
                    }
                    [rawDataInput addTarget:rotationFilter];
                    
                    [rotationFilter addTarget:filter];
                    
                    CMTime frameTime = CMTimeMakeWithSeconds(time, 10000);
                    [rawDataInput processDataForTimestamp:frameTime];
                    //                        [rawDataInput processData];
                    
                    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
                    
                    [rawDataInput removeTarget:rotationFilter];
                    [rotationFilter removeTarget:filter];
                    
                }
                
            }
            
            if (nextRound) { // 进入下一帧
                time += 0.05;
            }else { // 继续渲染当前帧
                time += 0.01;
            }
            
            !progress ? : progress(MIN(time / maxDuration, 1));
            
        }
        
        for (id ref in sampleBuffers) {
            
            CMSampleBufferRef sf = (__bridge CMSampleBufferRef)(ref);
            
            CFRelease(sf);
            
        }
        
        if (placeholderPixelBuffer) {
            
            CFRelease(placeholderPixelBuffer);
        }
        
        [sampleBuffers removeAllObjects];
        
        [filter removeTarget:rawDataOutput];
        //            [rotationFilter removeTarget:filter];
        [videoInput markAsFinished];
        [writer finishWriting];
        
    });
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    NSMutableArray *inputParameters = @[].mutableCopy;
    
    dispatch_group_async(group, self.editQueue, ^{
        
        for (int i = 0; i < vfs.count; i++) {
            
            KCVideoFuse *vf = vfs[i];
            
            AVAsset *videoAsset = [AVAsset assetWithURL:vf.URL];
            
            AVMutableCompositionTrack *compositionVoiceTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            
            AVAssetTrack *voiceTrack = [videoAsset tracksWithMediaType:AVMediaTypeAudio].firstObject;
            
            [compositionVoiceTrack insertTimeRange:voiceTrack.timeRange ofTrack:voiceTrack atTime:kCMTimeInvalid error:nil];
            
            AVMutableAudioMixInputParameters *param = [AVMutableAudioMixInputParameters audioMixInputParameters];
            [param setTrackID:voiceTrack.trackID];
            [param setVolume:vf.volume atTime:kCMTimeZero];
            
            [inputParameters addObject:param];
            
        }
        audioMix.inputParameters = inputParameters;
        
    });
    
    dispatch_group_notify(group, self.editQueue, ^{
        
        if (isCancel && *isCancel) {
            !completion ? : completion(nil);
            return;
        }
        
        AVMutableCompositionTrack *compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        
        AVAsset *tempAsset = [AVAsset assetWithURL:tempURL];
        
        AVAssetTrack *videoTrack = [tempAsset tracksWithMediaType:AVMediaTypeVideo].firstObject;
        
        [compositionVideoTrack insertTimeRange:videoTrack.timeRange ofTrack:videoTrack atTime:kCMTimeInvalid error:nil];
        
        [self exportWithComposition:composition videoComposition:nil audioMix:nil outputPath:outputPath progress:nil completion:completion];
    });
    
    
    
}*/


// 导出融合MV
- (void)exportWithVideoFuses:(NSArray *)vfs
                   videoSize:(CGSize)videoSize
            placeholderImage:(UIImage *)placeholderImage
                    isCancel:(BOOL *)isCancel
                  outputPath:(NSURL *)outputPath
                    progress:(void(^)(float p))progress
                  completion:(void(^)(NSError *error))completion
{
    
//    dispatch_async(self.editQueue, ^{
    
    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"KCVideoUtil_VideoFuseTemp.mp4"];
    
    NSURL *tempURL = [NSURL fileURLWithPath:tempPath];
    unlink(tempURL.path.UTF8String);
    
        dispatch_group_t group = dispatch_group_create();
        dispatch_group_async(group, self.editQueue, ^{
            KCVideoFuseFilter *filter = [[KCVideoFuseFilter alloc] init];
            filter.coordinates = [vfs valueForKeyPath:@"coordinate"];
            [filter forceProcessingAtSize:videoSize];
            
            GPUImageFilter *rotationFilter = [[GPUImageFilter alloc] init];
            
            NSMutableArray *fillModes = @[].mutableCopy;
            NSTimeInterval maxDuration = 0;
            filter.fillModes = fillModes;
            
            AVAssetWriter *writer = [[AVAssetWriter alloc] initWithURL:tempURL fileType:AVFileTypeMPEG4 error:nil];
            
            NSDictionary *videoSettings = @{ AVVideoCodecKey : AVVideoCodecH264,
                                             AVVideoScalingModeKey : AVVideoScalingModeResizeAspectFill,
                                             AVVideoWidthKey : @(videoSize.width),
                                             AVVideoHeightKey : @(videoSize.height),
                                             AVVideoCompressionPropertiesKey : @{
                                                     AVVideoAverageBitRateKey : @(2*1024*1024),
                                                     AVVideoExpectedSourceFrameRateKey : @(20),
                                                     AVVideoMaxKeyFrameIntervalKey : @(20)
                                                     }
                                             };
            
            
            AVAssetWriterInput *videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
            
            videoInput.expectsMediaDataInRealTime = YES;
            // You need to use BGRA for the video in order to get realtime encoding. I use a color-swizzling shader to line up glReadPixels' normal RGBA output with the movie input's BGRA.
            NSDictionary *sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey,
                                                                   [NSNumber numberWithInt:videoSize.width], kCVPixelBufferWidthKey,
                                                                   [NSNumber numberWithInt:videoSize.height], kCVPixelBufferHeightKey,
                                                                   nil];
            
            AVAssetWriterInputPixelBufferAdaptor *pixelBufferInput = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoInput sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
            
            [writer addInput:videoInput];
            
            [writer startWriting];
            
//            GPUImageRawDataInput *rawDataInput;
            
            GPUImageRawDataOutput *rawDataOutput = [[GPUImageRawDataOutput alloc] initWithImageSize:videoSize resultsInBGRAFormat:YES];
            
            [filter addTarget:rawDataOutput];
            
            
            __block BOOL isStart = NO;
            __weak GPUImageRawDataOutput *weakOutput = rawDataOutput;
            //        __weak typeof(self) wself = self;
            [rawDataOutput setNewFrameAvailableBlock:^(CMTime frameTime){
                
                if (isCancel && *isCancel) {
                    return;
                }
                
//                __strong GPUImageRawDataOutput *strongOutput = weakOutput;
                //            __strong typeof(wself) strongSelf = wself;
                [weakOutput lockFramebufferForReading];
                
                //从 GPUImageRawDataOutput 中获取 CVPixelBufferRef
                GLubyte *outputBytes = [weakOutput rawBytesForImage];
                NSInteger bytesPerRow = [weakOutput bytesPerRowInOutput];
                
                
                CVPixelBufferRef outputPixelBuffer = NULL;
                CVPixelBufferCreateWithBytes(kCFAllocatorDefault, videoSize.width, videoSize.height, kCVPixelFormatType_32BGRA, outputBytes, bytesPerRow, nil, nil, nil, &outputPixelBuffer);
                
                [weakOutput unlockFramebufferAfterReading];
                
                if(outputPixelBuffer == NULL) {
                    return ;
                }
                
                if (!isStart) {
                    [writer startSessionAtSourceTime:frameTime];
                    isStart = YES;
                    
                }
                
                while (!videoInput.readyForMoreMediaData) {
                    [NSThread sleepForTimeInterval:0.1];
                }
                
                [pixelBufferInput appendPixelBuffer:outputPixelBuffer withPresentationTime:frameTime];
                
                CFRelease(outputPixelBuffer);
                
            }];
            
            
            
            UIImage *pi = placeholderImage;
            
            if (!pi) {
                
                CGRect rect = CGRectMake(0, 0, 1, 1);
       
                UIGraphicsBeginImageContext(rect.size);
                
                CGContextRef context  = UIGraphicsGetCurrentContext();
                CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
                CGContextFillRect(context, rect);
                UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
                
                pi = img;
            }
            
            GPUImagePicture *pic = [[GPUImagePicture alloc] initWithImage:pi];

            GPUImageRawDataOutput *output = [[GPUImageRawDataOutput alloc] initWithImageSize:pi.size resultsInBGRAFormat:YES];
            
            [pic addTarget:output];
            [pic processImage];
            [output lockFramebufferForReading];

            //从 GPUImageRawDataOutput 中获取 CVPixelBufferRef
            GLubyte *outputBytes = [output rawBytesForImage];
            NSInteger bytesPerRow = [output bytesPerRowInOutput];

            CVPixelBufferRef placeholderPixelBuffer = NULL;
            CVPixelBufferCreateWithBytes(kCFAllocatorDefault, pi.size.width, pi.size.height, kCVPixelFormatType_32BGRA, outputBytes, bytesPerRow, nil, nil, nil, &placeholderPixelBuffer);

            [output unlockFramebufferAfterReading];
            [pic removeTarget:output];

            NSMutableArray *readers = @[].mutableCopy;
            NSMutableArray *readerVideoTrackOutputs = @[].mutableCopy;
            NSMutableArray *rotationModes = @[].mutableCopy;
            
            for (int i = 0; i < vfs.count; i++) {
                KCVideoFuse *vf = vfs[i];
                
                if (vf.URL && [[NSFileManager defaultManager] fileExistsAtPath:vf.URL.path]) {
                    
                    AVAsset *asset = [AVAsset assetWithURL:vf.URL];
                    
                    AVAssetTrack *videoTrack = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
                    CGAffineTransform t = videoTrack.preferredTransform;
                    GPUImageRotationMode rotationMode = kGPUImageNoRotation;
                    if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0){
                        rotationMode = kGPUImageRotateRight;
                    }else if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0){
                        rotationMode = kGPUImageRotateLeft;
                    }else if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0){
                        rotationMode = kGPUImageRotate180;
                    }else {
                        rotationMode = kGPUImageNoRotation;
                    }
                    
                    NSError *error = nil;
                    AVAssetReader *assetReader = [AVAssetReader assetReaderWithAsset:asset error:&error];
                    NSTimeInterval duration = CMTimeGetSeconds(asset.duration);
                    if (duration > maxDuration) {
                        maxDuration = duration;
                    }
                    
                    NSMutableDictionary *videoOutputSettings = [NSMutableDictionary dictionary];
                    [videoOutputSettings setObject:@(kCVPixelFormatType_32BGRA) forKey:(id)kCVPixelBufferPixelFormatTypeKey];
                    
                    AVAssetReaderTrackOutput *readerVideoTrackOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:[[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] outputSettings:videoOutputSettings];
                    
                    readerVideoTrackOutput.alwaysCopiesSampleData = NO;
                    [assetReader addOutput:readerVideoTrackOutput];
                    
                    [assetReader startReading];
                    
                    [fillModes addObject:@(kGPUImageFillModePreserveAspectRatioAndFill)];
                    [readers addObject:assetReader];
                    [readerVideoTrackOutputs addObject:readerVideoTrackOutput];
                    [rotationModes addObject:@(rotationMode)];
                    
                }else {
                    
                    [fillModes addObject:@(-1)];
                    [rotationModes addObject:@(kGPUImageNoRotation)];
                    [readers addObject:@""];
                    [readerVideoTrackOutputs addObject:@""];
                }
                
                
            }
            
            
            NSTimeInterval time = 0;
            NSMutableDictionary *sampleBuffers = @{}.mutableCopy;
            
            GPUImageRawDataInput *rawDataInput;
            GPUImageTextureInput *textureInput;
            
            while (time <= maxDuration) {
                
                if (isCancel && *isCancel) {
                    break;
                }
                
                for (int i = 0; i < readerVideoTrackOutputs.count; i++) {
                    
                    AVAssetReaderTrackOutput *op = readerVideoTrackOutputs[i];
                    
                    CVPixelBufferRef pixelBuffer = NULL;
                    
                    if ([op isKindOfClass:[AVAssetReaderTrackOutput class]]) {
                        
                        AVAssetReader *reader = readers[i];
                        
                        CMSampleBufferRef sampleBuffer = NULL;
                        
                        if (reader.status != AVAssetReaderStatusReading && sampleBuffers.count > i) {
                            
                            sampleBuffer = (__bridge CMSampleBufferRef)(sampleBuffers[@(i)]);
                            
                        }else {
                            
                            sampleBuffer = (__bridge CMSampleBufferRef)(sampleBuffers[@(i)]);
                            
                            if (!sampleBuffer) {
                                
                                sampleBuffer = [op copyNextSampleBuffer];
                                
                                sampleBuffers[@(i)] = (__bridge id _Nonnull)(sampleBuffer);
                                
                            }else {
                                
                                if (time > CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer))) {
                                    
                                    CMSampleBufferRef nextSampleBuffer = [op copyNextSampleBuffer];
                                    
                                    while (nextSampleBuffer && time > CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(nextSampleBuffer))) {
                                        
                                        CFRelease(nextSampleBuffer);
                                        nextSampleBuffer = [op copyNextSampleBuffer];
                                        
                                    }
                                    
                                    if (nextSampleBuffer) {
                                        
                                        CFRelease(sampleBuffer);
                                        sampleBuffer = nextSampleBuffer;
                                        sampleBuffers[@(i)] = (__bridge id _Nonnull)(sampleBuffer);
                                        
                                    }else {
                                        
                                        [reader cancelReading];
                                        
                                    }
                                }
                                
                            }
                            
                           
                        }
                            
                            
                        if (sampleBuffer != NULL) {
                            
                            pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
                        }
                            
                    }
                    
                    if (pixelBuffer == NULL) {
                        
                        pixelBuffer = placeholderPixelBuffer;
                        
                    }
                    
//                    runSynchronouslyOnVideoProcessingQueue(^{
                    
                    CVPixelBufferLockBaseAddress(pixelBuffer, 0);

                    CGSize size = CGSizeMake(CVPixelBufferGetBytesPerRow(pixelBuffer)/4, CVPixelBufferGetHeight(pixelBuffer));

                    if (!textureInput) {
                        
                        rawDataInput = [[GPUImageRawDataInput alloc] initWithBytes:CVPixelBufferGetBaseAddress(pixelBuffer) size:size];
                        
                    }else {
                        
                        [rawDataInput updateDataFromBytes:CVPixelBufferGetBaseAddress(pixelBuffer) size:size];
                        
                    }
                    
                    

                    GPUImageRotationMode rotationMode = [rotationModes[i]  integerValue];
                    [rotationFilter setInputRotation:rotationMode atIndex:0];

//                    [textureInput addTarget:rotationFilter];
                    [rawDataInput addTarget:rotationFilter];

                    [rotationFilter addTarget:filter];

                    CMTime frameTime = CMTimeMakeWithSeconds(time, 10000);
                    [rawDataInput processDataForTimestamp:frameTime];
//                    [textureInput processTextureWithFrameTime:frameTime];

//                    [textureInput removeTarget:rotationFilter];
                    
                    [rawDataInput removeTarget:rotationFilter];

                    [rotationFilter removeTarget:filter];

                    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
                    
//                    });
                    
//                    [[GPUImageContext sharedFramebufferCache] purgeAllUnassignedFramebuffers];
                    
                }
                
                time += 0.05;
                
//                glFinish();
//                CVOpenGLESTextureCacheFlush([GPUImageContext sharedImageProcessingContext].coreVideoTextureCache,0);
                
                !progress ? : progress(MIN(time / maxDuration, 1));
                
            }
            
            // 60s 0.1 37s;
            // 60s 0.05 105s;
            
            // 720p n6 8s 0.05 6.32s;
            // 720p n6 8s 0.1 4.56s;
            // 720p n6 8s 0.5 2.82s;
            
            for (id ref in sampleBuffers) {

                CMSampleBufferRef sf = (__bridge CMSampleBufferRef)(ref);

                CFRelease(sf);

            }
            
            [sampleBuffers removeAllObjects];
            
//            [[GPUImageContext sharedImageProcessingContext].framebufferCache purgeAllUnassignedFramebuffers];
            
            if (placeholderPixelBuffer) {
                
                CFRelease(placeholderPixelBuffer);
            }
            
            [filter removeTarget:rawDataOutput];
            [rotationFilter removeTarget:filter];
            [videoInput markAsFinished];
            [writer finishWriting];
            
        });
       
        AVMutableComposition *composition = [AVMutableComposition composition];
        
        AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
        NSMutableArray *inputParameters = @[].mutableCopy;
        
        dispatch_group_async(group, self.editQueue, ^{
            
            for (int i = 0; i < vfs.count; i++) {
                
                KCVideoFuse *vf = vfs[i];
                
                AVAsset *videoAsset = [AVAsset assetWithURL:vf.URL];
                
                AVMutableCompositionTrack *compositionVoiceTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
                
                AVAssetTrack *voiceTrack = [videoAsset tracksWithMediaType:AVMediaTypeAudio].firstObject;
                
                [compositionVoiceTrack insertTimeRange:voiceTrack.timeRange ofTrack:voiceTrack atTime:kCMTimeInvalid error:nil];
                
                AVMutableAudioMixInputParameters *param = [AVMutableAudioMixInputParameters audioMixInputParameters];
                [param setTrackID:voiceTrack.trackID];
                [param setVolume:vf.volume atTime:kCMTimeZero];
                
                [inputParameters addObject:param];
                
            }
            audioMix.inputParameters = inputParameters;
            
        });
        
        dispatch_group_notify(group, self.editQueue, ^{
            
            if (isCancel && *isCancel) {
                
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        !completion ? : completion(nil);
                    });
                    
                    return;
            }
            
            AVMutableCompositionTrack *compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
            
            AVAsset *tempAsset = [AVAsset assetWithURL:tempURL];
            
            AVAssetTrack *videoTrack = [tempAsset tracksWithMediaType:AVMediaTypeVideo].firstObject;
            
            [compositionVideoTrack insertTimeRange:videoTrack.timeRange ofTrack:videoTrack atTime:kCMTimeInvalid error:nil];
            
            [self exportWithComposition:composition videoComposition:nil audioMix:nil outputPath:outputPath progress:nil completion:completion];
            
        });
    
    
}

- (AVAssetExportSession *)exportWithComposition:(AVComposition *)composition
             videoComposition:(AVVideoComposition *)vc
                     audioMix:(AVAudioMix *)mix
                   outputPath:(NSURL *)outputPath
                     progress:(void(^)(float p))progress
                   completion:(void (^)(NSError *error))completion
{
    
//    if (![outputPath isFileURL]) {
//
//        NSLog(@"输出路劲必须为File URL");
//
//        return nil;
//    }
    
    AVAssetExportSession *assetExport = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetHighestQuality];
    
    dispatch_async(self.editQueue, ^{
        
        unlink([outputPath.path UTF8String]);
        
        assetExport.outputFileType = AVFileTypeMPEG4;
        if (mix) {
            
            assetExport.audioMix = mix;
        }
        if (vc) {
            
            assetExport.videoComposition = vc;
            
        }
        
        assetExport.outputURL = outputPath;
        assetExport.shouldOptimizeForNetworkUse = YES;
        assetExport.metadata = self.metadata;
        
        [assetExport exportAsynchronouslyWithCompletionHandler:^{
            
            dispatch_async(dispatch_get_main_queue(), ^{
//                !progress ? : progress(1);
                completion(assetExport.error);
            });
            
            
        }];
        
        while (assetExport.status == AVAssetExportSessionStatusExporting || assetExport.status == AVAssetExportSessionStatusUnknown || assetExport.status == AVAssetExportSessionStatusWaiting) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                !progress ? : progress(assetExport.progress);
                
            });
            [NSThread sleepForTimeInterval:0.1];
        }
        
        
        
        
    });
    
    return assetExport;
   
    
    
}

- (void)cancelExport:(id)ex
{
    if ([ex isKindOfClass:[AVAssetExportSession class]]) {
        
        AVAssetExportSession *assetExport = ex;
        [assetExport cancelExport];
        
        
    }
}

//- (void)exportImagesWithFilePath:(NSURL *)filePath
//                         atTimes:(NSArray *)times
//                      completion:(void(^)(NSArray *images))completion
//{
//    
//    dispatch_async(self.editQueue, ^{
//        
//        AVAsset *asset = [AVURLAsset assetWithURL:filePath];
//        AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
//        generator.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
//        generator.appliesPreferredTrackTransform = YES;
//        
//        generator.requestedTimeToleranceBefore = kCMTimeZero;
//        generator.requestedTimeToleranceAfter = kCMTimeZero;
//        CMTime actualTime;
//        
//        NSMutableArray *images = @[].mutableCopy;
//        for (NSNumber *t in times) {
//            
//            NSTimeInterval time = [t doubleValue];
//            
//            CGImageRef cgImage = [generator copyCGImageAtTime:CMTimeMake(time * asset.duration.timescale, asset.duration.timescale) actualTime:&actualTime error:nil];
//            
//            UIImage* image = [UIImage imageWithCGImage:cgImage];
//            
//            CGImageRelease(cgImage);
//            
//            [images addObject:image];
//        }
//        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            !completion ? : completion(images);
//        });
//        
//    });
//    
//    
//}


// 拼接
- (void)spliceWithFilePaths:(NSArray <NSURL *>*)filePaths
                 outputPath:(NSURL *)outputPath
                 completion:(void(^)(NSError *error))completion
{
    dispatch_async(self.editQueue, ^{
    AVMutableComposition *composition = [AVMutableComposition composition];
    
    AVMutableCompositionTrack *compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVMutableCompositionTrack *compositionVoiceTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    for (int i = 0; i < filePaths.count; i++) {
        NSURL *url = filePaths[i];
        AVAsset *videoAsset = [AVAsset assetWithURL:url];
        
        AVAssetTrack *voiceTrack = [videoAsset tracksWithMediaType:AVMediaTypeAudio].firstObject;
        AVAssetTrack *videoTrack = [videoAsset tracksWithMediaType:AVMediaTypeVideo].firstObject;
        
        [compositionVideoTrack insertTimeRange:videoTrack.timeRange ofTrack:videoTrack atTime:kCMTimeInvalid error:nil];
        
        [compositionVoiceTrack insertTimeRange:voiceTrack.timeRange ofTrack:voiceTrack atTime:kCMTimeInvalid error:nil];
        
    }
    
    [self exportWithComposition:composition videoComposition:nil audioMix:nil outputPath:outputPath progress:nil completion:completion];
      });
}


- (void)addWatermarkWithFilePath:(NSURL *)filePath
                 wartermarkImage:(UIImage *)wartermarkImage
                           frame:(CGRect)frame
                      outputPath:(NSURL *)outputPath
                      completion:(void(^)(NSError *error))completion
{
    dispatch_async(self.editQueue, ^{
        AVAsset *videoAsset = [AVAsset assetWithURL:filePath];
        
        AVMutableComposition *composition = [AVMutableComposition composition];
        AVMutableCompositionTrack *compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                                    preferredTrackID:kCMPersistentTrackID_Invalid];
        
        AVMutableCompositionTrack *compositionVoiceTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        
        
        AVAssetTrack *voiceTrack = [videoAsset tracksWithMediaType:AVMediaTypeAudio].firstObject;
        [compositionVoiceTrack insertTimeRange:voiceTrack.timeRange ofTrack:voiceTrack atTime:kCMTimeInvalid error:nil];
        
        AVAssetTrack *videoTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo]firstObject];
        
        [compositionVideoTrack insertTimeRange:videoTrack.timeRange
                                       ofTrack:videoTrack
                                        atTime:kCMTimeZero error:nil];
        compositionVideoTrack.preferredTransform = videoTrack.preferredTransform;
        
        CGSize videoSize = [videoTrack naturalSize];
        
        CALayer *watermarkLayer = [CALayer layer];
        watermarkLayer.contents = (__bridge id _Nullable)(wartermarkImage.CGImage);
        
        [watermarkLayer setFrame:frame];
        
        CALayer *parentLayer = [CALayer layer];
        CALayer *videoLayer = [CALayer layer];
        parentLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
        videoLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
        [parentLayer addSublayer:videoLayer];
        [parentLayer addSublayer:watermarkLayer];
        
        AVMutableVideoComposition* videoComposition = [AVMutableVideoComposition videoComposition];
        videoComposition.renderSize = videoSize;
        parentLayer.geometryFlipped = YES;
        videoComposition.frameDuration = CMTimeMake(1, 20);
        videoComposition.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
        AVMutableVideoCompositionInstruction* instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        //
        instruction.timeRange = compositionVideoTrack.timeRange;
        AVMutableVideoCompositionLayerInstruction* layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTrack];
        instruction.layerInstructions = @[layerInstruction];
        videoComposition.instructions = @[instruction];
        
        [self exportWithComposition:composition videoComposition:videoComposition audioMix:nil outputPath:outputPath progress:nil completion:completion];
    });
    
   
    
}

@end
