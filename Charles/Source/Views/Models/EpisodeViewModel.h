//
//  EpisodeViewModel.h
//  Charles
//
//  Created by Simon Støvring on 01/08/13.
//  Copyright (c) 2013 intuitaps. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EpisodeViewModel : NSObject

@property (nonatomic, strong) NSNumber *seasonNumber;
@property (nonatomic, strong) NSNumber *episodeNumber;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *fullName;
@property (nonatomic, strong) NSString *videoPath;
@property (nonatomic, strong) NSString *subtitlePath;

@end
