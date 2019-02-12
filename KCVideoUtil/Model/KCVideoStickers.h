//
//  KCEffect.h
//  KCVideoUtil
//
//  Created by Erica on 2018/8/8.
//  Copyright © 2018年 Erica. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KCVideoStickers : NSObject

@property (nonatomic,copy) NSString *name;
@property (nonatomic,copy) NSString *path;
@property (nonatomic,copy) NSString *fileURL;
@property (nonatomic,copy) NSString *tip;
@property (nonatomic,copy) NSString *logoURLString;
@property (nonatomic,assign, readonly) BOOL isExist;

- (void)downloadWithCompletion:(void(^)(BOOL success))completion;
@property (nonatomic,strong) id extra;

@end
