//
//  KCVideoFuseFilter.m
//  KCVideoUtil
//
//  Created by Erica on 2018/11/2.
//  Copyright © 2018 Erica. All rights reserved.
//

#import "KCVideoFuseFilter.h"

static const GLfloat lineVertices[] = {
    -1.0f, 1.0f,
    -1.0f, -1.0f,
    1.0f,  -1.0f,
    1.0f,  1.0f,
};


@interface KCVideoFuseFilter ()
{
    NSInteger nextTextureIndex;
    GLfloat imageVertices[8];
    GLuint lineTexture;
//    CMTime previousTime;
}
//@property (nonatomic,strong) GPUImageUIElement *border;
@end

@implementation KCVideoFuseFilter

- (instancetype)init
{
    self = [super init];
    if (self) {
        inputFramebuffers = @{}.mutableCopy;
//        inputRotations = @{}.mutableCopy;
        
        glGenTextures(1, &lineTexture);

    }
    return self;
}

- (void)dealloc
{
    
    [self clearInputFrameBuffers];
    
}

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates;
{
    
    if (self.preventRendering)
    {
//        [inputFramebuffers enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, GPUImageFramebuffer * _Nonnull obj, BOOL * _Nonnull stop) {
//            [obj unlock];
//        }];
//        [self clearInputFrameBuffers];
        return;
    }
    
    [GPUImageContext setActiveShaderProgram:filterProgram];
    
    outputFramebuffer = [[GPUImageContext sharedFramebufferCache] fetchFramebufferForSize:[self sizeOfFBO] textureOptions:self.outputTextureOptions onlyTexture:NO];
    [outputFramebuffer activateFramebuffer];
    if (usingNextFrameForImageCapture)
    {
        [outputFramebuffer lock];
    }
    
    [self setUniformsForProgramAtIndex:0];
    
    glClearColor(0.11, 0.11, 0.11, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glDisable(GL_DEPTH_TEST);
//    glEnable(GL_BLEND);
//    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    for (int i = 0; i < self.coordinates.count; i++) {
        
        GPUImageFramebuffer *inputFramebuffer = inputFramebuffers[@(i)];
        
//        if (self.cachePreviousInputFramebuffers) {
        
            if (!inputFramebuffer) {
                break;
            }
//        }
        
        CGRect rect = [self.coordinates[i] CGRectValue];
        
        NSInteger fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
        if (self.fillModes.count > i) {
            fillMode = [self.fillModes[i] integerValue];
        }
        
        [self drawViewportWithFrameBuffer:inputFramebuffer textureCoordinates:textureCoordinates coordinate:rect fillMode:fillMode];
    }
  
//    if (!self.cachePreviousInputFramebuffers) {
//        [inputFramebuffers enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, GPUImageFramebuffer * _Nonnull obj, BOOL * _Nonnull stop) {
//            [obj unlock];
//        }];
//    }
    
    
    
    if (usingNextFrameForImageCapture)
    {
        dispatch_semaphore_signal(imageCaptureSemaphore);
    }
    
}

- (void)drawViewportWithFrameBuffer:(GPUImageFramebuffer *)fb textureCoordinates:(const GLfloat *)textureCoordinates coordinate:(CGRect)coordinate fillMode:(GPUImageFillModeType)fillMode
{
    
    CGFloat backingWidth = [self sizeOfFBO].width;
    CGFloat backingHeight = [self sizeOfFBO].height;
    
    
//    NSLog(@"preferedVideoSize = %@", NSStringFromCGSize(inputTextureSize));
//    NSLog(@"%f---%f", backingWidth, backingHeight);
    
//    CGFloat backingWidth = fb.size.width;
//    CGFloat backingHeight = fb.size.height;
    
    CGFloat w = backingWidth * coordinate.size.width;
    CGFloat h = backingHeight * coordinate.size.height;
    CGFloat x = backingWidth * coordinate.origin.x;
    CGFloat y = backingHeight * coordinate.origin.y;
    
    CGFloat heightScaling, widthScaling;
    CGSize currentViewSize = CGSizeMake(w, h);
    
  
    CGRect insetRect = AVMakeRectWithAspectRatioInsideRect(fb.size, CGRectMake(0, 0, currentViewSize.width, currentViewSize.height));
    
    
    switch (fillMode) {
            case kGPUImageFillModeStretch:

            widthScaling = 1;
            heightScaling = 1;

            break;
            case kGPUImageFillModePreserveAspectRatio:

            widthScaling = insetRect.size.width / currentViewSize.width;
            heightScaling = insetRect.size.height / currentViewSize.height;

            break;
            case kGPUImageFillModePreserveAspectRatioAndFill:
    
            widthScaling = currentViewSize.height / insetRect.size.height;
            heightScaling = currentViewSize.width / insetRect.size.width;
            
            break;

        default:
            
            
            widthScaling = fb.size.width / currentViewSize.width;
            heightScaling = fb.size.height / currentViewSize.height;
            
            break;
    }
    
    
    imageVertices[0] = -widthScaling;
    imageVertices[1] = -heightScaling;
    imageVertices[2] = widthScaling;
    imageVertices[3] = -heightScaling;
    imageVertices[4] = -widthScaling;
    imageVertices[5] = heightScaling;
    imageVertices[6] = widthScaling;
    imageVertices[7] = heightScaling;
    
    glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, imageVertices);
    
    glViewport(x, y, w, h); 
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, [fb texture]);
    glUniform1i(filterInputTextureUniform, 2);
    glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    
    glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, lineVertices);
    glLineWidth(2);
//    GLuint lineTexture = 0;
//    glGenTextures(1, &lineTexture);
    glBindTexture(GL_TEXTURE_2D, lineTexture);

    glDrawArrays(GL_LINE_LOOP, 0, 4);
    
}


- (NSInteger)nextAvailableTextureIndex;
{
    
    return nextTextureIndex;
}

- (void)clearInputFrameBuffers
{
//    runSynchronouslyOnVideoProcessingQueue(^{
    
        [inputFramebuffers enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, GPUImageFramebuffer * _Nonnull obj, BOOL * _Nonnull stop) {
//            glDeleteTextures(1,
            [obj clearAllLocks];
            [obj unlock];
        }];
        [inputFramebuffers removeAllObjects];
        
        nextTextureIndex = 0;
        glEnable(GL_DEPTH_TEST);
        glDisable(GL_BLEND);
//    });
    
}

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex;
{
    
//    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive || self.renderDisabled) {
//        
//        runSynchronouslyOnVideoProcessingQueue(^{
//            glFinish();
//        });
//        [self clearInputFrameBuffers];
//        
//        return;
//    }
    
    if (inputFramebuffers.count >= self.coordinates.count) {
    
        [self renderToTextureWithVertices:imageVertices textureCoordinates:[[self class] textureCoordinatesForRotation:inputRotation]];
        
        [self informTargetsAboutNewFrameAtTime:frameTime];
        
        [self clearInputFrameBuffers];
        
    }
    
    if (!self.coordinates.count) {
        NSLog(@"error:坐标不存在");
    }

}

- (void)setInputFramebuffer:(GPUImageFramebuffer *)newInputFramebuffer atIndex:(NSInteger)textureIndex;
{
//    GPUImageFramebuffer *lastFrameBuffer = inputFramebuffers[@(textureIndex)];
    
    inputFramebuffers[@(textureIndex)] = newInputFramebuffer;
    [newInputFramebuffer lock];
    
//    [lastFrameBuffer unlock];
    
    if (textureIndex + 1 > nextTextureIndex) {
        nextTextureIndex = textureIndex + 1;
    }
    
}


@end
