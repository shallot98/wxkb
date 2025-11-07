#import <UIKit/UIKit.h>

@interface PSViewController : UIViewController
@end

@interface PSListController : PSViewController {
    NSMutableArray *_specifiers;
}
- (NSArray *)loadSpecifiersFromPlistName:(NSString *)name target:(id)target;
- (NSArray *)specifiers;
@end
