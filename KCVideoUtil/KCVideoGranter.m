//
//  KCVideoManager.m
//  KCVideoUtil
//
//  Created by Erica on 2018/8/8.
//  Copyright © 2018年 Erica. All rights reserved.
//

#import "KCVideoGranter.h"
#import "KCVideoMacro.h"


@interface KCVideoGranter()

#ifdef KC_USAGE_SENSETIME
@property (nonatomic,strong) SenseArShortVideoClient *client;
#endif

#ifdef KC_USAGE_AIYA
@property (nonatomic,copy)  void(^facueSDKAuthorizeBlock)(NSInteger code);
#endif


@end

@implementation KCVideoGranter

+ (instancetype)sharedGranter
{
    __strong static id _sharedObject = nil;
    static dispatch_once_t pred = 0;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc]init];
    });
    return _sharedObject;
    
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
#ifdef KC_USAGE_SENSETIME
        SenseArShortVideoClient *client = [[SenseArShortVideoClient alloc] init];
        client.strID = @"524565";
        self.client = client;
        
#endif
        
        
        
#ifdef KC_USAGE_AIYA
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(aiyaLicenseNotification:) name:AiyaLicenseNotification object:nil];
        
#endif
        
        
    }
    return self;
}


#ifdef KC_USAGE_AIYA
- (void)aiyaLicenseNotification:(NSNotification *)note
{
    AiyaLicenseResult result = [note.userInfo[AiyaLicenseNotificationUserInfoKey] integerValue];
    if (self.facueSDKAuthorizeBlock) {
        self.facueSDKAuthorizeBlock(result);
        self.facueSDKAuthorizeBlock = nil;
    }
}
#endif

- (void)facueSDKAuthorizeWithLicencePath:(NSString *)path appKey:(NSString *)appKay appID:(NSString *)appID block:(void(^)(NSInteger code))block
{
    
#ifdef KC_USAGE_SENSETIME
    [SenseArMaterialService switchToServerType:DomesticServer];
    
    NSString *strLicensePath = path;
    NSString *checkActiveCode = [SenseArMaterialService generateActiveCodeWithLicensePath:strLicensePath error:nil];
    BOOL success = [SenseArMaterialService checkActiveCode:checkActiveCode licensePath:strLicensePath error:nil];
    
    if (success) {
        
        SenseArMaterialService *meterial = [SenseArMaterialService sharedInstance];
        
        [meterial authorizeWithAppID:appID appKey:appKay onSuccess:^{
            
            SenseArConfigStatus status = [meterial configureClientWithType:SmallVideo client:self.client];
            
            block(status);
            
        } onFailure:^(SenseArAuthorizeError iErrorCode) {
            
            block(iErrorCode);
        }];
        
    }else {
        
        block(-1);
        
    }
#endif
    
    
#ifdef KC_USAGE_AIYA
    
    self.facueSDKAuthorizeBlock = block;
    [AYLicenseManager initLicense:appKay];
    
#endif
    
}

- (void)fetchEffectsWithCompletion:(void (^)(NSArray<KCVideoStickers *> *))completion
{
    
#ifdef KC_USAGE_SENSETIME
    
    [[SenseArMaterialService sharedInstance] fetchAllGroupsOnSuccess:^(NSArray<SenseArMaterialGroup *> *arrMaterialGroups) {
        
        NSMutableArray *effects = @[].mutableCopy;
        
        dispatch_group_t group = dispatch_group_create();
        
        for (SenseArMaterialGroup *materialgroup in arrMaterialGroups) {
            dispatch_group_enter(group);
            
//            NSLog(@"materialgroup.strGroupID = %@", materialgroup.strGroupID);
            
            [[SenseArMaterialService sharedInstance] fetchMaterialsWithUserID:self.client.strID GroupID:materialgroup.strGroupID adMode:SMALL_VIDEO_EFFECT onSuccess:^(NSArray<SenseArMaterial *> *arrMaterials) {
                
                for (SenseArMaterial *am in arrMaterials) {
                    
                    KCVideoStickers *effect = [KCVideoStickers new];
                    effect.name = am.strName;
                    effect.logoURLString = am.strThumbnailURL;
                    effect.fileURL = am.strMeterialURL;
                    NSMutableString *string = [NSMutableString string];
                    
                    for (int i = 0; i < am.arrMaterialTriggerActions.count; i++) {
                        
                        SenseArMaterialAction *action = am.arrMaterialTriggerActions[i];
                        [string appendString:action.strTriggerActionTip];
                        if (i != am.arrMaterialTriggerActions.count - 1) {
                            [string appendString:@","];
                        }
                    }
                    effect.tip = string;
                    effect.extra = am;
                    [effects addObject:effect];
                    
                }
                dispatch_group_leave(group);
                
            } onFailure:^(int iErrorCode, NSString *strMessage) {
                
                dispatch_group_leave(group);
                
            }];
            
        }
        
        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
            
            !completion ? : completion(effects);
        });
        
        
        
        
    } onFailure:^(int iErrorCode, NSString *strMessage) {
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            !completion ? : completion(nil);
        });
    }];
    /*
    [[SenseArMaterialService sharedInstance] fetchMaterialsWithUserID:self.client.strID GroupID:@"4d2125e0ce0011e8a92002f2be04c567" adMode:SMALL_VIDEO_EFFECT onSuccess:^(NSArray<SenseArMaterial *> *arrMaterials) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSMutableArray *effects = @[].mutableCopy;
            for (SenseArMaterial *am in arrMaterials) {
                
                KCVideoStickers *effect = [KCVideoStickers new];
                effect.name = am.strName;
                effect.logoURLString = am.strThumbnailURL;
                effect.fileURL = am.strMeterialURL;
                NSMutableString *string = [NSMutableString string];
                
                for (int i = 0; i < am.arrMaterialTriggerActions.count; i++) {
                    
                    SenseArMaterialAction *action = am.arrMaterialTriggerActions[i];
                    [string appendString:action.strTriggerActionTip];
                    if (i != am.arrMaterialTriggerActions.count - 1) {
                        [string appendString:@","];
                    }
                }
                effect.tip = string;
                effect.extra = am;
                [effects addObject:effect];
                
            }
            
            !completion ? : completion(effects);
        });
        
        
    } onFailure:^(int iErrorCode, NSString *strMessage) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            !completion ? : completion(nil);
        });
        
    }];*/
#else
    if ([self.delegate respondsToSelector:@selector(granter:loadEffectWithComplection:)]) {
        [self.delegate granter:self loadEffectWithComplection:completion];
    }
#endif
    
}

- (BOOL)isEffectExist:(KCVideoStickers *)effect
{
#ifdef KC_USAGE_SENSETIME
    
    SenseArMaterial *am = effect.extra;
    return [[SenseArMaterialService sharedInstance] isMaterialDownloaded:am];
    
#else
    return [[NSFileManager defaultManager] fileExistsAtPath:effect.path];
    
#endif
}

- (void)downloadEffect:(KCVideoStickers *)effect progress:(void(^)(float progress))progress completion:(void(^)(NSError *))completion
{
    
    if ([self isEffectExist:effect]) {
        !completion ? : completion(nil);
    }else {
        
#ifdef KC_USAGE_SENSETIME
        
        [[SenseArMaterialService sharedInstance] downloadMaterial:effect.extra onSuccess:^(SenseArMaterial *material) {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                !completion ? : completion(nil);
            });
        } onFailure:^(SenseArMaterial *material, int iErrorCode, NSString *strMessage) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                !completion ? : completion([NSError errorWithDomain:@"123" code:iErrorCode userInfo:@{NSLocalizedFailureReasonErrorKey:strMessage}]);
            });
        } onProgress:^(SenseArMaterial *material, float fProgress, int64_t iSize) {
            
            !progress ? : progress(fProgress);
            
        }];
        
#else
        if ([self.delegate respondsToSelector:@selector(granter:downloadEffect:complection:)]) {
            [self.delegate granter:self downloadEffect:effect complection:completion];
        }
#endif
        
    }
    
}


- (void)fetchStylesWithCompletion:(void(^)(NSArray <KCVideoStyle *>*styles))completion
{
    
    NSArray *styleArray = @[
                            @{
                                @"title":@"SU1",
                                @"ID":@"F2",
                                @"type":@(KCVideoStyleTypeLookup),
                                @"value":@1
                                },
                            
                            @{
                                @"title":@"SU2",
                                @"ID":@"L1",
                                @"type":@(KCVideoStyleTypeLookup),
                                @"value":@1
                                },
                            @{
                                @"title":@"SU3",
                                @"ID":@"G1",
                                @"type":@(KCVideoStyleTypeContrast),
                                @"value":@2
                                },
                            @{
                                @"title":@"SU4",
                                @"ID":@"G2",
                                @"type":@(KCVideoStyleTypeGamma),
                                @"value":@2
                                },
                            @{
                                @"title":@"SU5",
                                @"ID":@"F3",
                                @"type":@(KCVideoStyleTypeLookup),
                                @"value":@1
                                },
                            @{
                                @"title":@"SU6",
                                @"ID":@"P1",
                                @"type":@(KCVideoStyleTypeLookup),
                                @"value":@1
                                },
                            
                            @{
                                @"title":@"SU7",
                                @"ID":@"B2",
                                @"type":@(KCVideoStyleTypeLookup),
                                @"value":@1
                                },
                            @{
                                @"title":@"BW1",
                                @"ID":@"B1",
                                @"type":@(KCVideoStyleTypeLookup),
                                @"value":@1
                                },
                            
                            @{
                                @"title":@"BW2",
                                @"ID":@"G7",
                                @"type":@(KCVideoStyleTypeGreyScale),
                                @"value":@0
                                },
                            
                            @{
                                @"title":@"BW3",
                                @"ID":@"G10",
                                @"type":@(KCVideoStyleTypeSobelEdgeDetection),
                                @"value":@1
                                },
                            @{
                                @"title":@"BW4",
                                @"ID":@"G56",
                                @"type":@(KCVideoStyleTypeToon)
                                },
                            
                            @{
                                @"title":@"BW5",
                                @"ID":@"G18",
                                @"type":@(KCVideoStyleTypeMonochrome),
                                @"value":@1
                                },
                            
                            @{
                                @"title":@"SP5",
                                @"ID":@"G29",
                                @"type":@(KCVideoStyleTypeBlendDissolve)
                                },
                            @{
                                @"title":@"SP4",
                                @"ID":@"G64",
                                @"type":@(KCVideoStyleTypeSwirl)
                                },
                            @{
                                @"title":@"SP3",
                                @"ID":@"G3",
                                @"type":@(KCVideoStyleTypeInvert),
                                @"value":@0
                                },
                            @{
                                @"title":@"SP2",
                                @"ID":@"G66",
                                @"type":@(KCVideoStyleTypeFalseColor)
                                },
                            @{
                                @"title":@"SP1",
                                @"ID":@"G55",
                                @"type":@(KCVideoStyleTypeSketch)
                                },
                            
                            @{
                                @"title":@"ME7",
                                @"ID":@"B3",
                                @"type":@(KCVideoStyleTypeLookup),
                                @"value":@1
                                },
                            @{
                                @"title":@"ME6",
                                @"ID":@"G22",
                                @"type":@(KCVideoStyleTypeVignette),
                                @"value":@1
                                },
                            @{
                                @"title":@"ME5",
                                @"ID":@"G8",
                                @"type":@(KCVideoStyleTypeSepia),
                                @"value":@0
                                },
                            @{
                                @"title":@"ME4",
                                @"ID":@"L3",
                                @"type":@(KCVideoStyleTypeLookup),
                                @"value":@1
                                },
                            @{
                                @"title":@"ME3",
                                @"ID":@"L2",
                                @"type":@(KCVideoStyleTypeLookup),
                                @"value":@1
                                },
                            @{
                                @"title":@"ME2",
                                @"ID":@"P2",
                                @"type":@(KCVideoStyleTypeLookup),
                                @"value":@1
                                },
                            @{
                                @"title":@"ME1",
                                @"ID":@"F1",
                                @"type":@(KCVideoStyleTypeLookup),
                                @"value":@1
                                },
                           
//                            @{
//                                @"title":@"BW7",
//                                @"ID":@"G53",
//                                @"type":@(KCVideoStyleTypeKuwahara)
//                                },
//
//                            @{
//                                @"title":@"BW5",
//                                @"ID":@"G52",
//                                @"type":@(KCVideoStyleTypeDilation)
//                                },
                           
                           ];
    
    
    NSMutableArray *arrM = @[].mutableCopy;
    
    for (NSDictionary *dict in styleArray) {
        
        KCVideoStyle *vs = [KCVideoStyle new];
        
        [dict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            
            [vs setValue:obj forKey:key];
            
        }];
        
        if (vs.type == KCVideoStyleTypeLookup || vs.type == KCVideoStyleTypeBlendDissolve) {

            vs.lookup = [UIImage imageNamed:[NSString stringWithFormat:@"lookup-%@", vs.ID] inBundle:[NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"KCVideoUtil" ofType:@"bundle"]] compatibleWithTraitCollection:nil];
        }
        
        [arrM addObject:vs];
    }
    
    
    
    !completion ? : completion(arrM);
    
}

- (UIImage *)imageNamed:(NSString *)name
{
    return [UIImage imageNamed:name inBundle:[NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"KCVideoUtil" ofType:@"bundle"]] compatibleWithTraitCollection:nil];
}

@end
