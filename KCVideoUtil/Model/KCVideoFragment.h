//
//  KCVideoFragment.h
//  KSVideoFramework
//
//  Created by Erica on 2018/2/26.
//  Copyright © 2018年 Erica. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KCVideoFragment : NSObject

//@property (nonatomic,strong) NSURL *bgmURL;
//@property (nonatomic,assign) float bgmRate;
@property (nonatomic,assign) NSTimeInterval bgmStartTime;
@property (nonatomic,assign) NSTimeInterval bgmEndTime;

@property (nonatomic,assign) float rate;
@property (nonatomic,assign) NSTimeInterval duration;

@property (nonatomic,strong) NSURL *URL;
@property (nonatomic,strong) NSURL *revertURL;

@end
