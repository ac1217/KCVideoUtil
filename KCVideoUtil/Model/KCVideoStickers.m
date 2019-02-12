//
//  KCEffect.m
//  KCVideoUtil
//
//  Created by Erica on 2018/8/8.
//  Copyright © 2018年 Erica. All rights reserved.
//

#import "KCVideoStickers.h"
#import "KCVideoGranter.h"

@implementation KCVideoStickers

- (BOOL)isExist
{
    return [[KCVideoGranter sharedGranter] isEffectExist:self];
}

- (void)downloadWithCompletion:(void(^)(BOOL success))completion
{
    [[KCVideoGranter sharedGranter] downloadEffect:self progress:^(float progress) {
        
    } completion:^(NSError *error) {
        
        !completion ? : completion(error == nil);
    }];
    
}
@end
