//
//  KCVideoFragment.m
//  KSVideoFramework
//
//  Created by Erica on 2018/2/26.
//  Copyright © 2018年 Erica. All rights reserved.
//

#import "KCVideoFragment.h"
#import <AVFoundation/AVFoundation.h>
#import "KCVideoEditor.h"
#import "KCVideoGranter.h"

@implementation KCVideoFragment

- (instancetype)init
{
    if (self = [super init]) {
//        _bgmRate = 1;
        _rate = 1;
    }
    return self;
}


/*
- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
//        self.bgmURL = [aDecoder decodeObjectForKey:@"bgmURL"];
//        self.videoURL = [aDecoder decodeObjectForKey:@"videoURL"];
//        self.videoFileName = [aDecoder decodeObjectForKey:@"videoFileName"];
        self.rate = [[aDecoder decodeObjectForKey:@"bgmRate"] doubleValue];
//        self.videoRate = [[aDecoder decodeObjectForKey:@"videoRate"] doubleValue];
        self.bgmStartTime = [[aDecoder decodeObjectForKey:@"bgmStartTime"] doubleValue];
        
        self.bgmEndTime = [[aDecoder decodeObjectForKey:@"bgmEndTime"] doubleValue];
        self.duration = [[aDecoder decodeObjectForKey:@"duration"] doubleValue];
        
        
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:@(self.duration) forKey:@"duration"];
    [aCoder encodeObject:@(self.bgmEndTime) forKey:@"bgmEndTime"];
    [aCoder encodeObject:@(self.bgmStartTime) forKey:@"bgmStartTime"];
    [aCoder encodeObject:@(self.rate) forKey:@"videoRate"];
//    [aCoder encodeObject:@(self.bgmRate) forKey:@"bgmRate"];
//    [aCoder encodeObject:self.bgmURL forKey:@"bgmURL"];
//    [aCoder encodeObject:self.videoFileName forKey:@"videoFileName"];
    
}
*/
@end
