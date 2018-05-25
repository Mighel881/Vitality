#import "FLAnimatedImage.h"
#import "VLYSettings.h"
#import <SpringBoard/SBWallpaperController.h>

VLYSettings *settings;

FLAnimatedImageView *imageView;

#pragma mark - Setup

void updateAnimatedWallpaperView() {
    // Create and set animatedImage
    NSData *data = settings.animatedImageData;
    FLAnimatedImage *image = [FLAnimatedImage animatedImageWithGIFData:data];
    imageView.animatedImage = image;

    // Hide view if not enabled
    imageView.hidden = !settings.enabled;
}

void (^createAnimatedGifView)(NSNotification *) = ^(NSNotification *nsNotification) {
    // Create imageView
    imageView = [[FLAnimatedImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;

    // Added to wallpaper window
    UIWindow *wallpaperWindow = [[%c(SBWallpaperController) sharedInstance] _window];
    [wallpaperWindow addSubview:imageView];

    // Add the image
    updateAnimatedWallpaperView();

    // Have the view update when setting does
    [settings registerPreferenceChangeBlock:^{
        updateAnimatedWallpaperView();
    }];
};

#pragma mark - Management

void (^startOrStopGif)(NSNotification *) = ^(NSNotification *notification) {
    NSString *name = notification.name;
    NSDictionary *userInfo = notification.userInfo;

    if ([name isEqualToString:@"SBLockScreenUndimmedNotification"] || [name isEqualToString:@"SBHomescreenIconsWillAppearNotification"]) {
        // Begin animating because view is visible
        [imageView startAnimating];
    } else if ([name isEqualToString:@"SBLockScreenDimmedNotification"] || (userInfo && ![userInfo[@"kSBNotificationKeyDisplayIdentifier"] isEqual:@""])) {
        // Stop animating because hidden
        [imageView stopAnimating];
}
};

#pragma mark - Constructor

%ctor {
    // Create singleton
    settings = [VLYSettings sharedSettings];

    // Add the animated view when SpringBoard loads
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:createAnimatedGifView];

    // Register for notifications to start / stop gif apropriately
    [center addObserverForName:@"SBDisplayDidLaunchNotification" object:nil queue:[NSOperationQueue mainQueue] usingBlock:startOrStopGif];
    [center addObserverForName:@"SBHomescreenIconsWillAppearNotification" object:nil queue:[NSOperationQueue mainQueue] usingBlock:startOrStopGif];
    [center addObserverForName:@"SBLockScreenUndimmedNotification" object:nil queue:[NSOperationQueue mainQueue] usingBlock:startOrStopGif];
    [center addObserverForName:@"SBLockScreenDimmedNotification" object:nil queue:[NSOperationQueue mainQueue] usingBlock:startOrStopGif];
}
