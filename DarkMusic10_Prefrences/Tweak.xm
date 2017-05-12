#import "../Headers.h"

@interface NotificationsExplanationView : NSObject
-(NSArray *)_accessibilityLabels;
@end

@interface AlertStyleView
-(UIImageView *)selectionImage;
@end

@interface PSSpecifier
- (id)propertyForKey:(id)arg1;
- (void)setProperty:(id)prop forKey:(id)key;
@end


%hook PSListController
- (void)viewWillAppear:(bool)arg1
{
	%orig;
	NSString *bundlePath = [[self bundle] bundlePath];

	if([bundlePath rangeOfString:@"/System/Library/"].location == NSNotFound){
		[%c(DarkMusic10Controller) isInTweakPref:YES];
	}else{
		[%c(DarkMusic10Controller) isInTweakPref:NO];
	}
}

%end

%group 
	%hook 
	-(id)initWithFrame:(CGRect)arg1
	{
		UILabel *label = %orig;
		label.textColor = TableViewFooterTextColor;
		return label;
	}
	%end
%end

%group PSUIPrefsListController
	%hook PSUIPrefsListController
	-(NSMutableArray *) specifiers
	{
		static dispatch_once_t sp;
		NSMutableArray *specifiers = %orig;
		dispatch_once(&sp, ^{
			for(PSSpecifier *specifier in specifiers){
				NSBundle *specifierBundle = ((NSBundle *)[specifier propertyForKey:@"pl_bundle"]);
				if(specifierBundle){
					NSString *bundlePath = [specifierBundle bundlePath];
					if([bundlePath rangeOfString:@"PreferenceLoader"].location != NSNotFound){
						UIImage *iconImage = [specifier propertyForKey:@"iconImage"];
						if([iconImage isDark])
							iconImage = [iconImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
							[specifier setProperty:iconImage forKey:@"iconImage"];
					}
				}
			}
		});
		return specifiers;
	}
	%end
%end

%group AirPortSettingsAPTableCell
	%hook APTableCell
	- (void)updateImages
	{
		%orig;
		UIImageView *lockView = MSHookIvar<UIImageView *>(self, "_lockView");
		lockView.image = [lockView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
		lockView.tintColor = TextColor;

		lockView = MSHookIvar<UIImageView *>(self, "_barsView");
		lockView.image = [lockView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
		lockView.tintColor = TextColor;
	}
	%end
%end

%group
	%hook 
	-(void)layoutSubviews
	{
		%orig;
		NSMutableArray *allLabels = MSHookIvar<NSMutableArray *>(self, "_labels");
		for(UILabel *label in allLabels){
			label.textColor = TableViewFooterTextColor;
		}
	}
	%end
%end

%group 
	%hook SetupView
	-(void)addStep:(id)step
	{
		UILabel *titleLabel = MSHookIvar<UILabel *>(self, "_title");
		titleLabel.textColor = TextColor;
		%orig;
	}

	-(void)setIcon:(UIImage *)image
	{
		%orig([image invertColors]);
	}

	-(id)_preferenceLabelWithText:(id)arg1
	{
		UILabel *setupLabel = %orig;
		setupLabel.textColor = LightTextColor;
		return setupLabel;
	}

	%end
%end

%group 
	%hook 
	-(UIView *)initWithType:(id)arg1
	{	
		UIView *styleView = %orig;
		UIImageView * = [self selectionImage];
		selectionImage.image = [selectionImage.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
		selectionImage.tintColor = LightBlueColor;
		return styleView;
	}
	%end
%end

%group  ACUIAppInstallCell
	%hook ACUIAppInstallCell
	- (UILabel *)_createLabelForPublisher:(id)arg1
	{
		UILabel *label = %orig;
		label.textColor = LightTextColor;
		return label;
	}
	- (UILabel *)_createLabelForAppName:(id)arg1
	{
		UILabel *label = %orig;
		label.textColor = CellTextColor;
		return label;
	}
	%end
%end


%ctor
{

	%init;

	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_async(queue, ^{

		NSString *systemVersionString = [[UIDevice currentDevice] systemVersion];
		int systemVersion = [systemVersionString intValue];

		/* Force PreferenceLoader to load before Nocturne */
		void *preferenceLoaderHandle = dlopen("/Library/MobileSubstrate/DynamicLibraries/PreferenceLoader.dylib", RTLD_NOW);
		if(preferenceLoaderHandle){
			void *preferencesUIHandle = dlopen("/System/Library/PrivateFrameworks/PreferencesUI.framework/PreferencesUI", RTLD_LAZY);
			if(preferencesUIHandle){
				%init(PSUIPrefsListController, PSUIPrefsListController = objc_getClass("PSUIPrefsListController"));
				dlclose(preferencesUIHandle);
			}else{
				HBLogError(@"Nocturne : Failed to dlopen PreferenceUI.framework for iOS %f", [systemVersionString floatValue]);
			}
		}

		void *accountUIHandle = dlopen("/System/Library/PrivateFrameworks/AccountsUI.framework/AccountsUI", RTLD_LAZY);
		if(accountUIHandle){
			%init(ACUIAppInstallCell, ACUIAppInstallCell = objc_getClass("ACUIAppInstallCell"));
			dlclose(accountUIHandle);
		}else{
			HBLogError(@"Nocturne : Failed to dlopen AccountsUI.framework for iOS %f", [systemVersionString floatValue]);
		}

		void *airPortSettingsHandle = dlopen("/System/Library/PreferenceBundles/AirPortSettings.bundle/AirPortSettings", RTLD_LAZY);
		if(airPortSettingsHandle){
			%init(AirPortSettingsAPTableCell, APTableCell = objc_getClass("APTableCell"));
			dlclose(airPortSettingsHandle);
		}else{
			HBLogError(@"Nocturne : Failed to dlopen AirPortSettings.bundle for iOS %f", [systemVersionString floatValue]);
		}

		void *wirelessModemSettingsHandle = dlopen("/System/Library/PreferenceBundles/WirelessModemSettings.bundle/WirelessModemSettings", RTLD_LAZY);
		if(wirelessModemSettingsHandle){
			%init(WirelessModemSettings, TetheringSwitchFooterView = objc_getClass("TetheringSwitchFooterView"));
			%init(WirelessModemSetupInstructions, SetupView = objc_getClass("SetupView"));
			dlclose(wirelessModemSettingsHandle);
		}else{
			HBLogError(@"DarkMusic10 : Failed to dlopen WirelessModemSettings.bundle for iOS %f", [systemVersionString floatValue]);
		}

		void *noctificationSettingsHandle = NULL;
		if(systemVersion == 8){
			noctificationSettingsHandle = dlopen("/System/Library/PreferenceBundles/NotificationSettings.bundle/NotificationsSettings", RTLD_LAZY);
		}
		else if(systemVersion >= 9){
			noctificationSettingsHandle = dlopen("/System/Library/PreferenceBundles/NotificationsSettings.bundle/NotificationsSettings", RTLD_LAZY);
		}
		if(noctificationSettingsHandle){
			%init(AlertStyleView, AlertStyleView = objc_getClass("AlertStyleView"));
		}else{
			HBLogError(@"DarkMusic10 : Failed to dlopen NotificationSettings.bundle for iOS %f", [systemVersionString floatValue]);
		}

		void *wallpaperHandle = dlopen("/System/Library/PreferenceBundles/Wallpaper.bundle/Wallpaper", RTLD_LAZY);
		if(wallpaperHandle){
			%init(WallpaperMagicTableCategoryLabel, WallpaperMagicTableCategoryLabel = objc_getClass("WallpaperMagicTableCategoryLabel"));
			dlclose(wallpaperHandle);
		}else{
			HBLogError(@"Nocturne : Failed to dlopen Wallpaper.bundle for iOS %f", [systemVersionString floatValue]);
		}

		void *photoUIHandle = dlopen("/Library/MobileSubstrate/DynamicLibraries/Nocturne_PhotosUI.dylib", RTLD_LAZY);
		if(!photoUIHandle)
			HBLogError(@"DarkMusic10 : Failed to dlopen DarkMusic10_PhotosUI.dylib for iOS %f", [systemVersionString floatValue]);
	});
}
