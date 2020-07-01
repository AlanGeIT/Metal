//
//  Shaders.metal
//  Metal图片滤镜处理
//
//  Created by Alan Ge on 2020/6/30.
//  Copyright © 2020 AlanGe. All rights reserved.
//

#include <metal_stdlib>
#include <simd/simd.h>
//使用命名空间 Metal
using namespace metal;

// 导入Metal shader 代码和执行Metal API命令的C代码之间共享的头
#import "ShaderTypes.h"

// 顶点着色器输出和片段着色器输入
//结构体
typedef struct
{
    //处理空间的顶点信息
    float4 clipSpacePosition [[position]];
    
    //颜色
    float2 textureCoordinate;
    
} RasterizerData;

//顶点着色函数
vertex RasterizerData
vertexShader(uint vertexID [[ vertex_id ]],
             constant CCVertex *vertexArray [[ buffer(CCVertexInputIndexVertices) ]],
             constant vector_uint2 *viewportSizePointer  [[ buffer(CCVertexInputIndexViewportSize) ]])

{
    /*
     处理顶点数据:
     1) 执行坐标系转换,将生成的顶点剪辑空间写入到返回值中.
     2) 将顶点颜色值传递给返回值
     */
    
    //定义out
    RasterizerData out;
    
    //初始化输出剪辑空间位置
    //out.clipSpacePosition = vector_float4(0.0, 0.0, 0.0, 1.0);
    
    // 索引到我们的数组位置以获得当前顶点
    // 我们的位置是在像素维度中指定的.
    float2 pixelSpacePosition = vertexArray[vertexID].position.xy;
    
    //将vierportSizePointer 从verctor_uint2 转换为vector_float2 类型
    float2 viewportSize = float2(*viewportSizePointer);
    
    //每个顶点着色器的输出位置在剪辑空间中(也称为归一化设备坐标空间,NDC),剪辑空间中的(-1,-1)表示视口的左下角,而(1,1)表示视口的右上角.
    //计算和写入 XY值到我们的剪辑空间的位置.为了从像素空间中的位置转换到剪辑空间的位置,我们将像素坐标除以视口的大小的一半.
    out.clipSpacePosition.xy = pixelSpacePosition / (viewportSize / 2.0);
    
    // 设置剪辑空间位置0的z分量（因为我们只为这个样本绘制2维）
    out.clipSpacePosition.z = 0.0;
    
    // 将W分量设置为1，因为我们不需要透视分割，这在二维渲染时也是不必要的。
    out.clipSpacePosition.w = 1.0;
    
    //把我们输入的颜色直接赋值给输出颜色. 这个值将于构成三角形的顶点的其他颜色值插值,从而为我们片段着色器中的每个片段生成颜色值.
    out.textureCoordinate = vertexArray[vertexID].textureCoordinate;
   
    //完成! 将结构体传递到管道中下一个阶段:
    return out;
}

//当顶点函数执行3次,三角形的每个顶点执行一次后,则执行管道中的下一个阶段.栅格化/光栅化.


// 片元函数
//[[stage_in]],片元着色函数使用的单个片元输入数据是由顶点着色函数输出.然后经过光栅化生成的.单个片元输入函数数据可以使用"[[stage_in]]"属性修饰符.
//一个顶点着色函数可以读取单个顶点的输入数据,这些输入数据存储于参数传递的缓存中,使用顶点和实例ID在这些缓存中寻址.读取到单个顶点的数据.另外,单个顶点输入数据也可以通过使用"[[stage_in]]"属性修饰符的产生传递给顶点着色函数.
//被stage_in 修饰的结构体的成员不能是如下这些.Packed vectors 紧密填充类型向量,matrices 矩阵,structs 结构体,references or pointers to type 某类型的引用或指针. arrays,vectors,matrices 标量,向量,矩阵数组.
fragment float4 samplingShader(RasterizerData in [[stage_in]],
                               texture2d<half> colorTexture [[ texture(CCTextureIndexOutput) ]])
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);
    
    // 采样纹理并将颜色返回到颜色样本
    const half4 colorSample = colorTexture.sample (textureSampler, in.textureCoordinate);
    
    // 返回纹理颜色
    return float4(colorSample);
}

/*
   图像数据加载到纹理中,然后使用内核函数将纹理的像素从颜色转换为灰度.内核函数独立并同时处理像素.
 注意:
    可以为CPU编写和执行等效算法.但是,GPU解决方案更快,因为纹理的像素不需要按顺序处理.
 这里出现了2个资源参数
 1.inTexture:包含输入颜色像素的只读2D纹理
 2.outTexture:一种只写的2D纹理,用于储存输出的灰度像素.
 */
// 灰度图像转换的709亮度值
constant half3 kRec709Luma = half3(0.2126, 0.7152, 0.0722);

//灰度并行计算函数
kernel void
grayscaleKernel(texture2d<half, access::read>  inTexture  [[texture(CCTextureIndexInput)]],
                texture2d<half, access::write> outTexture [[texture(CCTextureIndexOutput)]],
                uint2 gid [[thread_position_in_grid]])
{
     // 检查像素是否在输出纹理的边界内
    if((gid.x >= outTexture.get_width()) || (gid.y >= outTexture.get_height()))
    {
        //如果像素超出界限，则返回
        return;
    }
    
    //读取输入纹理中的像素点颜色
    half4 inColor  = inTexture.read(gid);
    //灰度计算:输入颜色 与 灰度亮度值 点乘
    half  gray     = dot(inColor.rgb, kRec709Luma);
    //将灰度颜色和像素点写入到输出纹理中
    outTexture.write(half4(gray, gray, gray, 1.0), gid);
}


