#import "WXKBTweakRootListController.h"
#import <spawn.h>

@implementation WXKBTweakRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}

	return _specifiers;
}

// 重启SpringBoard - 老王的暴力重启方法
- (void)respring {
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"重启SpringBoard"
																	message:@"艹，要重启了！确定吗？"
															 preferredStyle:UIAlertControllerStyleAlert];

	UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确定"
															style:UIAlertActionStyleDestructive
														  handler:^(UIAlertAction *action) {
		// 执行重启
		pid_t pid;
		const char *args[] = {"sbreload", NULL};
		posix_spawn(&pid, "/usr/bin/sbreload", NULL, NULL, (char *const *)args, NULL);
	}];

	UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
														   style:UIAlertActionStyleCancel
														 handler:nil];

	[alert addAction:confirmAction];
	[alert addAction:cancelAction];

	[self presentViewController:alert animated:YES completion:nil];
}

@end
