//
//  EpisodeCell.h
//  Charles
//
//  Created by Simon Støvring on 01/08/13.
//  Copyright (c) 2013 intuitaps. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface EpisodeCell : NSTableCellView <NSTextFieldDelegate>

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *videoName;
@property (nonatomic, strong) NSString *subtitleName;
@property (nonatomic, strong) void (^nameChanged)(NSString *newName);
@property (nonatomic, strong) void (^videoPathButtonClicked)(void);
@property (nonatomic, strong) void (^subtitlePathButtonClicked)(void);

@end
