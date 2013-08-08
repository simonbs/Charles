//
//  EpisodeCell.m
//  Charles
//
//  Created by Simon Støvring on 01/08/13.
//  Copyright (c) 2013 intuitaps. All rights reserved.
//

#import "EpisodeCell.h"

@interface EpisodeCell ()
@property (nonatomic, weak) IBOutlet NSTextField *nameTextField;
@property (nonatomic, weak) IBOutlet NSTextField *videoNameTextField;
@property (nonatomic, weak) IBOutlet NSTextField *subtitleNameTextField;
@end

@implementation EpisodeCell

#pragma mark -
#pragma mark Lifecycle

- (void)dealloc
{
    self.nameTextField = nil;
    self.videoNameTextField = nil;
    self.subtitleNameTextField = nil;
    self.name = nil;
    self.videoName = nil;
    self.subtitleName = nil;
    self.nameChanged = nil;
    self.videoPathButtonClicked = nil;
    self.subtitlePathButtonClicked = nil;
}

#pragma mark -
#pragma mark Public Accessors

- (void)setName:(NSString *)name
{
    if (![name isEqualToString:self.name])
    {
        self.nameTextField.stringValue = (name == nil) ? @"" : name;
        
        _name = name;
    }
}

- (void)setVideoName:(NSString *)videoName
{
    if (![videoName isEqualToString:self.videoName])
    {
        self.videoNameTextField.stringValue = (videoName == nil) ? @"" : videoName;
        
        _videoName = videoName;
    }
}

- (void)setSubtitleName:(NSString *)subtitleName
{
    if (![subtitleName isEqualToString:self.subtitleName])
    {
        self.subtitleNameTextField.stringValue = (subtitleName == nil) ? @"" : subtitleName;
        
        _subtitleName = subtitleName;
    }
}

#pragma mark -
#pragma mark Private Methods

- (IBAction)videoPathButtonClicked:(id)sender
{
    if (self.videoPathButtonClicked)
    {
        self.videoPathButtonClicked();
    }
}

- (IBAction)subtitlePathButtonClicked:(id)sender
{
    if (self.subtitlePathButtonClicked)
    {
        self.subtitlePathButtonClicked();
    }
}

#pragma mark -
#pragma mark Text Field Delegate

- (void)controlTextDidChange:(NSNotification *)notification
{
    if (notification.object == self.nameTextField && self.nameChanged)
    {
        self.nameChanged(self.nameTextField.stringValue);
    }
}

@end
