//
//  KCVideoFusePlayer2.h
//  KCVideoUtil
//
//  Created by Erica on 2018/11/16.
//  Copyright © 2018 Erica. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KCVideoFuse.h"
#import "KCVideoMacro.h"
#import "KCVideoPlayer.h"

NS_ASSUME_NONNULL_BEGIN

@interface KCVideoFusePlayer : KCVideoPlayer

/*
 *  需要播放的视频对象数组
 */
@property (nonatomic,strong) NSArray <KCVideoFuse *>*videoFuses;

/*
 *  设置音量大小
 */
- (void)setVolume:(float)volume forIndex:(NSInteger)index;

/*
 *  视频背景色
 */
@property (nonatomic,strong) UIColor *videoBgColor;
/*
 *  视频边框颜色
 */
@property (nonatomic,strong) UIColor *videoBorderColor;

/*
 *  视频边框宽度
 */
@property (nonatomic,assign) CGFloat videoBorderWidth;
/*
 *  展位图
 */
@property (nonatomic,strong) UIImage *placeholderImage;

/*
 *  输出视频大小
 */
@property (nonatomic,assign) CGSize preferedVideoSize;

@end

NS_ASSUME_NONNULL_END
