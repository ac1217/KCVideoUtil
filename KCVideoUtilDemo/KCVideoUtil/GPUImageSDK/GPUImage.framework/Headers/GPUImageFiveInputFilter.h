//
//  GPUImageFiveInputFilter.h
//  GPUImage
//
//  Created by Erica on 2018/11/8.
//  Copyright © 2018 Brad Larson. All rights reserved.
//
#import "GPUImageFourInputFilter.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kGPUImageFiveInputTextureVertexShaderString;

@interface GPUImageFiveInputFilter : GPUImageFourInputFilter
{
    GPUImageFramebuffer *fifthInputFramebuffer;
    
    GLint filterFifthTextureCoordinateAttribute;
    GLint filterInputTextureUniform5;
    GPUImageRotationMode inputRotation5;
    GLuint filterSourceTexture5;
    CMTime fifthFrameTime;
    
    BOOL hasSetFourthTexture, hasReceivedFifthFrame, fifthFrameWasVideo;
    BOOL fifthFrameCheckDisabled;
}

- (void)disableFifthFrameCheck;
@end

NS_ASSUME_NONNULL_END
