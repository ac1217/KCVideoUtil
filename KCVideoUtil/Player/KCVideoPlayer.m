//
//  KCAVPlayer.m
//  KCVideoUtil
//
//  Created by Erica on 2018/12/27.
//  Copyright © 2018 Erica. All rights reserved.
//

#import "KCVideoPlayer.h"
#import "KCVideoEditor.h"

@interface KCVideoPlayerView : UIView
- (AVPlayerLayer *)playerLayer;
@end

@implementation KCVideoPlayerView

+ (Class)layerClass
{
    return [AVPlayerLayer class];
}

- (AVPlayerLayer *)playerLayer
{
    return (AVPlayerLayer *)self.layer;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        
    }
    return self;
}

- (void)setPlayer:(AVPlayer *)player
{
    
    self.playerLayer.player = player;
    
}

@end

@interface KCVideoPlayer (){
    
    KCVideoPlaybackState _state;
    BOOL _isPreparedToPlay;
    KCVideoPlayerView *_preview;
    AVPlayerItemVideoOutput *_videoOutput;
    AVPlayer *_player;
    
}

@property (nonatomic,strong) AVAssetExportSession *export;

@property (nonatomic,strong) id timerObserver;

@end

@implementation KCVideoPlayer


#pragma mark -Life Cycle
- (instancetype)init
{
    if (self = [super init]) {
        
        _playVolume = 1.0;
        _playRate = 1;
        _playbackProgressTimeInterval = 0.1;
        _preview = [[KCVideoPlayerView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _preview.backgroundColor = [UIColor blackColor];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActiveNotification) name:UIApplicationDidBecomeActiveNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActiveNotification) name:UIApplicationWillResignActiveNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidPlayToEndTimeNotification:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemFailedToPlayToEndTimeNotification:) name:AVPlayerItemFailedToPlayToEndTimeNotification object:nil];
        
        
        [_preview.playerLayer addObserver:self forKeyPath:@"readyForDisplay" options:NSKeyValueObservingOptionNew context:nil];
        
    }
    return self;
}

- (void)dealloc
{
    [self stop];
    [[NSNotificationCenter defaultCenter]  removeObserver:self];
    
    [_preview.playerLayer removeObserver:self forKeyPath:@"readyForDisplay"];
}

- (void)setPlayRate:(float)playRate
{
    _playRate = playRate;
    
    _player.rate = playRate;
}

- (void)setPlayVolume:(float)playVolume
{
    _playVolume = playVolume;
    
    _player.volume = playVolume;
}

#pragma mark -Notification

- (void)playerItemFailedToPlayToEndTimeNotification:(NSNotification *)note
{
    if (note.object != self.player.currentItem) return;
    
    NSError *error = note.userInfo[AVPlayerItemFailedToPlayToEndTimeErrorKey];
    !self.playbackFailureBlock ? : self.playbackFailureBlock(error);
    
    _state = KCVideoPlaybackPaused;
    !self.playbackStateBlock ? : self.playbackStateBlock(_state);
}

- (void)playerItemDidPlayToEndTimeNotification:(NSNotification *)note
{
    
    if (note.object != self.player.currentItem) return;
    
    if (self.repeatToPlay) {
        
        [self seekToTime:0];
        [_player play];
        
    }else {
        
        !self.playbackFinishBlock ? : self.playbackFinishBlock();
        
        _state = KCVideoPlaybackPaused;
        !self.playbackStateBlock ? : self.playbackStateBlock(_state);
    }
    
}

- (void)applicationWillResignActiveNotification
{
    [self.player pause];
}

- (void)applicationDidBecomeActiveNotification
{
    
    if (self.isPlaying) {
        [self.player play];
    }
}

- (void)createPlayerResource {}

- (void)destoryPlayerResource {}

#pragma mark -KCVideoPlayback

- (void)prepareToPlay
{
    if (self.isPreparedToPlay) {
        return;
    }
    
    [self createPlayerResource];
    AVPlayerItem *item = self.playerItem;
    _player = [AVPlayer playerWithPlayerItem:item];
    
    //初始化输出流
    _videoOutput = [[AVPlayerItemVideoOutput alloc] init];
    //添加输出流
    [_player.currentItem addOutput:_videoOutput];
    
    __weak typeof(self) weakSelf = self;
    self.timerObserver = [_player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(self.playbackProgressTimeInterval, 1000) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        
        if (weakSelf.currentTime < 0 || weakSelf.duration == 0) {
            return;
        }
        
        float progress = weakSelf.currentTime / weakSelf.duration;
        
        progress = MAX(0, progress);
        
        !weakSelf.playbackProgressBlock ? : weakSelf.playbackProgressBlock(weakSelf.currentTime, weakSelf.duration, progress);
        
    }];
    
    _preview.player = self.player;
    
//    [self.player addObserver:self forKeyPath:@"currentItem.status" options:NSKeyValueObservingOptionNew context:nil];
    
    _isPreparedToPlay = YES;
    !self.isPreparedToPlayBlock ? : self.isPreparedToPlayBlock(_isPreparedToPlay);
    
    
    
    
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"readyForDisplay"]) {

        if (_preview.playerLayer.isReadyForDisplay) {
            
            !self.firstVideoFrameRenderedBlock ? : self.firstVideoFrameRenderedBlock();

        }
        
        !self.isReadyForDisplayBlock ? : self.isReadyForDisplayBlock(_preview.playerLayer.isReadyForDisplay);

    }
}

- (void)play
{
    
    if (self.isPlaying) {
        return;
    }
    
    if (!self.isPreparedToPlay) {
        
        [self prepareToPlay];
        
    }
    
    [_player play];
    _player.rate = self.playRate;
    _player.volume = self.playVolume;
    
    _state = KCVideoPlaybackPlaying;
    !self.playbackStateBlock ? : self.playbackStateBlock(_state);
    
}

- (BOOL)isPlaying
{
    return _state == KCVideoPlaybackPlaying;
}

- (void)stop
{
    
    if (!self.isPreparedToPlay) {
        return;
    }
    
    [_player pause];
    
    [_player.currentItem removeOutput:_videoOutput];
    _videoOutput = nil;
    
//    [_player removeObserver:self forKeyPath:@"currentItem.status"];
    
    if (self.timerObserver) {
        [_player removeTimeObserver:self.timerObserver];
        self.timerObserver = nil;
    }
    
    [self destoryPlayerResource];
    
    _player = nil;
    _preview.player = nil;
    
    _state = KCVideoPlaybackStopped;
    _isPreparedToPlay = NO;
    !self.isPreparedToPlayBlock ? : self.isPreparedToPlayBlock(_isPreparedToPlay);
    !self.playbackStateBlock ? : self.playbackStateBlock(_state);
    
}

- (void)pause
{
    
    if (!self.isPlaying) {
        return;
    }
    
    [_player pause];
    _state = KCVideoPlaybackPaused;
    !self.playbackStateBlock ? : self.playbackStateBlock(_state);
    
}

- (BOOL)isPreparedToPlay
{
    return _isPreparedToPlay;
}

- (UIView *)preview
{
    return _preview;
}

- (NSTimeInterval)currentTime
{
    return CMTimeGetSeconds(self.player.currentItem.currentTime);
}

- (NSTimeInterval)duration
{
    return CMTimeGetSeconds(self.player.currentItem.asset.duration);
}


- (UIImage *)imageAtCurrentTime
{
    if (!self.isPreparedToPlay) {
        [self prepareToPlay];
    }
    
    CMTime itemTime = self.player.currentItem.currentTime;
    
    if (![_videoOutput hasNewPixelBufferForItemTime:itemTime]) {
        
        return nil;
    }
    
    CVPixelBufferRef pixelBuffer = [_videoOutput copyPixelBufferForItemTime:itemTime itemTimeForDisplay:nil];
    
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    UIImage *image = [UIImage imageWithCIImage:ciImage];
    
    if (pixelBuffer) {
        CFRelease(pixelBuffer);
    }
    
    //开启图形上下文
    UIGraphicsBeginImageContext(image.size);
    //绘制图片
    [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
    //从图形上下文获取图片
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    //关闭图形上下文
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (void)imageAtCurrentTime:(void(^)(UIImage *image))cmp
{
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        UIImage *image = [self imageAtCurrentTime];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            !cmp ? : cmp(image);
        });
        
    });
    
}

- (void)seekToTime:(NSTimeInterval)time completion:(void (^)(BOOL))completion
{
    
    if (_player.currentItem.status != AVPlayerStatusFailed) {
        
        [_player seekToTime:CMTimeMakeWithSeconds(time, _player.currentItem.asset.duration.timescale) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:completion];
        
    }else {
        
        !completion ? : completion(NO);
        
    }
    
}


- (void)seekToTime:(NSTimeInterval)time
{
    [self seekToTime:time completion:nil];
}

- (void)cancelExport
{
    [[KCVideoEditor sharedEditor] cancelExport:self.export];
    self.export = nil;
}

- (void)exportAtPath:(NSString *)outputPath
            progress:(void(^)(float p))progress
          completion:(void (^)(NSError *error))completion
{
    
    if (!self.isPreparedToPlay) {
        
        [self prepareToPlay];
        
    }
    
    AVComposition *composition = (AVComposition *)_player.currentItem.asset;
    AVVideoComposition *videoComposition = _player.currentItem.videoComposition;
    AVAudioMix *audioMix = _player.currentItem.audioMix;
    
    self.export = [[KCVideoEditor sharedEditor] exportWithComposition:composition videoComposition:videoComposition audioMix:audioMix outputPath:[NSURL fileURLWithPath:outputPath] progress:progress completion:^(NSError *error) {
        !completion ? : completion(error);
        self.export = nil;
    }];
}

@end
