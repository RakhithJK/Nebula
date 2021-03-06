#include "NBLRootListController.h"
#include "NBLBlacklistController.h"
#import <objc/runtime.h>

#define kWidth [[UIApplication sharedApplication] keyWindow].frame.size.width

@protocol PreferencesTableCustomView
- (id)initWithSpecifier:(id)arg1;

@optional
- (CGFloat)preferredHeightForWidth:(CGFloat)arg1;
- (CGFloat)preferredHeightForWidth:(CGFloat)arg1 inTableView:(id)arg2;
@end

@interface NBLPrefBannerView : UITableViewCell <PreferencesTableCustomView> {
    UILabel *label;
}

@end
//banner
@implementation NBLPrefBannerView

- (id)initWithSpecifier:(PSSpecifier *)specifier {
	self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
	if (self) {

		CGRect labelFrame = CGRectMake(0, -15, kWidth, 70);

		label = [[UILabel alloc] initWithFrame:labelFrame];

		[label.layer setMasksToBounds:YES];
		[label setNumberOfLines:1];
		label.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:40];

		label.textColor = [UIColor blackColor];
		//label.textAlignment = NSTextAlignmentCenter;
		label.text = @"Nebula";

		NSTextAttachment *attachment = [NSTextAttachment new];
		UIImage *image = [UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/Nebula.bundle/Icon@3x.png"];
		CGSize size = image.size;
		attachment.image = resizeImage(image, CGSizeMake(size.width + 14.0, size.height + 14.0));
		attachment.bounds = CGRectMake(-8.0, -7.0, attachment.image.size.width, attachment.image.size.height);

		NSAttributedString *attrString = [NSAttributedString attributedStringWithAttachment:attachment];
		NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:@""];
		[text appendAttributedString:attrString];

		NSMutableAttributedString *secondText = [[NSMutableAttributedString alloc] initWithString:@"Nebula"];

		[text appendAttributedString:secondText];

		label.textAlignment = NSTextAlignmentCenter;
		label.attributedText = text;

		[self addSubview:label];



	}
	return self;
}
- (CGFloat)preferredHeightForWidth:(CGFloat)arg1 {
    return 70.0f;
}
@end

@implementation PSTableCell (Nebula)

+ (void)load {
	//if we were to swizzle twice, after the second swizzle, our changes would be reversed
	//we can override +load because very few classes implement this method (and PSTableCell is no exception)
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		Class class = [self class];

		//get the original selector and the new selector we add (remember this is a category)
		//in categories you can add selectors
		SEL originalSelector = @selector(layoutSubviews);
		SEL swizzledSelector = @selector(nebulaLayoutSubviews);

		//we are swizzling layoutSubviews, which is an instance method, so we need the instance methods
		//of course, our new method is also an instance method
		Method originalMethod = class_getInstanceMethod(class, originalSelector);
		Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);

		//add the method. At this stage, there is no exchange of implementations.
		BOOL didAddMethod =
		class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));

		//if it managed to add the method, we can simply replace layoutSubviews with our custom one
		//this means that any calls to layoutSubviews will be redirected to nebulaLayoutSubviews
		if (didAddMethod) {
			class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
		} else {
			//if, for whatever reason, the method wasn't added, we can just swap the implementations round
			//this basically means that the code from nebulaLayoutSubviews will be put inside layoutSubviews.
			//this has the same effect as swapping around the methods, but is a different approach
			//rather than redirecting, we simply run different code
			method_exchangeImplementations(originalMethod, swizzledMethod);
		}
	});
}

- (void)nebulaLayoutSubviews {
	/*
	This looks like it would cause an infinite loop. It doesn't! The code in this method will be run in layoutSubviews,
	and the code from layoutSubviews will be run in this method (the code has been swapped one way or another, see above).
	We are effectively inside layoutSubviews right now. Because nebulaLayoutSubviews contains the original code now,
	calling it is like calling %orig. If we were to not call it, it would have the same possible consequences as forgetting
	%orig (e.g. crashes).
	*/
	[self nebulaLayoutSubviews];
	NSString *keyPath = [[self valueForKeyPath:@"superview.delegate"] respondsToSelector:NSSelectorFromString(@"delegate")] ? @"superview.delegate.delegate.class" : @"superview.delegate.class";
	if([NSStringFromClass((Class)[self valueForKeyPath:keyPath]) isEqualToString:@"NBLRootListController"]) {
		if(self.accessoryView) {
			self.accessoryView.layer.borderWidth = 0;
		}
	}
}

@end

#import <spawn.h>
#import <AudioToolbox/AudioServices.h>

@interface SQRespringControl : NSObject
+(void)respring;
@end

@implementation SQRespringControl

//beautiful and gentle respring effect
+ (void)respring {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"UIStatusBarHide" object:nil userInfo:nil]; //fade out the status bar

	//AudioServicesPlaySystemSound(1521); //triple haptic to tell user we're respringing
    //make a visual effect view to fade in for the blur

    UIVisualEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];

    UIVisualEffectView *visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];

    visualEffectView.frame = [[UIApplication sharedApplication] keyWindow].bounds;
    visualEffectView.alpha = 0.0;

    //add it to the main window, but with no alpha
    [[[UIApplication sharedApplication] keyWindow] addSubview:visualEffectView];

    //animate in the alpha
    [UIView animateWithDuration:0.5f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         visualEffectView.alpha = 1.0f;
                     }
                     completion:^(BOOL finished){
                         if (finished) {
                             //call the animation here for the screen fade and respring
					    pid_t pid;
                             const char* args[] = {"killall", "-9", "backboardd", NULL};
                             posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char* const*)args, NULL);
                         }
                     }];

    //sleep(15);

    //[[UIScreen mainScreen] setBrightness:0.0f]; //so the screen fades back in when the respringing is done
}
@end

@implementation NBLRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}

	return _specifiers;
}

-(void)viewWillAppear:(BOOL)a {
	[super viewWillAppear:a];

	/*
	when ya done with de prefs
	an' ya want de change kept
	gotta press de button at de top

	dats de respring ting
	it give ya de progress ring
	so it look like ya phone has stopped

	de reality is
	im not takin de piss
	sprin'board has gone an' dropped off

	while its asleep
	behind all of de scenes
	into de plist de changes will pop
	*/
	
	/*
	It is worth noting that the changes are not written during the respring. They are written before.
	(The respring allows the tweak to reload all the values.)
	I was using poetic license.
	*/
	
	UIBarButtonItem *respringTing = [[UIBarButtonItem alloc] initWithTitle:@"Respring" style:UIBarButtonItemStylePlain target:[SQRespringControl class] action:@selector(respring)];
	respringTing.tintColor = [UIColor colorWithRed:50/255.0 green:55/255.0 blue:64/255.0 alpha:1.0];
	[self.navigationItem setRightBarButtonItem:respringTing];

	[UISwitch appearanceWhenContainedInInstancesOfClasses:@[self.class]].onTintColor = [UIColor colorWithRed:50/255.0 green:55/255.0 blue:64/255.0 alpha:1.0];
}

@end
