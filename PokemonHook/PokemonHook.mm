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
#import "UIView+draggable.h"

inline void replaceImplementation(Class newClass, Class hookedClass, SEL sel, IMP& oldImp){
    Method old = class_getInstanceMethod(hookedClass, sel);
    IMP newImp = class_getMethodImplementation(newClass, sel);
    oldImp = method_setImplementation(old, newImp);
}

#pragma mark  NIAIosLocationManagerHook @ Hook

@interface NIAIosLocationManagerHook : NSObject
+ (void)locationUpdateHook;
- (void)start;
@end

static NIAIosLocationManagerHook *hookLocationManager;

@implementation NIAIosLocationManagerHook
static IMP NIAIosLocationManager_start = NULL;

+ (void)locationUpdateHook {
    Class hookedClass = objc_getClass("NIAIosLocationManager");
    SEL startSel = @selector(start);
    replaceImplementation([self class], hookedClass, startSel, NIAIosLocationManager_start);
}

- (void)start {
    NIAIosLocationManager_start(self, @selector(start));
    hookLocationManager = self;
}

@end


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
static UIButton *googleMapsButton;
#pragma mark  CLLocation @ Swizzle
//  Ref: https://github.com/rpplusplus/PokemonHook
@interface CLLocation (Swizzle)

@end

@implementation CLLocation (Swizzle)

//SF
static float x = -36.851638;
static float y = 174.765068;

static float version = 167141100;

+ (void)load {
    Method m1 = class_getInstanceMethod(self, @selector(coordinate));
    Method m2 = class_getInstanceMethod(self, @selector(coordinate_));
    method_exchangeImplementations(m1, m2);

    if (![[NSUserDefaults standardUserDefaults] valueForKey:@"_fake_version"]) {
        float _verison = [[[NSUserDefaults standardUserDefaults] valueForKey:@"_fake_version"] floatValue];
        if (_verison < version) {
            [[NSUserDefaults standardUserDefaults] setValue:@(x) forKey:@"_fake_X"];
            [[NSUserDefaults standardUserDefaults] setValue:@(y) forKey:@"_fake_Y"];
            [[NSUserDefaults standardUserDefaults] setValue:@(version) forKey:@"_fake_version"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }

    if ([[NSUserDefaults standardUserDefaults] valueForKey:@"_fake_X"]) {
        x = [[[NSUserDefaults standardUserDefaults] valueForKey:@"_fake_X"] floatValue];
    }
    if ([[NSUserDefaults standardUserDefaults] valueForKey:@"_fake_Y"]) {
        y = [[[NSUserDefaults standardUserDefaults] valueForKey:@"_fake_Y"] floatValue];
    }


    [NIAIosLocationManagerHook locationUpdateHook];

    [self addRockerView];
}

- (CLLocationCoordinate2D)coordinate_ {

    if ([[NSUserDefaults standardUserDefaults] valueForKey:@"_fake_X"]) {
        x = [[[NSUserDefaults standardUserDefaults] valueForKey:@"_fake_X"] floatValue];
    }
    if ([[NSUserDefaults standardUserDefaults] valueForKey:@"_fake_Y"]) {
        y = [[[NSUserDefaults standardUserDefaults] valueForKey:@"_fake_Y"] floatValue];
    }
    return CLLocationCoordinate2DMake(x, y);
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
            y += [self randSetpDistance:0.000050 to:-0.000050];
            break;
        case RockerControlDirectionDown:
            x -= [self randSetpDistance:0.000400 to:0.000150];
            y += [self randSetpDistance:0.000050 to:-0.000050];
            break;
        case RockerControlDirectionLeft:
            y -= [self randSetpDistance:0.000400 to:0.000150];
            x += [self randSetpDistance:0.000050 to:-0.000050];
            break;
        case RockerControlDirectionRight:
            y += [self randSetpDistance:0.000400 to:0.000150];
            x += [self randSetpDistance:0.000050 to:-0.000050];
            break;
        default:
            break;
        }

        [[NSUserDefaults standardUserDefaults] setValue:@(x) forKey:@"_fake_X"];
        [[NSUserDefaults standardUserDefaults] setValue:@(y) forKey:@"_fake_Y"];
        [[NSUserDefaults standardUserDefaults] synchronize];

        if (hookLocationManager) {
            [hookLocationManager start];
            [googleMapsButton setAttributedTitle:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"lat:%@  lon:%@ open GoogleMaps", @(x), @(y)] attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:13]}] forState:UIControlStateNormal];
        }
    };

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [gameRockerView enableDragging];
        gameRockerView.cagingArea = UIScreen.mainScreen.bounds;

        googleMapsButton = [[UIButton alloc] initWithFrame:CGRectMake(10, UIScreen.mainScreen.bounds.size.height - 20, UIScreen.mainScreen.bounds.size.width, 20)];
        [googleMapsButton enableDragging];
        googleMapsButton.cagingArea = UIScreen.mainScreen.bounds;

        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:gameRockerView action:@selector(openGoogleMap:)];
        [googleMapsButton addGestureRecognizer:longPress];

        [[[UIApplication sharedApplication] keyWindow] addSubview:gameRockerView];
        [[[UIApplication sharedApplication] keyWindow] addSubview:googleMapsButton];
        [[NSNotificationCenter defaultCenter] addObserver:gameRockerView selector:@selector(dismissRocker) name:@"UIWindowDidShake" object:nil];
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

    self.frame = CGRectMake(60, 20, 150, 150);
    self.backgroundColor = [UIColor clearColor];
    self.layer.borderColor = [UIColor colorWithRed:0.000 green:0.000 blue:1.000 alpha:0.431].CGColor;
    self.layer.borderWidth = 1;
    self.clipsToBounds = YES;
    self.layer.cornerRadius = 20;
    UIButton *up = [[UIButton alloc] initWithFrame:CGRectMake(50, 0, 50, 50)];
    up.backgroundColor = [UIColor colorWithRed:0.000 green:0.000 blue:1.000 alpha:0.123];
    up.layer.borderColor = [UIColor colorWithRed:0.000 green:0.000 blue:1.000 alpha:0.425].CGColor;
    up.layer.borderWidth = 1;
    [up setTitle:@"👆" forState:UIControlStateNormal];
    up.titleLabel.font = [UIFont systemFontOfSize:25.0];
    up.tag = 101;
    [up addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchDown];
    [self addSubview:up];


    UIButton *setting = [[UIButton alloc] initWithFrame:CGRectMake(50, 50, 50, 50)];
    setting.backgroundColor = [UIColor colorWithRed:0.000 green:0.000 blue:1.000 alpha:0.123];
    setting.layer.borderColor = [UIColor colorWithRed:0.000 green:0.000 blue:1.000 alpha:0.425].CGColor;
    setting.layer.borderWidth = 1;
    [setting setTitle:@"👻" forState:UIControlStateNormal];
    setting.titleLabel.font = [UIFont systemFontOfSize:25.0];
    setting.tag = 201;
    [setting addTarget:self action:@selector(dismissRocker) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:setting];

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

- (void)dismissRocker {
    self.hidden = !self.hidden;
    googleMapsButton.hidden = self.hidden;
}

- (void)openGoogleMap:(UILongPressGestureRecognizer*)gesture {
    if ( gesture.state != UIGestureRecognizerStateEnded ) {
        return;
    }

    if (([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"comgooglemaps://"]] ||
         [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"comgooglemaps-x-callback://"]])) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"comgooglemaps-x-callback://?center=%@,%@&q=%@,%@&zoom=17&x-success=b335b2fc-69dc-472c-9e88-e6c97f84091c-3://?resume=true&x-source=PokemonGO", @(x), @(y), @(x), @(y)]]];
    }
}

- (void)buttonAction:(UIButton *)sender {
    [sender.layer addAnimation:[self scaleAnimation] forKey:@"scale"];

    if (self.controlCallback) {
        RockerControlDirection direction;
        switch (sender.tag) {
        case 101:
            direction = RockerControlDirectionUp;
            printf("Up");
            break;
        case 102:
            direction = RockerControlDirectionDown;
            printf("Down");
            break;
        case 103:
            direction = RockerControlDirectionLeft;
            printf("Left");
            break;
        case 104:
            direction = RockerControlDirectionRight;
            printf("Right");
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

@interface UIWindow (Shake_Swizzle)

@end

@implementation UIWindow (Shake_Swizzle)
- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (event.type == UIEventTypeMotion && event.subtype == UIEventSubtypeMotionShake) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UIWindowDidShake" object:nil];
    }
}

@end
