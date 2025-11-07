#import "WXKBTweakRootListController.h"
#import <spawn.h>

@implementation WXKBTweakRootListController

- (instancetype)init {
    self = [super init];
    if (self) {
        NSLog(@"[WXKBTweak] 老王：设置控制器初始化！");
    }
    return self;
}

- (NSArray *)specifiers {
    if (!_specifiers) {
        NSLog(@"[WXKBTweak] 老王：开始加载设置...");

        @try {
            // 获取Bundle路径
            NSBundle *bundle = [NSBundle bundleForClass:[self class]];
            NSString *bundlePath = [bundle bundlePath];
            NSLog(@"[WXKBTweak] 老王：Bundle路径=%@", bundlePath);

            // 查找Root.plist
            NSString *plistPath = [bundle pathForResource:@"Root" ofType:@"plist"];
            NSLog(@"[WXKBTweak] 老王：Plist路径=%@", plistPath);

            if (!plistPath || ![[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
                NSLog(@"[WXKBTweak] 老王：❌ Root.plist不存在！");
                _specifiers = [NSMutableArray array];
            } else {
                NSLog(@"[WXKBTweak] 老王：✅ 找到Root.plist，开始加载...");
                _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
                NSLog(@"[WXKBTweak] 老王：✅ 加载了 %lu 个设置项", (unsigned long)[_specifiers count]);
            }
        } @catch (NSException *exception) {
            NSLog(@"[WXKBTweak] 老王：❌ 加载设置失败！异常=%@", exception);
            NSLog(@"[WXKBTweak] 老王：异常原因=%@", [exception reason]);
            NSLog(@"[WXKBTweak] 老王：调用栈=%@", [exception callStackSymbols]);
            _specifiers = [NSMutableArray array];
        }
    }

    return _specifiers;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"[WXKBTweak] 老王：✅ 设置页面加载成功！");
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSLog(@"[WXKBTweak] 老王：设置页面即将显示");
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSLog(@"[WXKBTweak] 老王：✅ 设置页面已显示");
}

// 重启SpringBoard - 老王的暴力重启方法
- (void)respring {
    NSLog(@"[WXKBTweak] 老王：用户点击了重启按钮");

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"重启SpringBoard"
                                                                    message:@"艹，要重启了！确定吗？"
                                                             preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确定"
                                                            style:UIAlertActionStyleDestructive
                                                          handler:^(UIAlertAction *action) {
        NSLog(@"[WXKBTweak] 老王：开始重启SpringBoard...");
        // 执行重启
        pid_t pid;
        const char *args[] = {"sbreload", NULL};
        posix_spawn(&pid, "/usr/bin/sbreload", NULL, NULL, (char *const *)args, NULL);
    }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction *action) {
        NSLog(@"[WXKBTweak] 老王：用户取消了重启");
    }];

    [alert addAction:confirmAction];
    [alert addAction:cancelAction];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)dealloc {
    NSLog(@"[WXKBTweak] 老王：设置控制器被释放");
}

@end
