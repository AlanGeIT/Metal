//
//  MyScene.m
//  SpriteKit打怪兽游戏
//
//  Created by Alan Ge on 2020/6/30.
//  Copyright © 2020 AlanGe. All rights reserved.
//

#import "MyScene.h"
#import <AVFoundation/AVFoundation.h>
#import <foundation/NSObjCRuntime.h>
#import "ResultScene.h"

@interface MyScene()

//怪物数组
@property (nonatomic, strong) NSMutableArray *monsters;
//弹药数组
@property (nonatomic, strong) NSMutableArray *projectiles;

//背景播放Player
@property (nonatomic, strong) AVAudioPlayer *bgmPlayer;
//子弹声音Action
@property(nonatomic,strong)SKAction *projectileSoundEffectAction;

//消灭怪物个数
@property(nonatomic,assign)int monstersDestroyed;

@end
@implementation MyScene


-(instancetype)initWithSize:(CGSize)size
{
    if (self = [super initWithSize:size]) {
       
        //设置背景音乐
        NSString *bgmPath = [[NSBundle mainBundle]pathForResource:@"background-music-aac" ofType:@"caf"];
        self.bgmPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL fileURLWithPath:bgmPath] error:nil];
        self.bgmPlayer.numberOfLoops = -1;
        [self.bgmPlayer play];
        
        //子弹发射声音Action
        self.projectileSoundEffectAction = [SKAction playSoundFileNamed:@"pew-pew-lei.caf" waitForCompletion:NO];
        
        self.monsters = [NSMutableArray array];
        self.projectiles = [NSMutableArray array];
        
        
        //1.设置给Scene设置背景颜色,默认颜色是黑色
        /*
         SKColor只是一个define定义而已，在iOS平台下被定义
         UIColor，在Mac下被定义为NSColor。在SpriteKit开发时，尽量
         用SK开头的对应的UI类可以统一代码而减少跨iOS和Mac平台的成本
         类似的定义还有SKView，它在iOS下是UIView的子类，在Mac下是NSView的子类
         */
        self.backgroundColor = [SKColor colorWithRed:1.0f green:1.0 blue:1.0f alpha:1.0f];
        
        //2.初始化一个精灵.
        /*
         实际上一个SKSpriteNode中包含了贴图（SKTexture对象），颜色，尺寸等等参数，这个简便方法为我们读取图片，生成SKTexture，并设定精灵尺寸和图片大小一致。在实际使用中，绝大多数情况这个简便方法就足够了。
         */
        SKSpriteNode * player = [SKSpriteNode spriteNodeWithImageNamed:@"player"];
        
        //3.设置精灵玩家的位置.
        /*SpriteKit中的坐标系和其他OpenGL游戏坐标系是一致的，屏幕左下角为(0,0)。不过需要注意的是不论是横屏还是竖屏游戏，view的尺寸都是按照竖屏进行计算的，即对于iPhone来说在这里传入的sizewidth是320，height是480或者568，而不会因为横屏而发生交换。因此在开发时，请千万不要使用绝对数值来进行位置设定及计算（否则你会死的很难看啊很难看）
         设置玩家的位置在右中侧
         */
        player.position = CGPointMake(player.size.width/2, size.height/2);
        
        //4.将Player 添加当前的SCene中.
        [self addChild:player];
        
        //5.添加怪物
        // [self addMonster];
        
        //5.添加多个怪物
        /*
         问题:
          1.为什么不用NSTimer来控制时间.
            尽量不要使用NSTimer,因为NSTimer 不受SpriteKit的影响和管理.使用SKAction 管理简单并且简便
         */
        //1)创建怪物动作
        SKAction *actionAddMonster = [SKAction runBlock:^{
            [self addMonster];
        }];
        //2)间隔时间
        SKAction *actionWaitNextMonster = [SKAction waitForDuration:1];
        
        //3)重复创建怪物并等待1秒钟
        SKAction *repeatAddMonsterAction = [SKAction repeatActionForever:[SKAction sequence:@[actionAddMonster,actionWaitNextMonster]]];
        
        //4)执行该动作
        [self runAction:repeatAddMonsterAction];
    }
    
    return self;
}

//添加怪物--添加怪物和添加主角的方式是一样的.同样生成精灵,设定位置,加到Scene中.区别就怪物会移动/并且会每隔段时间随机出现.
-(void)addMonster
{
    SKSpriteNode *monster = [SKSpriteNode spriteNodeWithImageNamed:@"monster"];

    //1.计算怪物的出生点(移动开始的位置)的Y值,怪物从右侧屏幕外随机的高度处进入屏幕.为了保证怪物图像都在屏幕范围内,需要指定最小/最大的Y值,然后在这个范围内随机一个Y值作为出生点.
    CGSize winSize = self.size;
    int minY = monster.size.height/2;
    int maxY = winSize.height - monster.size.height/2;
    //范围
    int rangeY = maxY - minY;
    //实际Y,在范围内产生随机Y值
    int actualY = (arc4random() % rangeY)+minY;
    
    //2.设定出生点恰好在屏幕右侧外面,然后添加怪物精灵
    monster.position = CGPointMake(winSize.width + monster.size.width/2, actualY);
    [self addChild:monster];
    
    //3.设置怪物速度(速度如果是匀速,游戏会显得非常死板,所以速度可以为随机值)
    int minDuration = 2.0;
    int maxDuration = 4.0;
    int rangeDuration = maxDuration - minDuration;
    int actualDuration = (arc4random() % rangeDuration) + minDuration;
    
    //4.建立SKAction,SKAction 可以操作SKNode.比如精灵移动/消失/旋转等行为.
    /*
     需要设置2个SKAction;
     actionMove负责将精灵在actualDuration的时间间隔内移动到结束点（直线横穿屏幕
     actionMoveDone负责将精灵移出场景，其实是run一段接受到的block代码。
     
     在runAction方法可以让精灵执行某个操作，而在这里我们要做的是先将精灵移动到结束点，当移动结束后，移除精灵
     按照一个顺序执行,创建一个sequence.可以让我们按照顺序调度多个action;
     */
    
    /**
     + (SKAction *)moveTo:(CGPoint)location duration:(NSTimeInterval)duration;
     创建将节点移动到新位置的操作。
     @location 节点新位置的坐标
     @duration 动画的持续时间，以秒为单位
     */
    SKAction *actionMove = [SKAction moveTo:CGPointMake(-monster.size.width/2, actualY) duration:actualDuration];
    
    
    SKAction *actionMoveDone = [SKAction runBlock:^{
        //从父节点中移除
        [monster removeFromParent];
        //移除monster
        [self.monsters removeObject:monster];
        //显示到失败的界面
        [self changeToResultSceneWithWon:NO];
    }];
    
    //runAction 执行Action,按照数组sequence数组中的顺序
    [monster runAction:[SKAction sequence:@[actionMove,actionMoveDone]]];
    
    //将Monster 添加的数组中
    [self.monsters addObject:monster];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    for (UITouch *touch in touches) {
        //1.建立弹药初始位置
        CGSize winSize = self.size;
        //创建子弹节点
        SKSpriteNode *projectile = [SKSpriteNode spriteNodeWithImageNamed:@"projectile.png"];
        //获取位置
        projectile.position = CGPointMake(projectile.size.width/2, winSize.height/2);
        
        //2.获取当前手指点击的位置
        CGPoint location = [touch locationInNode:self];
        
        //获取场景中的触摸位置并计算偏移量
        CGPoint offset = CGPointMake(location.x - projectile.position.x, location.y - projectile.position.y);
        
        //如果位置为负数.则直接返回
        if (offset.x <= 0) return;
        [self addChild:projectile];
        
        //实际上X的位置
        int realX = winSize.width + projectile.size.width/2;
        //比率
        float ratio = offset.y/offset.x;
        //实际上Y的位置
        int realY = realX * ratio + projectile.position.y;
        //获取的点击位置
        CGPoint realDest = CGPointMake(realX, realY);
        
        //3.获取结束的XY位置
        int offRealX = realX - projectile.position.x;
        int offRealY = realY - projectile.position.y;
        //路径长度
        float length = sqrtf((offRealX*offRealX)+(offRealY*offRealY));
        //速度
        float velocity = self.size.width/1;
        //时间=路程/速度
        float realMoveDuration =length/velocity;
        
        //4.设置MoveAction
        SKAction *moveAction = [SKAction moveTo:realDest duration:realMoveDuration];
        
        //将移动和子弹声音动画组合使播放音效的action和移动精灵的action同时执行
        SKAction *projectileCastAction = [SKAction group:@[moveAction,self.projectileSoundEffectAction]];
        
        //执行动画
        [projectile runAction:projectileCastAction completion:^{
            //动画执行完毕,移除子弹
            [projectile removeFromParent];
            //将子弹从子弹数组中移除
            [self.projectiles removeObject:projectile];
            
        }];
        
        //往子弹数组中添加刚刚产生的子弹
        [self.projectiles addObject:projectile];
    }
}

-(void)update:(NSTimeInterval)currentTime
{
    //1.要删除的子弹数组
     NSMutableArray *projectilesToDelete = [[NSMutableArray alloc] init];
    
    //2 遍历子弹数组
    for (SKSpriteNode *projectile in self.projectiles) {
        
        //定义怪物删除数组
        NSMutableArray *monsterToDelete = [[NSMutableArray alloc]init];
        
        //遍历怪物数组
        for (SKSpriteNode *monster in self.monsters) {
            
            /*
             CGRectIntersectsRect(CGRect rect1, CGRect rect2)
             
             Return true if `rect1' intersects `rect2', false otherwise. `rect1'
             intersects `rect2' if the intersection of `rect1' and `rect2' is not the null rect.
             
             如果rect1 与 rect2 相交则返回true,否则返回flase.
             */
            //判断子弹是否和怪物相交(碰撞检测)
            if (CGRectIntersectsRect(projectile.frame, monster.frame)) {
                [monsterToDelete addObject:monster];
            }
        }
        
        //3.遍历怪物删除数组
        for (SKSpriteNode *monster in monsterToDelete) {
            //从怪物数组删除该怪物
            [self.monsters removeObject:monster];
            //将该怪物从父节点中移除(怪物消失)
            [monster removeFromParent];
            
            //记录战绩
            self.monstersDestroyed++;
            if (self.monstersDestroyed >= 30) {
                //战绩大于30,切换到成功的界面
                [self changeToResultSceneWithWon:YES];
            }
        }
        
        //如果怪物>0,则有多余子弹,则将多余子弹加入到子弹删除数组
        if (monsterToDelete.count > 0) {
            [projectilesToDelete addObject:projectile];
        }
    }
    
    //4.遍历子弹删除数组
    for (SKSpriteNode *projectile in projectilesToDelete) {
        //将子弹从子弹数组删除
        [self.projectiles removeObject:projectile];
        //将该子弹从父节点中移除(子弹消失)
        [projectile removeFromParent];
    }
}

-(void) changeToResultSceneWithWon:(BOOL)won
{
    //1.停止背景音乐
    [self.bgmPlayer stop];
    self.bgmPlayer = nil;
    //2.切换到结果场景
    ResultScene *rs = [[ResultScene alloc]initWithSize:self.size won:won];
    //3.设置转场动画
    SKTransition *reveal = [SKTransition revealWithDirection:SKTransitionDirectionUp duration:1.0];
    //4.切换场景
    [self.scene.view presentScene:rs transition:reveal];
}

@end

