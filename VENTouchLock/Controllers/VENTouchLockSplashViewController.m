#import "VENTouchLockSplashViewController.h"
#import "VENTouchLockEnterPasscodeViewController.h"
#import "VENTouchLock.h"

NSString *const VENTouchLockSplashViewControllerSupressShowUnlockAnimated = @"VENTouchLockSplashViewControllerSupressShowUnlockAnimated";

@interface VENTouchLockSplashViewController ()
@property (nonatomic, assign) BOOL isSnapshotViewController;
@end

@implementation VENTouchLockSplashViewController

#pragma mark - Creation and Lifecycle

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (!self.isSnapshotViewController) {
        self.touchLock.backgroundLockVisible = NO;
    }
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    if (!self.isSnapshotViewController) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showUnlockAnimated:NO];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
        });
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

}

#pragma mark - Supress Show Unlock Animated

+ (void)resetSupressShowUnlockAnimated
{
    NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
    [standardDefaults removeObjectForKey:VENTouchLockSplashViewControllerSupressShowUnlockAnimated];
    [standardDefaults synchronize];
}

+ (void)supressShowUnlockAnimatedOnce {
    NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
    [standardDefaults setBool:YES forKey:VENTouchLockSplashViewControllerSupressShowUnlockAnimated];
    [standardDefaults synchronize];
}

+ (BOOL)shouldSupressShowUnlockAnimatedOnce {
    NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
    return [standardDefaults boolForKey:VENTouchLockSplashViewControllerSupressShowUnlockAnimated];
}

#pragma mark - Present unlock methods

- (void)showUnlockAnimated:(BOOL)animated
{
    if([VENTouchLockSplashViewController shouldSupressShowUnlockAnimatedOnce] == false) {
        if ([VENTouchLock shouldUseTouchID]) {
            [self showTouchID];
        }
        else {
            [self showPasscodeAnimated:animated];
        }
    }else {
        [VENTouchLockSplashViewController resetSupressShowUnlockAnimated];
    }
}

- (void)showTouchID
{
    __weak __typeof__(self) weakSelf = self;
    [self.touchLock requestTouchIDWithCompletion:^(VENTouchLockTouchIDResponse response) {
        switch (response) {
            case VENTouchLockTouchIDResponseSuccess:
                [weakSelf unlockWithType:VENTouchLockSplashViewControllerUnlockTypeTouchID];
                break;
            case VENTouchLockTouchIDResponseUsePasscode:
                [weakSelf showPasscodeAnimated:YES];
                break;
            default:
                break;
        }
    }];
}

- (void)showPasscodeAnimated:(BOOL)animated
{
    UIViewController *enterPassCodeViewController;
    if (self.touchLock.appearance.passcodeViewControllerShouldEmbedInNavigationController) {
        enterPassCodeViewController = [[self enterPasscodeVC] embeddedInNavigationController];
    } else {
        enterPassCodeViewController = [self enterPasscodeVC];
    }

    [self presentViewController:enterPassCodeViewController animated:animated completion:nil];
}

- (VENTouchLockEnterPasscodeViewController *)enterPasscodeVC
{
    VENTouchLockEnterPasscodeViewController *enterPasscodeVC = [[VENTouchLockEnterPasscodeViewController alloc] init];
    __weak __typeof__(self) weakSelf = self;
    enterPasscodeVC.willFinishWithResult = ^(BOOL success) {
        if (success) {
            [weakSelf unlockWithType:VENTouchLockSplashViewControllerUnlockTypePasscode];
        }
        else {
            [weakSelf dismissViewControllerAnimated:YES completion:nil];
        }
    };
    return enterPasscodeVC;
}

- (void)appWillEnterForeground
{
    if (!self.presentedViewController) {
        [self showUnlockAnimated:NO];
    }
}

- (void)unlockWithType:(VENTouchLockSplashViewControllerUnlockType)unlockType
{
    [self dismissWithUnlockSuccess:YES
                        unlockType:unlockType
                          animated:YES];
}

- (void)dismissWithUnlockSuccess:(BOOL)success
                      unlockType:(VENTouchLockSplashViewControllerUnlockType)unlockType
                        animated:(BOOL)animated
{
    
    if(success || unlockType != VENTouchLockSplashViewControllerUnlockTypeNone) {
        [[VENTouchLock sharedInstance] setIsAppLocked:NO];
        [[NSNotificationCenter defaultCenter] postNotificationName:VENTouchLockDidUnlockApp object:nil];
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        self.presentingViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [self.presentingViewController dismissViewControllerAnimated:animated completion:^{
            if (self.didFinishWithSuccess) {
                self.didFinishWithSuccess(success, unlockType);
            }
        }];
    }else {
        [self dismissViewControllerAnimated:animated completion:^{
            if (self.didFinishWithSuccess) {
                self.didFinishWithSuccess(success, unlockType);
            }
        }];
    }
}

- (void)initialize
{
    _touchLock = [VENTouchLock sharedInstance];
}

@end