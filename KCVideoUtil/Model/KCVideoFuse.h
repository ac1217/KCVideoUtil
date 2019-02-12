//
//  KCVideoFuse.h
//  KCVideoUtil
//
//  Created by Erica on 2018/11/8.
//  Copyright © 2018 Erica. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface KCVideoFuse : NSObject

@property (nonatomic,assign) CGRect coordinate;

@property (nonatomic,strong) NSURL *URL;

@property (nonatomic,assign) float volume;

@property (nonatomic,assign) float startPlayTime;
// 预留
@property (nonatomic,strong) NSArray *URLs;
@end

NS_ASSUME_NONNULL_END
