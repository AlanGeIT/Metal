//
//  Renderer.h
//  Metal图片滤镜处理
//
//  Created by Alan Ge on 2020/6/30.
//  Copyright © 2020 AlanGe. All rights reserved.
//

#import <Foundation/Foundation.h>
@import MetalKit;

NS_ASSUME_NONNULL_BEGIN

@interface Renderer : NSObject<MTKViewDelegate>

- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView;

@end

NS_ASSUME_NONNULL_END
