//
//  Image.h
//  Metal图片滤镜处理
//
//  Created by Alan Ge on 2020/6/30.
//  Copyright © 2020 AlanGe. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Image : NSObject

//通过加载一个非常简单的TGA文件初始化这个图像。将不加载压缩、PalelEt、翻转或彩色映射的图像。只支持每像素32位的TGA文件
-(nullable instancetype) initWithTGAFileAtLocation:(nonnull NSURL *)location;

//图片的宽高,以像素为单位
@property (nonatomic, readonly) NSUInteger      width;
@property (nonatomic, readonly) NSUInteger      height;

//图片数据每像素32bit,以BGRA形式的图像数据(相当于MTLPixelFormatBGRA8Unorm)
@property (nonatomic, readonly, nonnull) NSData *data;

@end

NS_ASSUME_NONNULL_END
