//
//  KCPlayer.m
//  KChortVideo
//
//  Created by Erica on 2018/7/20.
//  Copyright © 2018年 Erica. All rights reserved.
//

#import "KCVideoFragmentPlayer.h"
#import "KCVideoEditor.h"

@interface KCVideoFragmentPlayer()

@property (nonatomic, readwrite, strong) AVMutableComposition *composition;
@property (nonatomic, readwrite, strong) AVMutableAudioMix *audioMix;

@property (nonatomic, readwrite, strong) AVMutableCompositionTrack *compositionVoiceTrack;
@property (nonatomic, readwrite, strong) AVMutableCompositionTrack *compositionVideoTrack;

@property (nonatomic, readwrite, strong) NSArray *compositionBgmTracks;



@end

@implementation KCVideoFragmentPlayer

- (instancetype)init {
    self = [super init];
    if (self) {
        
        _bgmVolume = 1;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioSessionRouteChangeNotification:)   name:AVAudioSessionRouteChangeNotification object:nil];
        
    }
    return self;
}


- (void)audioSessionRouteChangeNotification:(NSNotification *)notification
{
    NSDictionary *interuptionDict = notification.userInfo;
    NSInteger routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    switch (routeChangeReason) {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            //            NSLog(@"AVAudioSessionRouteChangeReasonNewDeviceAvailable");
            //            NSLog(@"耳机插入");
            [self play];
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            //            NSLog(@"AVAudioSessionRouteChangeReasonOldDeviceUnavailable");
            //            NSLog(@"耳机拔出，停止播放操作");
            [self play];
            break;
        case AVAudioSessionRouteChangeReasonCategoryChange:
            
            
            break;
    }
}

//- (void)playerItemDidPlayToEndTimeNotification:(NSNotification *)note
//{
//
//    if (note.object != self.player.currentItem) {
//        return;
//    }
//
//    [self seekToTime:0 completion:^(BOOL finished) {
//
//        [self.player play];
//
//    }];
//
//}



- (void)createPlayerResource
{

    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    
    AVMutableCompositionTrack *compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVMutableCompositionTrack *compositionVoiceTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    CMTime videoStart = kCMTimeZero;
    
    for (int i = 0; i < self.videoFragments.count; i++) {
        
        AVAsset *videoAsset;
        KCVideoFragment *videoFragment;
        if (self.revert) {
            videoFragment =  self.videoFragments[self.videoFragments.count - 1 - i];
            videoAsset = [AVAsset assetWithURL: videoFragment.revertURL];
        }else {
            videoFragment =  self.videoFragments[i];
            videoAsset = [AVAsset assetWithURL: videoFragment.URL];
            
        }
        
        
        AVAssetTrack *voiceTrack = [videoAsset tracksWithMediaType:AVMediaTypeAudio].firstObject;
        AVAssetTrack *videoTrack = [videoAsset tracksWithMediaType:AVMediaTypeVideo].firstObject;
        
        CMTimeRange videoTimeRange = videoTrack.timeRange;
        
        [compositionVideoTrack insertTimeRange:videoTimeRange ofTrack:videoTrack atTime:kCMTimeInvalid error:nil];
        
        [compositionVoiceTrack insertTimeRange:videoTimeRange ofTrack:voiceTrack atTime:kCMTimeInvalid error:nil];
        
        if (videoFragment.rate != 1) {
            
            [compositionVideoTrack scaleTimeRange:CMTimeRangeMake(videoStart, videoTimeRange.duration) toDuration:CMTimeMultiplyByFloat64(videoTimeRange.duration, 1 / videoFragment.rate)];
            
            [compositionVoiceTrack scaleTimeRange:CMTimeRangeMake(videoStart, videoTimeRange.duration) toDuration:CMTimeMultiplyByFloat64(videoTimeRange.duration, 1 / videoFragment.rate)];
        }
        
        videoStart = compositionVideoTrack.timeRange.duration;
    }
    
    
    AVAsset *bgmAsset = [AVAsset assetWithURL:self.bgmURL];
    
    NSArray *bgmTracks = [bgmAsset tracksWithMediaType:AVMediaTypeAudio];
    
    CMTimeRange audioTimeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(self.bgmStartTime, bgmAsset.duration.timescale), compositionVideoTrack.timeRange.duration);
    
    NSMutableArray *compositionBgmTracks = @[].mutableCopy;
    
    if (!self.useAllBgmTracks) {
        
        AVMutableCompositionTrack *compositionBgmTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        
        [compositionBgmTrack insertTimeRange:audioTimeRange ofTrack:bgmTracks.firstObject atTime:kCMTimeZero error:nil];
        
        [compositionBgmTracks addObject:compositionBgmTrack];
    }else {
        
        for (AVAssetTrack *bgmTrack in bgmTracks) {
            
            AVMutableCompositionTrack *compositionBgmTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            
            [compositionBgmTrack insertTimeRange:audioTimeRange ofTrack:bgmTrack atTime:kCMTimeZero error:nil];
            [compositionBgmTracks addObject:compositionBgmTrack];
            
        }
        
    }
    
    
    NSMutableArray<AVAudioMixInputParameters *> *inputParameters = [NSMutableArray<AVAudioMixInputParameters *> array];
    
    AVMutableAudioMixInputParameters *voiceMixParams = [AVMutableAudioMixInputParameters audioMixInputParameters];
    voiceMixParams.trackID = compositionVoiceTrack.trackID;
    [voiceMixParams setVolume:self.volume atTime:kCMTimeZero];
    [inputParameters addObject:voiceMixParams];
    
    
    for (AVMutableCompositionTrack *compositionBgmTrack in compositionBgmTracks) {
        
        AVMutableAudioMixInputParameters *audioMixParams = [AVMutableAudioMixInputParameters audioMixInputParameters];
        audioMixParams.trackID = compositionBgmTrack.trackID;
        [audioMixParams setVolume:self.bgmVolume atTime:kCMTimeZero];
        [inputParameters addObject:audioMixParams];
    }
    
    
    audioMix.inputParameters = inputParameters;
    if (self.rate != 1) {
        
        [composition scaleTimeRange:CMTimeRangeMake(kCMTimeZero, composition.duration) toDuration:CMTimeMultiplyByFloat64(composition.duration, 1 / self.rate)];
    }
    
    self.composition = composition;
    self.audioMix = audioMix;
    self.compositionBgmTracks = compositionBgmTracks;
    self.compositionVoiceTrack = compositionVoiceTrack;
    self.compositionVideoTrack = compositionVideoTrack;
    
    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:composition];
    item.audioMix = self.audioMix;
    item.audioTimePitchAlgorithm = AVAudioTimePitchAlgorithmSpectral;
    
    self.playerItem = item;
}

- (void)setBgmVolume:(float)bgmVolume
{
    _bgmVolume = bgmVolume;
    
    
    NSMutableArray *inputParameters = [NSMutableArray array];
    {
        AVMutableAudioMixInputParameters *voiceMix =
        [AVMutableAudioMixInputParameters audioMixInputParameters];
        [voiceMix setTrackID:self.compositionVoiceTrack.trackID];
        [voiceMix setVolume:self.volume atTime:kCMTimeZero];
        [inputParameters addObject:voiceMix];
        
        
        
        for (AVMutableCompositionTrack *compositionBgmTrack in self.compositionBgmTracks) {
            
            AVMutableAudioMixInputParameters *audioMixParams = [AVMutableAudioMixInputParameters audioMixInputParameters];
            audioMixParams.trackID = compositionBgmTrack.trackID;
            [audioMixParams setVolume:bgmVolume atTime:kCMTimeZero];
            [inputParameters addObject:audioMixParams];
        }
        
    }
    
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    [audioMix setInputParameters:inputParameters];
    
    [self.player.currentItem setAudioMix:audioMix];
    self.audioMix = audioMix;
}

- (void)setVolume:(float)volume
{
    _volume = volume;
    
    NSMutableArray *inputParameters = [NSMutableArray array];
    {
        AVMutableAudioMixInputParameters *voiceMix =
        [AVMutableAudioMixInputParameters audioMixInputParameters];
        [voiceMix setTrackID:self.compositionVoiceTrack.trackID];
        [voiceMix setVolume:volume atTime:kCMTimeZero];
        [inputParameters addObject:voiceMix];
        
        for (AVMutableCompositionTrack *compositionBgmTrack in self.compositionBgmTracks) {
            
            AVMutableAudioMixInputParameters *audioMixParams = [AVMutableAudioMixInputParameters audioMixInputParameters];
            audioMixParams.trackID = compositionBgmTrack.trackID;
            [audioMixParams setVolume:self.bgmVolume atTime:kCMTimeZero];
            [inputParameters addObject:audioMixParams];
        }
    }
    
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    [audioMix setInputParameters:inputParameters];
    
    [self.player.currentItem setAudioMix:audioMix];
    self.audioMix = audioMix;
    
}

@end

