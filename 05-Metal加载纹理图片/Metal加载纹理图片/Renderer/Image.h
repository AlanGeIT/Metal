//
//  Image.h
//  Metal加载纹理图片
//
//  Created by Alan Ge on 2020/6/30.
//  Copyright © 2020 AlanGe. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Image : NSObject

//图片的宽高,以像素为单位
@property(nonatomic,readonly)NSUInteger width;
@property(nonatomic,readonly)NSUInteger height;

//图片数据每像素32bit,以BGRA形式的图像数据(相当于MTLPixelFormatBGRA8Unorm)
@property(nonatomic,readonly)NSData *data;

//通过加载一个简单的TGA文件初始化这个图像.只支持32bit的TGA文件
-(nullable instancetype) initWithTGAFileAtLocation:(nonnull NSURL *)location;

@end

NS_ASSUME_NONNULL_END
