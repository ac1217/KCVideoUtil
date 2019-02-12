//
//  KCVideoGranter.h
//  KCVideoUtil
//
//  Created by Erica on 2018/8/15.
//  Copyright © 2018年 Erica. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "KCVideoStickers.h"
#import "KCVideoStyle.h"

@class KCVideoGranter;
@protocol KCVideoGranterDelegate<NSObject>
@optional

- (void)granter:(KCVideoGranter *)granter loadEffectWithComplection:(void(^)(NSArray <KCVideoStickers *>*effects))completion;
- (void)granter:(KCVideoGranter *)granter downloadEffect:(KCVideoStickers *)effect complection:(void(^)(NSError *error))completion;

@end


@interface KCVideoGranter : NSObject

+ (instancetype)sharedGranter;

@property (nonatomic, weak) id<KCVideoGranterDelegate> delegate;

// 设备ID
@property (nonatomic,copy) NSString *deviceID;

// 如果用到脸萌SDK需要调用SDK授权
- (void)facueSDKAuthorizeWithLicencePath:(NSString *)path appKey:(NSString *)appKay appID:(NSString *)appID block:(void(^)(NSInteger code))block;

- (void)fetchEffectsWithCompletion:(void(^)(NSArray <KCVideoStickers *>*effects))completion;

- (BOOL)isEffectExist:(KCVideoStickers *)effect;

- (void)downloadEffect:(KCVideoStickers *)effect progress:(void(^)(float progress))progress completion:(void(^)(NSError *))completion;


- (void)fetchStylesWithCompletion:(void(^)(NSArray <KCVideoStyle *>*styles))completion;


@end
