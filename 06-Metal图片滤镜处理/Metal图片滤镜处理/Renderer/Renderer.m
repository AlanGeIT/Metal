//
//  Renderer.m
//  Metal图片滤镜处理
//
//  Created by Alan Ge on 2020/6/30.
//  Copyright © 2020 AlanGe. All rights reserved.
//

#import "Renderer.h"
#import "Image.h"
#import "ShaderTypes.h"
@import simd;
@import MetalKit;

@implementation Renderer
{
    // 我们用来渲染的设备(又名GPU)
    id<MTLDevice> _device;
    
    // 我们的渲染管道有顶点着色器和片元着色器 它们存储在.metal shader 文件中
    id<MTLComputePipelineState> _computePipelineState;
    
    //  我们的渲染管道由Metal shader file 中的vertex和fragment着色器组成
    id<MTLRenderPipelineState> _renderPipelineState;
    
    // 命令队列,从命令缓存区获取
    id<MTLCommandQueue> _commandQueue;
    
    // 纹理对象作为图像处理的源
    id<MTLTexture> _inputTexture;
    
    // 纹理对象作为图像处理的输出
    id<MTLTexture> _outputTexture;
    
    // 当前视图大小,这样我们才可以在渲染通道使用这个视图
    vector_uint2 _viewportSize;
    
    // 计算内核调度参数
    MTLSize _threadgroupSize;
    MTLSize _threadgroupCount;
    
}

//初始化MetalView
- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView
{
    
    self = [super init];
    if(self)
    {
        NSError *error = NULL;
        
        _device = mtkView.device;
        
        // 设置将要绘制的纹理的颜色像素格式.
        mtkView.colorPixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;
        
        // 在项目中加载所有的着色器文件
        id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];
        
        // 从库中加载内核函数
        id<MTLFunction> kernelFunction = [defaultLibrary newFunctionWithName:@"grayscaleKernel"];
        
        // 创建计算管道状态
        _computePipelineState = [_device newComputePipelineStateWithFunction:kernelFunction
                                                                       error:&error];
        
        if(!_computePipelineState)
        {
            NSLog(@"Failed to create compute pipeline state, error %@", error);
            return nil;
        }
        
        // 从库中加载顶点函数
        id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"vertexShader"];
        
        // 从库中加载片段函数
        id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"samplingShader"];
        
        // 建立用于创建管道状态对象的描述符
        MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        //管道名称
        pipelineStateDescriptor.label = @"Simple Pipeline";
        //可编程函数,用于处理渲染过程中的各个顶点
        pipelineStateDescriptor.vertexFunction = vertexFunction;
        //可编程函数,用于处理渲染过程总的各个片段/片元
        pipelineStateDescriptor.fragmentFunction = fragmentFunction;
        //设置管道中存储颜色数据的组件格式
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat;
        
         //同步创建并返回渲染管线对象
        _renderPipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor
                                                                       error:&error];
        if (!_renderPipelineState)
        {
            NSLog(@"Failed to create render pipeline state, error %@", error);
        }
        //获取tag的路径
        NSURL *imageFileLocation = [[NSBundle mainBundle] URLForResource:@"stone"
                                                           withExtension:@"tga"];
        //创建CCImage对象
        Image * image = [[Image alloc] initWithTGAFileAtLocation:imageFileLocation];
        
        if(!image)
        {
            return nil;
        }
        
        //创建纹理描述对象
        MTLTextureDescriptor *textureDescriptor = [[MTLTextureDescriptor alloc] init];
        
        // 创建纹理类型--2D纹理.
        textureDescriptor.textureType = MTLTextureType2D;
        
        //表示每个像素有蓝色,绿色,红色和alpha通道.其中每个通道都是8位无符号归一化的值.(即0映射成0,255映射成1);
        textureDescriptor.pixelFormat = MTLPixelFormatBGRA8Unorm;
        //设置纹理的像素尺寸
        textureDescriptor.width = image.width;
        textureDescriptor.height = image.height;
        //设置纹理使用说明--只读
        textureDescriptor.usage = MTLTextureUsageShaderRead;
        
        //使用描述符从设备中创建纹理(输入纹理)
        _inputTexture = [_device newTextureWithDescriptor:textureDescriptor];
        //设置纹理使用说明--读/写
        textureDescriptor.usage = MTLTextureUsageShaderWrite | MTLTextureUsageShaderRead ;
        //使用描述符从设备中创建纹理(输出纹理)
        _outputTexture = [_device newTextureWithDescriptor:textureDescriptor];
        /*
         typedef struct
         {
         MTLOrigin origin; //开始位置x,y,z
         MTLSize   size; //尺寸width,height,depth
         } MTLRegion;
         */
        MTLRegion region = {{ 0, 0, 0 }, {textureDescriptor.width, textureDescriptor.height, 1}};
        
        //每个纹理的大小*纹理的宽度
        NSUInteger bytesPerRow = 4 * textureDescriptor.width;
        
        //复制图片数据到texture
        [_inputTexture replaceRegion:region
                         mipmapLevel:0
                           withBytes:image.data.bytes
                         bytesPerRow:bytesPerRow];
        
        //判断输入纹理是否为空
        if(!_inputTexture || error)
        {
            NSLog(@"Error creating texture %@", error.localizedDescription);
            return nil;
        }
        
        // 设置计算内核的16x16线程组大小
        _threadgroupSize = MTLSizeMake(16, 16, 1);
        
        //根据输入图像的宽度计算线程组的行数和列数，以确保覆盖整个图像（或更多），从而处理每个像素
        _threadgroupCount.width  = (_inputTexture.width  + _threadgroupSize.width -  1) / _threadgroupSize.width;
        _threadgroupCount.height = (_inputTexture.height + _threadgroupSize.height - 1) / _threadgroupSize.height;
        
        // 由于我们只处理2D数据集，所以设置深度为1。
        _threadgroupCount.depth = 1;
        
        // 创建命令队列
        _commandQueue = [_device newCommandQueue];
    }
    
    return self;
}
//每当视图改变方向或调整大小时调用
- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    // 保存可绘制的大小，因为当我们绘制时，我们将把这些值传递给顶点着色器
    _viewportSize.x = size.width;
    _viewportSize.y = size.height;
}

// 每当视图需要渲染帧时调用
- (void)drawInMTKView:(nonnull MTKView *)view
{
    static const CCVertex quadVertices[] =
    {
        //像素坐标,纹理坐标
        { {  250,  -250 }, { 1.f, 0.f } },
        { { -250,  -250 }, { 0.f, 0.f } },
        { { -250,   250 }, { 0.f, 1.f } },
        
        { {  250,  -250 }, { 1.f, 0.f } },
        { { -250,   250 }, { 0.f, 1.f } },
        { {  250,   250 }, { 1.f, 1.f } },
    };
    
     //为当前渲染的每个渲染传递创建一个新的命令缓冲区
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    //指定缓存区名称
    commandBuffer.label = @"MyCommand";
    //创建一个命令编码器
    id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
    //创建一个命令编码器
    [computeEncoder setComputePipelineState:_computePipelineState];
    
    
    //设置纹理对象
   // [renderEncoder setFragmentTexture:_texture atIndex:CCTextureIndexBaseColor];
    
    
    //设置输入纹理
    [computeEncoder setTexture:_inputTexture
                       atIndex:CCTextureIndexInput];
    //设置输出纹理
    [computeEncoder setTexture:_outputTexture
                       atIndex:CCTextureIndexOutput];
    
    //将计算函数调度输入为线程组大小的倍数
    [computeEncoder dispatchThreadgroups:_threadgroupCount
                   threadsPerThreadgroup:_threadgroupSize];
    //结束编码
    [computeEncoder endEncoding];
    
    
    // currentRenderPassDescriptor描述符包含currentDrawable's的纹理、视图的深度、模板和sample缓冲区和清晰的值。
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    
    if(renderPassDescriptor != nil)
    {
        //创建渲染命令编码器,这样我们才可以渲染到something
        id<MTLRenderCommandEncoder> renderEncoder =
        [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        //渲染器名称
        renderEncoder.label = @"MyRenderEncoder";
        
        //设置我们绘制的可绘制区域
        /*
         typedef struct {
         double originX, originY, width, height, znear, zfar;
         } MTLViewport;
         */
        [renderEncoder setViewport:(MTLViewport){0.0, 0.0, _viewportSize.x, _viewportSize.y, -1.0, 1.0 }];
        
        [renderEncoder setRenderPipelineState:_renderPipelineState];
        
        //将顶点数据 --> 顶点函数
        [renderEncoder setVertexBytes:quadVertices
                               length:sizeof(quadVertices)
                              atIndex:CCVertexInputIndexVertices];
        
        //将视图size-->顶点函数
        [renderEncoder setVertexBytes:&_viewportSize
                               length:sizeof(_viewportSize)
                              atIndex:CCVertexInputIndexViewportSize];
        //将输出纹理-->片段函数
        [renderEncoder setFragmentTexture:_outputTexture
                                  atIndex:CCTextureIndexOutput];
        
        //Metal 先将图片处理灰度滤镜(并行函数)-->片元函数显示图片(片元函数)
        //OpenGL ES: 片元函数(拿掉纹理像素点->灰度处理->计算后的颜色)
        
        //绘制
        // @method drawPrimitives:vertexStart:vertexCount:
        //@brief 在不使用索引列表的情况下,绘制图元
        //@param 绘制图形组装的基元类型
        //@param 从哪个位置数据开始绘制,一般为0
        //@param 每个图元的顶点个数,绘制的图型顶点数量
        /*
         MTLPrimitiveTypePoint = 0, 点
         MTLPrimitiveTypeLine = 1, 线段
         MTLPrimitiveTypeLineStrip = 2, 线环
         MTLPrimitiveTypeTriangle = 3,  三角形
         MTLPrimitiveTypeTriangleStrip = 4, 三角型扇
         */
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                          vertexStart:0
                          vertexCount:6];
        //表示已该编码器生成的命令都已完成,并且从NTLCommandBuffer中分离
        [renderEncoder endEncoding];
        
        //一旦框架缓冲区完成，使用当前可绘制的进度表
        [commandBuffer presentDrawable:view.currentDrawable];
    }
    
    //最后,在这里完成渲染并将命令缓冲区推送到GPU
    [commandBuffer commit];
}


@end
