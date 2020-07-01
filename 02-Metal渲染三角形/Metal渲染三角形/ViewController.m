//
//  ViewController.m
//  Metal渲染三角形
//
//  Created by Alan Ge on 2020/6/30.
//  Copyright © 2020 AlanGe. All rights reserved.
//

#import "ViewController.h"
//导入MetalKit 工具类
@import MetalKit;
#import "AAPLRenderer.h"

@interface ViewController ()
{
    MTKView      *_view;
    AAPLRenderer *_renderer;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Set the view to use the default device
    _view = (MTKView *)self.view;
    _view.device = MTLCreateSystemDefaultDevice();
    
    if(!_view.device)
    {
        NSLog(@"Metal is not supported on this device");
        return;
    }
    
    _renderer = [[AAPLRenderer alloc] initWithMetalKitView:_view];
    
    if(!_renderer)
    {
        NSLog(@"Renderer failed initialization");
        return;
    }
    
    // Initialize our renderer with the view size
    [_renderer mtkView:_view drawableSizeWillChange:_view.drawableSize];
    
    _view.delegate = _renderer;
}

@end
