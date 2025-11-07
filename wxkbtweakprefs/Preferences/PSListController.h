#import <UIKit/UIKit.h>

@interface PSListController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
    NSArray *_specifiers;
}

- (NSArray *)loadSpecifiersFromPlistName:(NSString *)name target:(id)target;
- (NSArray *)specifiers;

@end
