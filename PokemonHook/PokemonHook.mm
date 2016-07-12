//
//  PokemonHook.mm
//  PokemonHook
//
//  Created by YoungShook on 16/7/11.
//  Copyright (c) 2016年 YoungShook. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <objc/runtime.h>

typedef NS_ENUM (NSUInteger, RockerControlDirection) {
    RockerControlDirectionUp,
    RockerControlDirectionDown,
    RockerControlDirectionLeft,
    RockerControlDirectionRight,
};
typedef void (^RockerValueCallback)(RockerControlDirection direction);


#pragma mark  RockerControlView @ interface
@interface RockerControlView : UIView
@property (nonatomic, copy) RockerValueCallback controlCallback;
@end

static RockerControlView *gameRockerView;

#pragma mark  CLLocation @ Swizzle
//  Ref: https://github.com/rpplusplus/PokemonHook
@interface CLLocation (Swizzle)

@end

@implementation CLLocation (Swizzle)

static float x = -1;
static float y = -1;

static float controlOffsetX = 0;
static float controlOffsetY = 0;

+ (void)load {
    Method m1 = class_getInstanceMethod(self, @selector(coordinate));
    Method m2 = class_getInstanceMethod(self, @selector(coordinate_));
    method_exchangeImplementations(m1, m2);
    if ([[NSUserDefaults standardUserDefaults] valueForKey:@"_fake_x"]) {
        x = [[[NSUserDefaults standardUserDefaults] valueForKey:@"_fake_x"] floatValue];
    }
    if ([[NSUserDefaults standardUserDefaults] valueForKey:@"_fake_y"]) {
        y = [[[NSUserDefaults standardUserDefaults] valueForKey:@"_fake_y"] floatValue];
    }
    [self addRockerView];
}

- (CLLocationCoordinate2D)coordinate_ {

    CLLocationCoordinate2D pos = [self coordinate_];

    // 算与联合广场的坐标偏移量
    if (x == -1 && y == -1) {
        //悉尼
        //x = pos.latitude - -33.871688;
        //y = pos.longitude - (151.212954);

        // 联合广场
        x = pos.latitude - -36.851638;
        y = pos.longitude - (174.765068);

        [[NSUserDefaults standardUserDefaults] setValue:@(x) forKey:@"_fake_x"];
        [[NSUserDefaults standardUserDefaults] setValue:@(y) forKey:@"_fake_y"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }

    return CLLocationCoordinate2DMake(pos.latitude-x + (controlOffsetX), pos.longitude-y + (controlOffsetY));
}

+ (void)addRockerView {

    if (gameRockerView) {
        return;
    }

    gameRockerView = [RockerControlView new];

    gameRockerView.controlCallback = ^(RockerControlDirection direction){
        switch (direction) {
        case RockerControlDirectionUp:
            x += [self randSetpDistance:0.000400 to:0.000150];
            break;
        case RockerControlDirectionDown:
            x -= [self randSetpDistance:0.000400 to:0.000150];
            break;
        case RockerControlDirectionLeft:
            y -= [self randSetpDistance:0.000400 to:0.000150];
            break;
        case RockerControlDirectionRight:
            y += [self randSetpDistance:0.000400 to:0.000150];
            break;
        default:
            break;
        }
    };

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[[UIApplication sharedApplication] keyWindow] addSubview:gameRockerView];
    });
}

+ (float)randSetpDistance:(float)max to:(float)min {
    return (((float)rand() / RAND_MAX) * (max - min)) + min;
}

@end


#pragma mark  RockerControlView @ implementation

@implementation RockerControlView

- (instancetype)init {
    if (self = [super init]) {
        [self initUI];
    }
    return self;
}

- (void)initUI {

    self.frame = CGRectMake(0, 20, 150, 150);
    self.backgroundColor = [UIColor clearColor];
    UIButton *up = [[UIButton alloc] initWithFrame:CGRectMake(50, 0, 50, 50)];
    up.backgroundColor = [UIColor colorWithRed:0.000 green:0.000 blue:1.000 alpha:0.123];
    up.layer.borderColor = [UIColor colorWithRed:0.000 green:0.000 blue:1.000 alpha:0.425].CGColor;
    up.layer.borderWidth = 1;
    [up setTitle:@"👆" forState:UIControlStateNormal];
    up.titleLabel.font = [UIFont systemFontOfSize:25.0];
    up.tag = 101;
    [up addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchDown];
    [self addSubview:up];


    UIButton *down = [[UIButton alloc] initWithFrame:CGRectMake(50, 100, 50, 50)];
    [down setTitle:@"👇" forState:UIControlStateNormal];
    down.backgroundColor = [UIColor colorWithRed:0.000 green:0.000 blue:1.000 alpha:0.123];
    down.layer.borderColor = [UIColor colorWithRed:0.000 green:0.000 blue:1.000 alpha:0.425].CGColor;
    down.layer.borderWidth = 1;
    down.tag = 102;
    [down addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchDown];
    [self addSubview:down];


    UIButton *left = [[UIButton alloc] initWithFrame:CGRectMake(0, 50, 50, 50)];
    [left setTitle:@"👈" forState:UIControlStateNormal];
    left.backgroundColor = [UIColor colorWithRed:0.000 green:0.000 blue:1.000 alpha:0.123];
    left.layer.borderColor = [UIColor colorWithRed:0.000 green:0.000 blue:1.000 alpha:0.425].CGColor;
    left.layer.borderWidth = 1;
    left.titleLabel.font = [UIFont systemFontOfSize:25.0];
    left.tag = 103;
    [left addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchDown];
    [self addSubview:left];


    UIButton *right = [[UIButton alloc] initWithFrame:CGRectMake(100, 50, 50, 50)];
    [right setTitle:@"👉" forState:UIControlStateNormal];
    right.backgroundColor = [UIColor colorWithRed:0.000 green:0.000 blue:1.000 alpha:0.123];
    right.layer.borderColor = [UIColor colorWithRed:0.000 green:0.000 blue:1.000 alpha:0.425].CGColor;
    right.layer.borderWidth = 1;
    right.titleLabel.font = [UIFont systemFontOfSize:25.0];
    right.tag = 104;
    [right addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchDown];
    [self addSubview:right];
}

- (void)buttonAction:(UIButton *)sender {
    [sender.layer addAnimation:[self scaleAnimation] forKey:@"scale"];

    if (self.controlCallback) {
        RockerControlDirection direction;
        switch (sender.tag) {
        case 101:
            direction = RockerControlDirectionUp;
            break;
        case 102:
            direction = RockerControlDirectionDown;
            break;
        case 103:
            direction = RockerControlDirectionLeft;
            break;
        case 104:
            direction = RockerControlDirectionRight;
            break;

        default:
            break;
        }

        self.controlCallback(direction);
    }
}

- (CAAnimation *)scaleAnimation {
    CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scale.toValue = @3;
    return scale;
}

@end
