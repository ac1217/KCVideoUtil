//
//  GPUImageSixInputFilter.h
//  GPUImage
//
//  Created by Erica on 2018/11/8.
//  Copyright © 2018 Brad Larson. All rights reserved.
//

#import "GPUImageFiveInputFilter.h"

extern NSString *const kGPUImageSixInputTextureVertexShaderString;

NS_ASSUME_NONNULL_BEGIN

@interface GPUImageSixInputFilter : GPUImageFiveInputFilter
{
    GPUImageFramebuffer *sixthInputFramebuffer;
    
    GLint filterSixthTextureCoordinateAttribute;
    GLint filterInputTextureUniform6;
    GPUImageRotationMode inputRotation6;
    GLuint filterSourceTexture6;
    CMTime sixthFrameTime;
    
    BOOL hasSetFifthTexture, hasReceivedSixthFrame, sixthFrameWasVideo;
    BOOL sixthFrameCheckDisabled;
}

- (void)disableSixthFrameCheck;
@end

NS_ASSUME_NONNULL_END
