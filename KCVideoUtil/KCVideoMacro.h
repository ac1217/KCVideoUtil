//
//  KCVideoMacro.h
//  KCVideoUtil
//
//  Created by Erica on 2018/8/9.
//  Copyright © 2018年 Erica. All rights reserved.
//
#import <UIKit/UIKit.h>

@class KCVideoStickers, KCVideoStyle;

typedef NS_ENUM(NSInteger, KCVideoStyleType) {
    KCVideoStyleTypeLookup,
    KCVideoStyleTypeContrast,
    KCVideoStyleTypeGamma,
    KCVideoStyleTypeInvert,
    KCVideoStyleTypeGreyScale,
    KCVideoStyleTypeSepia,
    KCVideoStyleTypeSobelEdgeDetection,
    KCVideoStyleTypeMonochrome,
    KCVideoStyleTypeVignette,
    KCVideoStyleTypeBlendDissolve,
    KCVideoStyleTypeDilation,
    KCVideoStyleTypeKuwahara,
    KCVideoStyleTypeSketch,
    KCVideoStyleTypeToon,
    KCVideoStyleTypeSwirl,
    KCVideoStyleTypeFalseColor
    
};

typedef NS_ENUM(NSInteger, KCVideoEffectType) {
    KCVideoEffectTypeNone = 0, // 不使用滤镜
    KCVideoEffectTypeBeauty = 1<<0, // 美颜滤镜
//    KCVideoEffectTypeSenseAr = 1<<2, // 商汤滤镜
//    KCVideoEffectTypeAiya = 1<<3, // 宝宝特效滤镜
    KCVideoEffectTypeCrop = 1<<4, // 裁剪滤镜
    KCVideoEffectTypeStyle = 1<<5, // 风格滤镜
};

typedef NS_ENUM(NSInteger, KCVideoPlaybackState) {
    KCVideoPlaybackStopped,
    KCVideoPlaybackPlaying,
    KCVideoPlaybackPaused
};

typedef NS_ENUM(NSInteger, KCVideoRecordState) {
    KCVideoRecordStopped,
    KCVideoRecordRecording,
    KCVideoRecordPaused
};

@protocol KCVideoPlayback <NSObject>

@optional
/*
 *  预览视图
 */
@property (nonatomic,strong, readonly) UIView *preview;
/*
 *  状态
 */
@property (nonatomic,assign) KCVideoPlaybackState state;
/*
 *  是否正在状态
 */
- (BOOL)isPlaying;
/*
 *  是否准备好
 */
- (BOOL)isPreparedToPlay;


/*
 *  跳到某个时间段
 */
- (void)seekToTime:(NSTimeInterval)time completion:(void (^)(BOOL finished))completion;
- (void)seekToTime:(NSTimeInterval)time;

/*
 *  准备播放
 */
- (void)prepareToPlay;
/*
 *  播放
 */
- (void)play;

/*
 *  暂停
 */
- (void)pause;
/*
 *  停止
 */
- (void)stop;
/*
 *  当前时间
 */
- (NSTimeInterval)currentTime;
/*
 *  总时长
 */
- (NSTimeInterval)duration;
/*
 *  获取当前帧图片
 */
- (UIImage *)imageAtCurrentTime;
- (void)imageAtCurrentTime:(void(^)(UIImage *image))cmp;


@end



@protocol KCVideoEffect <NSObject>

@optional

// 设置效果类型
- (void)setEffectType:(KCVideoEffectType)effectType;

// 设置美颜（0.0 ~ 1.0 之间的浮点数）
- (void)setBeauty:(CGFloat)strength;

// 美型（下列美容设置参数范围均为 0.0 ~ 1.0 之间的浮点数）
- (void)setBasic:(CGFloat)strength;

// 设置脸萌贴纸
- (void)setStickers:(KCVideoStickers *)m;

// 设置裁剪区域（归一化坐标）
- (void)setCropRegion:(CGRect)cropRegion;

// 设置滤镜风格
- (void)setVideoStyle:(KCVideoStyle *)m;

@end
