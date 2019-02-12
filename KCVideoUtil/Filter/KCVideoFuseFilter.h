//
//  KCVideoFuseFilter.h
//  KCVideoUtil
//
//  Created by Erica on 2018/11/2.
//  Copyright © 2018 Erica. All rights reserved.
//

#import <GPUImage/GPUImageFramework.h>
#import "KCVideoMacro.h"
#import "KCVideoFuse.h"

NS_ASSUME_NONNULL_BEGIN

@interface KCVideoFuseFilter : GPUImageFilter
{

    NSMutableDictionary *inputFramebuffers;
//    NSMutableDictionary *inputRotations;
    
}

@property (nonatomic,strong) NSArray *fillModes;

@property (nonatomic,strong) NSArray *coordinates;

- (void)clearInputFrameBuffers;

//@property (nonatomic,strong) NSArray <KCVideoFuse *>*videoFuses;

@end

NS_ASSUME_NONNULL_END
