//
//  AppDelegate.m
//  Charles
//
//  Created by Simon Støvring on 27/07/13.
//  Copyright (c) 2013 intuitaps. All rights reserved.
//

#import "AppDelegate.h"
#import "MainWindowController.h"

@interface AppDelegate ()
@property (nonatomic, strong) MainWindowController *mainController;
@end

@implementation AppDelegate

#pragma mark -
#pragma mark Lifecycle

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    CharlesClient *charles = [CharlesClient sharedClient];
    charles.apiKey = TVDBAPIKey;

    self.mainController = [[MainWindowController alloc] init];
    [self.mainController showWindow:self];
}

- (void)dealloc
{
    self.mainController = nil;
}

@end
