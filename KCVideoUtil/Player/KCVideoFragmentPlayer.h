//
//  KCPlayer.h
//  KChortVideo
//
//  Created by Erica on 2018/7/20.
//  Copyright © 2018年 Erica. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import "KCVideoFragment.h"
#import "KCVideoPlayer.h"

@interface KCVideoFragmentPlayer : KCVideoPlayer

@property (nonatomic,strong) NSArray <KCVideoFragment *>*videoFragments;

@property (nonatomic,assign, getter=isRevert) BOOL revert;
@property (nonatomic,strong) NSURL *bgmURL;
@property (nonatomic,assign) NSTimeInterval bgmStartTime;
@property (nonatomic,assign) BOOL useAllBgmTracks;

// 实时改变
@property (nonatomic,assign) float volume;
@property (nonatomic,assign) float rate;
@property (nonatomic,assign) float bgmVolume;


@end

