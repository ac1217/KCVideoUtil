//
//  KCAVPlayer.h
//  KCVideoUtil
//
//  Created by Erica on 2018/12/27.
//  Copyright © 2018 Erica. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "KCVideoMacro.h"

NS_ASSUME_NONNULL_BEGIN

@interface KCVideoPlayer : NSObject<KCVideoPlayback>

@property (nonatomic,strong) AVPlayerItem *playerItem;

@property (nonatomic,strong, readonly) AVPlayer *player;
/*
 *  播放音量 0 ~ 1
 */
@property (nonatomic,assign) float playVolume;

/*
 *  播放速率 0.5 ~ 2.0
 */
@property (nonatomic,assign) float playRate;
/*
 *  是否重复播放
 */
@property (nonatomic,assign) BOOL repeatToPlay;

/*
 *  播放进度回调
 */
@property (nonatomic,copy) void(^playbackProgressBlock)(NSTimeInterval currentTime, NSTimeInterval duration, float progress);

/*
 *  播放状态回调
 */
@property (nonatomic,copy) void(^playbackStateBlock)(KCVideoPlaybackState state);

/*
 *  播放准备完毕回调
 */
@property (nonatomic,copy) void(^isPreparedToPlayBlock)(BOOL prepared);
/*
 *  准备显示完毕回调
 */
@property (nonatomic,copy) void(^isReadyForDisplayBlock)(BOOL ready);

/*
 *  播放完毕回调
 */
@property (nonatomic,copy) void(^playbackFinishBlock)(void);

/*
 *  播放失败回调
 */
@property (nonatomic,copy) void(^playbackFailureBlock)(NSError *error);

/*
 *  定时器回调秒数
 */
@property (nonatomic,assign) NSTimeInterval playbackProgressTimeInterval;

/*
 *  导出视频到指定路劲
 */
- (void)exportAtPath:(NSString *)outputPath
            progress:(void(^)(float p))progress
          completion:(void (^)(NSError *error))completion;
/*
 *  取消导出视频
 */
- (void)cancelExport;

// 子类重写
- (void)createPlayerResource;
- (void)destoryPlayerResource;
//- (void)playerItemDidPlayToEndTimeNotification:(NSNotification *)note;
//- (void)applicationWillResignActiveNotification;
//- (void)applicationDidBecomeActiveNotification;
//- (void)playerItemFailedToPlayToEndTimeNotification:(NSNotification *)note;


/*
 *  渲染第一针回调 (已弃用) replace: isReadyForDisplayBlock)
 */
@property (nonatomic,copy) void(^firstVideoFrameRenderedBlock)(void);

@end

NS_ASSUME_NONNULL_END
