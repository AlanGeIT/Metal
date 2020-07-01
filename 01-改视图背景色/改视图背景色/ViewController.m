//
//  ViewController.m
//  改视图背景色
//
//  Created by Alan Ge on 2020/6/30.
//  Copyright © 2020 AlanGe. All rights reserved.
//

#import "ViewController.h"
#import "Renderer.h"

@interface ViewController (){
    MTKView  *_view;
    Renderer *_render;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _view = (MTKView *)self.view;
    
    //一个MTLDevice 对象就代表这着一个GPU,通常我们可以调用方法MTLCreateSystemDefaultDevice()来获取代表默认的GPU单个对象.
    _view.device = MTLCreateSystemDefaultDevice();
    
    if (!_view.device) {
        NSLog(@"Metal is not supported on this device");
        return;
    }
    
    //创建CCRenderer
    _render =[[Renderer alloc]initWithMetalKitView:_view];
    
    
    if (!_render) {
        NSLog(@"Renderer failed initialization");
        return;
    }
    
    //设置MTKView 的代理
    _view.delegate = _render;
    //视图可以根据视图属性上设置帧速率(指定时间来调用drawInMTKView方法)
    _view.preferredFramesPerSecond = 60;
}

@end
