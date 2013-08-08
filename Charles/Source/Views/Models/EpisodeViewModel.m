//
//  EpisodeViewModel.m
//  Charles
//
//  Created by Simon Støvring on 01/08/13.
//  Copyright (c) 2013 intuitaps. All rights reserved.
//

#import "EpisodeViewModel.h"

@implementation EpisodeViewModel

#pragma mark -
#pragma mark Lifecycle

- (void)dealloc
{
    self.seasonNumber = nil;
    self.episodeNumber = nil;
    self.name = nil;
    self.fullName = nil;
    self.videoPath = nil;
    self.subtitlePath = nil;
}

@end
