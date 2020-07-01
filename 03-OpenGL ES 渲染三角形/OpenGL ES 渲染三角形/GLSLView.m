//
//  GLSLView.m
//  OpenGL ES 渲染三角形
//
//  Created by Alan Ge on 2020/6/30.
//  Copyright © 2020 AlanGe. All rights reserved.
//

#import "GLSLView.h"
#import "GLESMath.h"
#import "GLESUtils.h"
#import <OpenGLES/ES2/gl.h>

@interface GLSLView()

@property(nonatomic,strong)CAEAGLLayer *myEagLayer;
@property(nonatomic,strong)EAGLContext *myContext;

@property(nonatomic,assign)GLuint myColorRenderBuffer;
@property(nonatomic,assign)GLuint myColorFrameBuffer;

@property(nonatomic,assign)GLuint myProgram;
@property (nonatomic , assign) GLuint  myVertices;


@end

@implementation GLSLView

-(void)layoutSubviews
{
    
    //1.设置图层
    [self setupLayer];
    
    //2.设置上下文
    [self setupContext];
    
    //3.清空缓存区
    [self deletBuffer];
    
    //4.设置renderBuffer;
    [self setupRenderBuffer];
    
    //5.设置frameBuffer
    [self setupFrameBuffer];
    
    //6.绘制
    [self render];
}

//6.绘制
-(void)render
{
    //清屏颜色
    glClearColor(0, 0.0, 0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    CGFloat scale = [[UIScreen mainScreen] scale];
    //设置视口
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale);
    
    //获取顶点着色程序、片元着色器程序文件位置
    NSString* vertFile = [[NSBundle mainBundle] pathForResource:@"shaderv" ofType:@"glsl"];
    NSString* fragFile = [[NSBundle mainBundle] pathForResource:@"shaderf" ofType:@"glsl"];
    
    //判断self.myProgram是否存在，存在则清空其文件
    if (self.myProgram) {
        
        glDeleteProgram(self.myProgram);
        self.myProgram = 0;
    }
    
    //加载程序到myProgram中来。
    self.myProgram = [self loadShader:vertFile frag:fragFile];
    
    //4.链接
    glLinkProgram(self.myProgram);
    GLint linkSuccess;
    
    //获取链接状态
    glGetProgramiv(self.myProgram, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(self.myProgram, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"error%@", messageString);
        
        return ;
    }else {
        glUseProgram(self.myProgram);
    }
    

    //判断顶点缓存区是否为空，如果为空则申请一个缓存区标识符
    if (self.myVertices == 0) {
        glGenBuffers(1, &_myVertices);
    }
    

    //顶点数组
    //前3顶点值（x,y,z），后3位颜色值(RGB)
    GLfloat attrArr[] =
    {
        0.25f, -0.25f, 0.0f,      1.0f, 0.0f, 0.0f,
        -0.25f, -0.25f, 0.0f,      0.0f, 1.0f, 0.0f,
        0.0f, 0.25f, 0.0f,       0.0f, 0.0f, 1.0f,
       
    };
    
    //-----处理顶点数据-------
    //将_myVertices绑定到GL_ARRAY_BUFFER标识符上
    glBindBuffer(GL_ARRAY_BUFFER, _myVertices);
    //把顶点数据从CPU内存复制到GPU上
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
    
   // glBindBuffer(GL_ARRAY_BUFFER, _myVertices);
    
    //将顶点数据通过myPrograme中的传递到顶点着色程序的position
    //1.glGetAttribLocation,用来获取vertex attribute的入口的.2.告诉OpenGL ES,通过glEnableVertexAttribArray，3.最后数据是通过glVertexAttribPointer传递过去的。
    //注意：第二参数字符串必须和shaderv.vsh中的输入变量：position保持一致
    GLuint position = glGetAttribLocation(self.myProgram, "position");
    
    //3.设置读取方式
    //参数1：index,顶点数据的索引
    //参数2：size,每个顶点属性的组件数量，1，2，3，或者4.默认初始值是4.
    //参数3：type,数据中的每个组件的类型，常用的有GL_FLOAT,GL_BYTE,GL_SHORT。默认初始值为GL_FLOAT
    //参数4：normalized,固定点数据值是否应该归一化，或者直接转换为固定值。（GL_FALSE）
    //参数5：stride,连续顶点属性之间的偏移量，默认为0；
    //参数6：指定一个指针，指向数组中的第一个顶点属性的第一个组件。默认为0
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 6, NULL);
    
    //2.设置合适的格式从buffer里面读取数据
    glEnableVertexAttribArray(position);
    
    //--------处理顶点颜色值-------
    ////1.glGetAttribLocation,用来获取vertex attribute的入口的.
    //注意：第二参数字符串必须和shaderv.glsl中的输入变量：positionColor保持一致
    GLuint positionColor = glGetAttribLocation(self.myProgram, "positionColor");
    
    //3.设置读取方式
    //参数1：index,顶点数据的索引
    //参数2：size,每个顶点属性的组件数量，1，2，3，或者4.默认初始值是4.
    //参数3：type,数据中的每个组件的类型，常用的有GL_FLOAT,GL_BYTE,GL_SHORT。默认初始值为GL_FLOAT
    //参数4：normalized,固定点数据值是否应该归一化，或者直接转换为固定值。（GL_FALSE）
    //参数5：stride,连续顶点属性之间的偏移量，默认为0；
    //参数6：指定一个指针，指向数组中的第一个顶点属性的第一个组件。默认为0
    glVertexAttribPointer(positionColor, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 6, (float *)NULL + 3);
    
    //2.设置合适的格式从buffer里面读取数据
    glEnableVertexAttribArray(positionColor);
    

    
    glDrawArrays(GL_TRIANGLES, 0, 3);
    
    //要求本地窗口系统显示OpenGL ES渲染<目标>
    [self.myContext presentRenderbuffer:GL_RENDERBUFFER];
    
}

//5.设置frameBuffer
-(void)setupFrameBuffer
{
    //1.定义一个缓存区
    GLuint buffer;
    //2.申请一个缓存区标志
    glGenFramebuffers(1, &buffer);
    //3.
    self.myColorFrameBuffer = buffer;
    //4.设置当前的framebuffer
    glBindFramebuffer(GL_FRAMEBUFFER, self.myColorFrameBuffer);
    //5.将_myColorRenderBuffer 装配到GL_COLOR_ATTACHMENT0 附着点上
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self.myColorRenderBuffer);
    
    //接下来，可以调用OpenGL ES进行绘制处理，最后则需要在EGALContext的OC方法进行最终的渲染绘制。这里渲染的color buffer,这个方法会将buffer渲染到CALayer上。- (BOOL)presentRenderbuffer:(NSUInteger)target;

    
}

//4.设置renderBuffer
-(void)setupRenderBuffer
{
    //1.定义一个缓存区
    GLuint buffer;
    //2.申请一个缓存区标志
    glGenRenderbuffers(1, &buffer);
    //3.
    self.myColorRenderBuffer = buffer;
    //4.将标识符绑定到GL_RENDERBUFFER
    glBindRenderbuffer(GL_RENDERBUFFER, self.myColorRenderBuffer);
    
    //frame buffer仅仅是管理者，不需要分配空间；render buffer的存储空间的分配，对于不同的render buffer，使用不同的API进行分配，而只有分配空间的时候，render buffer句柄才确定其类型
    //为color renderBuffer 分配空间
    [self.myContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.myEagLayer];
    
}

//3.清空缓存区
-(void)deletBuffer
{
    //1.导入框架#import <OpenGLES/ES2/gl.h>
    /*
     2.创建2个帧缓存区，渲染缓存区，帧缓存区
     @property (nonatomic , assign) GLuint myColorRenderBuffer;
     @property (nonatomic , assign) GLuint myColorFrameBuffer;
     
     A.离屏渲染，详细解释见课件
     
     B.buffer的分类,详细见课件
     
     buffer分为frame buffer 和 render buffer2个大类。其中frame buffer 相当于render buffer的管理者。frame buffer object即称FBO，常用于离屏渲染缓存等。render buffer则又可分为3类。colorBuffer、depthBuffer、stencilBuffer。
     //绑定buffer标识符
     glGenRenderbuffers(<#GLsizei n#>, <#GLuint *renderbuffers#>)
     glGenFramebuffers(<#GLsizei n#>, <#GLuint *framebuffers#>)
     //绑定空间
     glBindRenderbuffer(<#GLenum target#>, <#GLuint renderbuffer#>)
     glBindFramebuffer(<#GLenum target#>, <#GLuint framebuffer#>)
     */
    glDeleteBuffers(1, &_myColorRenderBuffer);
    _myColorRenderBuffer = 0;
    
    glDeleteBuffers(1, &_myColorFrameBuffer);
    _myColorFrameBuffer = 0;
    
}


//2.设置上下文
-(void)setupContext
{
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    EAGLContext *context = [[EAGLContext alloc]initWithAPI:api];
    if (!context) {
        NSLog(@"Create Context Failed");
        return;
    }
    
    //设置为当前上下文
    if (![EAGLContext setCurrentContext:context]) {
        NSLog(@"Set Current Context Failed");
        return;
    }
    
    self.myContext = context;
    
}


//1.设置图层
-(void)setupLayer
{
    self.myEagLayer = (CAEAGLLayer *)self.layer;
    
    [self setContentScaleFactor:[[UIScreen mainScreen]scale]];
    
    //CALayer默认是透明的，必须将它设置为不透明才能其可见
    self.myEagLayer.opaque = YES;
    
    self.myEagLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking,kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
    
   
}

+ (Class)layerClass {
    return [CAEAGLLayer class];
}


#pragma mark -- Shader
-(GLuint)loadShader:(NSString *)vert frag:(NSString *)frag
{
    //创建2个临时的变量，verShader,fragShader
    GLuint verShader,fragShader;
    //创建一个Program
    GLuint program = glCreateProgram();
    
    //编译文件
    //编译顶点着色程序、片元着色器程序
    //参数1：编译完存储的底层地址
    //参数2：编译的类型，GL_VERTEX_SHADER（顶点）、GL_FRAGMENT_SHADER(片元)
    //参数3：文件路径
    [self compileShader:&verShader type:GL_VERTEX_SHADER file:vert];
    [self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:frag];
    
    //创建最终的程序
    glAttachShader(program, verShader);
    glAttachShader(program, fragShader);
    
    //释放不需要的shader
    glDeleteProgram(verShader);
    glDeleteProgram(fragShader);
    
    return program;
    
}

////链接shader
-(void)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
     //读取文件路径字符串
    NSString *content = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    //获取文件路径字符串，C语言字符串
    const GLchar *source = (GLchar *)[content UTF8String];
    
    //创建一个shader（根据type类型）
    *shader = glCreateShader(type);
    
    //将顶点着色器源码附加到着色器对象上。
    //参数1：shader,要编译的着色器对象 *shader
    //参数2：numOfStrings,传递的源码字符串数量 1个
    //参数3：strings,着色器程序的源码（真正的着色器程序源码）
    //参数4：lenOfStrings,长度，具有每个字符串长度的数组，或NULL，这意味着字符串是NULL终止的
    glShaderSource(*shader, 1, &source, NULL);
    
    //把着色器源代码编译成目标代码
    glCompileShader(*shader);
    
}


@end
