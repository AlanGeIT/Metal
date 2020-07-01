//
//  Render.h
//  Metal渲染多个图形
//
//  Created by Alan Ge on 2020/6/30.
//  Copyright © 2020 AlanGe. All rights reserved.
//

#import <Foundation/Foundation.h>
//导入MetalKit工具包
@import MetalKit;

NS_ASSUME_NONNULL_BEGIN

//这是一个独立于平台的渲染类
//MTKViewDelegate协议:允许对象呈现在视图中并响应调整大小事件
@interface Render : NSObject<MTKViewDelegate>

//初始化一个MTKView
- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView;

@end

NS_ASSUME_NONNULL_END
