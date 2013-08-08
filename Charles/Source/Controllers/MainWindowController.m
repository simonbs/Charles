//
//  MainWindowController.m
//  Charles
//
//  Created by Simon Støvring on 01/08/13.
//  Copyright (c) 2013 intuitaps. All rights reserved.
//

#import "MainWindowController.h"
#import "EpisodeViewModel.h"
#import "EpisodeCell.h"

#define kTableViewCellIdentifier @"EpisodeCell"

#define kFilenameMinimumSeasonNumberLength 2
#define kFilenameMinimumEpisodeNumberLength 2

@interface MainWindowController ()
@property (nonatomic, strong) NSString *searchTerm;
@property (nonatomic, strong) NSArray *searchResults;
@property (nonatomic, strong) CharlesTVSeries *selectedSearchResult;
@property (nonatomic, strong) CharlesSeason *selectedSeason;
@property (nonatomic, strong) NSMutableArray *episodeViewModels;
@property (nonatomic, strong) NSString *outputFolderPath;
@property (nonatomic, weak) IBOutlet NSPopUpButton *searchResultsPopUp;
@property (nonatomic, weak) IBOutlet NSPopUpButton *seasonsPopUp;
@property (nonatomic, weak) IBOutlet NSTableView *tableView;
@property (nonatomic, weak) IBOutlet NSButton *selectVideosFolderButton;
@property (nonatomic, weak) IBOutlet NSButton *selectSubtitlesFolderButton;
@property (nonatomic, weak) IBOutlet NSButton *performOperationsButton;
@end

@implementation MainWindowController

#pragma mark -
#pragma mark Lifecycle

- (id)init
{
    if (self = [super initWithWindowNibName:@"MainWindow" owner:self])
    {
        [self addObserver:self forKeyPath:@"selectedSearchResult" options:NSKeyValueObservingOptionOld context:NULL];
        [self addObserver:self forKeyPath:@"selectedSeason" options:NSKeyValueObservingOptionOld context:NULL];
    }
    
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"selectedSearchResult"])
    {
        if ([change objectForKey:NSKeyValueChangeOldKey] && [change objectForKey:NSKeyValueChangeOldKey] != [NSNull null])
        {
            // Check if the new and the previous selected search results are the same, if not, load the seasons
            CharlesTVSeries *old = [change objectForKey:NSKeyValueChangeOldKey];
            if (![self.selectedSearchResult isEqual:old])
            {
                [self loadSeasons];
            }
        }
        else
        {
            // No search result was previously selected, so this must be the first
            [self loadSeasons];
        }
    }
    else if ([keyPath isEqualToString:@"selectedSeason"])
    {
        if ([change objectForKey:NSKeyValueChangeOldKey] && [change objectForKey:NSKeyValueChangeOldKey] != [NSNull null])
        {
            // Check if the new and the previous selected season are the same, if not, update the table viewq
            CharlesSeason *old = [change objectForKey:NSKeyValueChangeOldKey];
            if (![self.selectedSeason isEqual:old])
            {
                [self updateEpisodesList];
            }
        }
        else
        {
            // No season was previously selected, so this must be the first
            [self updateEpisodesList];
        }
    }
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"selectedSearchResult"];
    [self removeObserver:self forKeyPath:@"selectedSeason"];
    
    self.searchTerm = nil;
    self.searchResults = nil;
    self.selectedSearchResult = nil;
    self.selectedSeason = nil;
    self.episodeViewModels = nil;
    self.outputFolderPath = nil;
    self.searchResultsPopUp = nil;
    self.seasonsPopUp = nil;
    self.tableView = nil;
    self.selectVideosFolderButton = nil;
    self.selectSubtitlesFolderButton = nil;
    self.performOperationsButton = nil;
}

#pragma mark -
#pragma mark Private Methods

- (IBAction)search:(id)sender
{
    [self.searchResultsPopUp removeAllItems];
    [self.seasonsPopUp removeAllItems];
    [self.episodeViewModels removeAllObjects];
    [self.tableView reloadData];
    
    self.selectVideosFolderButton.enabled = NO;
    self.selectSubtitlesFolderButton.enabled = NO;
    
    if ([self.searchTerm length] > 0)
    {
        [CharlesTVSeries searchTVSeriesByName:self.searchTerm completion:^(NSArray *results) {
            self.searchResults = results;
            
            for (CharlesTVSeries *tvSeries in results)
            {
                [self.searchResultsPopUp addItemWithTitle:tvSeries.name];
            }
            
            if ([self.searchResults count] > 0)
            {
                self.selectedSearchResult = [self.searchResults objectAtIndex:0];
            }
        } failure:^(NSError *error) {
            NSAlert *alert = [[NSAlert alloc] init];
            alert.messageText =
            alert.informativeText = NSLocalizedStringFromTable(@"An error occurred while searching for the TV series. Please try again.", @"MainWindowController", @"Informative text in alert shown when the search was unsuccesful.");
            alert.alertStyle = NSWarningAlertStyle;
            [alert runModal];
        }];
    }
}

- (IBAction)selectVideosFolder:(id)sender
{
    NSURL *url = [self selectFolder];
    if (!url)
    {
        // Don't do anything if no folder was selected
        return;
    }
    
    NSString *path = [url path];
    NSDictionary *files = [self filesMatchingEpisodesAtPath:path fileExtensions:[self videoFileExtensions]];
    NSArray *keys = [files allKeys];
    for (NSString *episodeNumber in keys)
    {
        NSString *filePath = [files objectForKey:episodeNumber];
        NSInteger index = [episodeNumber integerValue] - 1; // Episode number start at 1 but index start at 0
        if (index < [self.episodeViewModels count])
        {
            EpisodeViewModel *model = [self.episodeViewModels objectAtIndex:index];
            model.videoPath = filePath;
        }
    }
    
    [self.tableView reloadData];
}

- (IBAction)selectSubtitlesFolder:(id)sender
{
    NSURL *url = [self selectFolder];
    if (!url)
    {
        // Don't do anything if no folder was selected
        return;
    }
    
    NSString *path = [url path];
    NSDictionary *files = [self filesMatchingEpisodesAtPath:path fileExtensions:[self subtitleFileExtensions]];
    NSArray *keys = [files allKeys];
    for (NSString *episodeNumber in keys)
    {
        NSString *filePath = [files objectForKey:episodeNumber];
        NSInteger index = [episodeNumber integerValue] - 1; // Episode number start at 1 but index start at 0
        if (index < [self.episodeViewModels count])
        {
            EpisodeViewModel *model = [self.episodeViewModels objectAtIndex:index];
            model.subtitlePath = filePath;
        }
    }
    
    [self.tableView reloadData];
}

- (IBAction)selectOutputFolder:(id)sender
{
    NSURL *url = [self selectFolder];
    self.outputFolderPath = [url path];
    
    self.performOperationsButton.enabled = YES;
}

- (IBAction)searchResultSelected:(id)sender
{
    NSInteger index = self.searchResultsPopUp.indexOfSelectedItem;
    if (index >= 0 && index < [self.searchResults count])
    {
        self.selectedSearchResult = [self.searchResults objectAtIndex:index];
    }
    else
    {
        self.selectedSearchResult = nil;
        [self.searchResultsPopUp removeAllItems];
        [self.seasonsPopUp removeAllItems];
        [self.episodeViewModels removeAllObjects];
        [self.tableView reloadData];
    }
}

- (IBAction)seasonSelected:(id)sender
{
    NSArray *seasons = self.selectedSearchResult.details.seasons;
    
    NSInteger index = self.seasonsPopUp.indexOfSelectedItem;
    if (index >= 0 && index < [seasons count])
    {
        self.selectedSeason = [seasons objectAtIndex:index];
        
        self.selectVideosFolderButton.enabled = YES;
        self.selectSubtitlesFolderButton.enabled = YES;
    }
    else
    {
        self.selectedSeason = nil;
        [self.seasonsPopUp removeAllItems];
        [self.episodeViewModels removeAllObjects];
        [self.tableView reloadData];
        
        self.selectVideosFolderButton.enabled = NO;
        self.selectSubtitlesFolderButton.enabled = NO;
    }
}

- (IBAction)performOperations:(id)sender
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *seasonFolderName = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Season %@", @"MainWindowController", @"Name of season folder. %@ is replaced with the season number."), self.selectedSeason.seasonNumber];
    NSString *seasonFolder = [self.outputFolderPath stringByAppendingPathComponent:seasonFolderName];
    NSError *error = nil;
    [fileManager createDirectoryAtPath:seasonFolder withIntermediateDirectories:NO attributes:nil error:&error];
    if (error)
    {
        NSLog(@"Could not create directory '%@': %@", seasonFolder, error);
    }
    
    for (EpisodeViewModel *model in self.episodeViewModels)
    {
        NSString *name = model.name;
        NSString *fullName = model.fullName;
        NSNumber *episodeNumber = model.episodeNumber;
        NSString *videoPath = model.videoPath;
        NSString *subtitlePath = model.subtitlePath;
        
        NSString *episodeFolderName = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Episode %@ - %@", @"MainWindowController", @"Name of episode folders. First %@ is replaced with episode number, second %@ is replaced with the episode name."), episodeNumber, name];
        NSString *episodeFolder = [seasonFolder stringByAppendingPathComponent:episodeFolderName];
        
        // Create directory for files
        if (videoPath || subtitlePath)
        {
            NSError *error = nil;
            [fileManager createDirectoryAtPath:episodeFolder withIntermediateDirectories:NO attributes:nil error:&error];
            if (error)
            {
                NSLog(@"Could not create directory '%@': %@", episodeFolder, error);
            }
        }
        
        // Move video file
        if (videoPath)
        {
            NSString *newVideoFileName = [NSString stringWithFormat:@"%@.%@", fullName, [videoPath pathExtension]];
            NSString *newVideoPath = [episodeFolder stringByAppendingPathComponent:newVideoFileName];
            
            NSError *error = nil;
            [fileManager moveItemAtPath:videoPath toPath:newVideoPath error:&error];
            if (error)
            {
                NSLog(@"Could not move file from '%@' to '%@': %@", videoPath, newVideoPath, error);
            }
        }
        
        // Move subtitle file
        if (subtitlePath)
        {
            NSString *newSubtitleFileName = [NSString stringWithFormat:@"%@.%@", fullName, [subtitlePath pathExtension]];
            NSString *newSubtitlePath = [episodeFolder stringByAppendingPathComponent:newSubtitleFileName];
            
            NSError *error = nil;
            [fileManager moveItemAtPath:subtitlePath toPath:newSubtitlePath error:&error];
            if (error)
            {
                NSLog(@"Could not move file from '%@' to '%@': %@", videoPath, newSubtitlePath, error);
            }
        }
    }

    NSString *message = NSLocalizedStringFromTable(@"Succeeded!", @"MainWindowController", @"Message in the alert shown when the operations were performed.");
    NSString *defaultButton = NSLocalizedStringFromTable(@"OK", @"MainWindowController", @"Title of default button in the alert shown when the operations were performed.");
    NSString *informationText = NSLocalizedStringFromTable(@"The operations has been successfully performed.", @"MainWindowController", @"Informative text in the alert shown when the operations were performed.");
    NSAlert *alert = [NSAlert alertWithMessageText:message defaultButton:defaultButton alternateButton:nil otherButton:nil informativeTextWithFormat:informationText, nil];
    [alert runModal];
}

- (void)loadSeasons
{
    [self.seasonsPopUp removeAllItems];
    
    [self.selectedSearchResult loadDetails:^(BOOL success, NSError *error) {
        if (success)
        {
            NSArray *seasons = self.selectedSearchResult.details.seasons;
            for (CharlesSeason *season in seasons)
            {
                NSString *title = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Season %@", @"MainWindowController", @"Title of a season in the popup. %i is replaced with the season number."), season.seasonNumber];
                [self.seasonsPopUp addItemWithTitle:title];
            }
            
            if ([seasons count] > 0)
            {
                self.selectedSeason = [seasons objectAtIndex:0];
                
                self.selectVideosFolderButton.enabled = YES;
                self.selectSubtitlesFolderButton.enabled = YES;
            }
        }
        else
        {
            NSAlert *alert = [[NSAlert alloc] init];
            alert.messageText =
            alert.informativeText = NSLocalizedStringFromTable(@"An error occurred while loading the seasons. Please try again.", @"MainWindowController", @"Informative text in alert shown when loading the seasons failed.");
            alert.alertStyle = NSWarningAlertStyle;
            [alert runModal];
        }
    }];
}

- (void)updateEpisodesList
{
    if (!self.episodeViewModels)
    {
        self.episodeViewModels = [NSMutableArray array];
    }
    else
    {
        [self.episodeViewModels removeAllObjects];
    }
    
    if ([self.selectedSeason.episodes count] > 0)
    {
        NSNumberFormatter *seasonNumberFormatter = [self seasonNumberFormatter];
        NSNumberFormatter *episodeNumberFormatter = [self episodeNumberFormatter];
        
        for (CharlesEpisode *episode in self.selectedSeason.episodes)
        {
            NSString *seasonNumber = [seasonNumberFormatter stringFromNumber:episode.seasonNumber];
            NSString *episodeNumber = [episodeNumberFormatter stringFromNumber:episode.episodeNumber];
        
            EpisodeViewModel *model = [[EpisodeViewModel alloc] init];
            model.seasonNumber = episode.seasonNumber;
            model.episodeNumber = episode.episodeNumber;
            model.name = episode.name;
            model.fullName = [NSString stringWithFormat:@"S%@E%@ - %@", seasonNumber, episodeNumber, episode.name];

            [self.episodeViewModels addObject:model];
        }
    }
    
    [self.tableView reloadData];
}

- (NSURL *)selectVideoFile
{
    return [self selectFile:[self videoFileExtensions]];
}

- (NSURL *)selectSubtitleFile
{
    return [self selectFile:[self subtitleFileExtensions]];
}

- (NSURL *)selectFile:(NSArray *)allowedFileTypes
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.canChooseFiles = YES;
    openPanel.canChooseDirectories = NO;
    openPanel.allowsMultipleSelection = NO;
    openPanel.allowsOtherFileTypes = NO;
    openPanel.allowedFileTypes = allowedFileTypes;
    
    if ([openPanel runModal])
    {
        return openPanel.URL;
    }
    
    return nil;
}

- (NSURL *)selectFolder
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.canChooseFiles = NO;
    openPanel.canChooseDirectories = YES;
    openPanel.allowsMultipleSelection = NO;
    
    if ([openPanel runModal])
    {
        return openPanel.URL;
    }
    
    return nil;
}

- (NSNumberFormatter *)seasonNumberFormatter
{
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"seasonNumber" ascending:NO];
    NSArray *seasons = [self.selectedSearchResult.details.seasons sortedArrayUsingDescriptors:@[ sortDescriptor ]];
    NSUInteger lastCharLength = [[((CharlesSeason *)[seasons lastObject]).seasonNumber stringValue] length];
    lastCharLength = (lastCharLength < kFilenameMinimumSeasonNumberLength) ? kFilenameMinimumSeasonNumberLength : lastCharLength;
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setPaddingPosition:NSNumberFormatterPadBeforePrefix];
    [numberFormatter setPaddingCharacter:@"0"];
    [numberFormatter setMinimumIntegerDigits:lastCharLength];
    
    return numberFormatter;
}

- (NSNumberFormatter *)episodeNumberFormatter
{
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"episodeNumber" ascending:NO];
    NSArray *episodes = [self.selectedSeason.episodes sortedArrayUsingDescriptors:@[ sortDescriptor ]];
    NSUInteger lastCharLength = [[((CharlesEpisode *)[episodes lastObject]).episodeNumber stringValue] length];
    lastCharLength = (lastCharLength < kFilenameMinimumEpisodeNumberLength) ? kFilenameMinimumEpisodeNumberLength : lastCharLength;
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setPaddingPosition:NSNumberFormatterPadBeforePrefix];
    [numberFormatter setPaddingCharacter:@"0"];
    [numberFormatter setMinimumIntegerDigits:lastCharLength];
    
    return numberFormatter;
}

- (NSString *)fileNameForPath:(NSString *)path
{
    NSArray *components = [path pathComponents];
    if ([components count] == 0)
    {
        return nil;
    }
    
    return [components objectAtIndex:[components count] - 1];
}

- (NSDictionary *)filesMatchingEpisodesAtPath:(NSString *)path fileExtensions:(NSArray *)fileExtensions
{
    NSError *error = nil;
    NSArray *fileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&error];
    if (!error)
    {
        NSNumberFormatter *seasonNumberFormatter = [self seasonNumberFormatter];
        NSNumberFormatter *episodeNumberFormatter = [self episodeNumberFormatter];
        
        CharlesSeason *season = self.selectedSeason;
        
        NSMutableDictionary *filesFound = [NSMutableDictionary dictionaryWithCapacity:[season.episodes count]];
        
        NSMutableString *regularFileExtensions = [NSMutableString string];
        for (NSUInteger i = 0; i < [fileExtensions count]; i++)
        {
            NSString *fileExtension = [fileExtensions objectAtIndex:i];
            if (i == 0)
            {
                [regularFileExtensions appendString:fileExtension];
            }
            else
            {
                [regularFileExtensions appendFormat:@"|%@", fileExtension];
            }
        }
        
        NSString *seasonNumber = [seasonNumberFormatter stringFromNumber:season.seasonNumber];
        for (CharlesEpisode *episode in season.episodes)
        {
            NSString *episodeNumber = [episodeNumberFormatter stringFromNumber:episode.episodeNumber];
            NSString *lookup = [NSString stringWithFormat:@"S%@E%@", seasonNumber, episodeNumber];
            
            NSString *pattern = [NSString stringWithFormat:@".*%@.*\\.(%@)$", lookup, regularFileExtensions];
            NSPredicate *lookupPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES[c] %@", pattern];
            NSArray *matches = [fileNames filteredArrayUsingPredicate:lookupPredicate];
            
            if ([matches count] > 0)
            {
                NSString *match = [matches objectAtIndex:0];
                NSString *filePath = [path stringByAppendingPathComponent:match];
                
                [filesFound setValue:filePath forKey:[episode.episodeNumber stringValue]];
            }
        }
        
        return filesFound;
    }
    else
    {
        NSLog(@"Could not read contents of directory at path '%@': %@", path, error);
    }
    
    return nil;
}

- (NSArray *)videoFileExtensions
{
    return @[ @"avi", @"mov", @"mp4", @"mkv" ];
}

- (NSArray *)subtitleFileExtensions
{
    return @[ @"srt", @"sub" ];
}

#pragma mark -
#pragma mark Table View Data Source

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    EpisodeViewModel *model = [self.episodeViewModels objectAtIndex:row];
    
    EpisodeCell *cell = [tableView makeViewWithIdentifier:kTableViewCellIdentifier owner:self];
    __weak EpisodeCell *weakCell = cell;
    
    cell.name = model.name;
    weakCell.videoName = [self fileNameForPath:model.videoPath];
    weakCell.subtitleName = [self fileNameForPath:model.subtitlePath];
    
    cell.nameChanged = ^(NSString *name) {
        model.name = name;
    };
    
    cell.videoPathButtonClicked = ^{
        NSURL *url = [self selectVideoFile];
        if (url)
        {
            NSString *path = [url path];
            model.videoPath = path;
            weakCell.videoName = [self fileNameForPath:path];
        }
    };
    
    cell.subtitlePathButtonClicked = ^{
        NSURL *url = [self selectSubtitleFile];
        if (url)
        {
            NSString *path = [url path];
            model.subtitlePath = path;
            weakCell.subtitleName = [self fileNameForPath:path];
        }
    };
    
    return cell;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [self.episodeViewModels count];
}

@end
