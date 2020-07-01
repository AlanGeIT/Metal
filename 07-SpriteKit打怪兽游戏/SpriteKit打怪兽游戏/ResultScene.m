//
//  ResultScene.m
//  SpriteKit打怪兽游戏
//
//  Created by Alan Ge on 2020/6/30.
//  Copyright © 2020 AlanGe. All rights reserved.
//

#import "ResultScene.h"
#import "MyScene.h"
@implementation ResultScene
-(instancetype)initWithSize:(CGSize)size won:(BOOL)won
{
    if (self = [super initWithSize:size]) {
        
        self.backgroundColor = [SKColor colorWithRed:1.0 green:1.0f blue:1.0f alpha:1.0f];
      
        NSLog(@"%f,%f",size.width,size.height);
        
        //1.将结果label 显示到屏幕中央
        //开辟空间,设置字体
        SKLabelNode *resultLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
        //设置text内容
        resultLabel.text = won?@"You win":@"You lose";
        //设置字体大小
        resultLabel.fontSize = 30;
        //设置字体颜色
        resultLabel.fontColor = [SKColor blackColor];
        //设置位置--屏幕中央
        resultLabel.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));

        //添加子节点
        [self addChild:resultLabel];
        
        //2.添加再来一次标签
        SKLabelNode *retryLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
        retryLabel.text = @"Try again";
        retryLabel.fontSize = 20;
        retryLabel.fontColor = [SKColor blueColor];
        retryLabel.position = CGPointMake(resultLabel.position.x, resultLabel.position.y * 0.8);
        //给节点命名,方便找到节点
        retryLabel.name = @"retryLabel";
        [self addChild:retryLabel];
    }
    
    return self;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    for (UITouch *touch in touches) {
        //获取当前点击位置
        CGPoint touchuLocation = [touch locationInNode:self];
        //根据点击的位置,获取点击到的节点.如果有则返回对应节点/否则返回空
        SKNode *node = [self nodeAtPoint:touchuLocation];
        
        //判断当前点击的节点是"retryLabel"
        if ([node.name isEqualToString:@"retryLabel"]) {
            
            //重新进入游戏界面
            [self changeToGameScene];
        }
    }
}

-(void)changeToGameScene
{
    MyScene *ms = [MyScene sceneWithSize:self.size];
    SKTransition *reveal = [SKTransition revealWithDirection:SKTransitionDirectionDown duration:1.0];
    [self.scene.view presentScene:ms transition:reveal];
}

@end

