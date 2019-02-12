//
//  KCVideoInfo.h
//  KCVideoUtil
//
//  Created by Erica on 2018/12/19.
//  Copyright © 2018 Erica. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface KCVideoInfo : NSObject

@property (nonatomic,assign) NSTimeInterval duration;
@property (nonatomic,assign) int frameRate;
@property (nonatomic,assign) CGSize videoSize;

@property (nonatomic,strong) UIImage *firstFrameImage;


//@property (nonatomic,assign, readonly) size_t bitRate;
@end

NS_ASSUME_NONNULL_END
