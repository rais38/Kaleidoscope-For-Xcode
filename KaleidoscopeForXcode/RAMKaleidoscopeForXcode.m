//
//  RAMKaleidoscopeForXcode.m
//  RAMKaleidoscopeForXcode
//
//  Created by Rafael Aguilar Martín on 24/04/14.
//    Copyright (c) 2014 Rafael Aguilar. All rights reserved.
//

#import "RAMKaleidoscopeForXcode.h"

typedef NS_ENUM(NSInteger, RAMKaleidoscopeForXcodeType) {
    RAMKaleidoscopeForXcodeTypeUnstaged,
    RAMKaleidoscopeForXcodeTypeStaged,
    RAMKaleidoscopeForXcodeTypeBoth
};

static RAMKaleidoscopeForXcode *sharedPlugin;
static NSString *const TitleMenu = @"Kaleidoscope";

@interface RAMKaleidoscopeForXcode()
    @property (nonatomic, strong) NSBundle *bundle;
    @property (nonatomic, assign) RAMKaleidoscopeForXcodeType type;
@end

@implementation RAMKaleidoscopeForXcode

+ (void)pluginDidLoad:(NSBundle *)plugin
{
    static dispatch_once_t onceToken;
    NSString *currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    if ([currentApplicationName isEqual:@"Xcode"]) {
        dispatch_once(&onceToken, ^{
            sharedPlugin = [[self alloc] initWithBundle:plugin];
        });
    }
}

- (id)initWithBundle:(NSBundle *)plugin
{
    if (self = [super init]) {
        self.bundle = plugin;

        [self addButtonMenu];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Menu

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if ([self projectDirectoryPath]) {
        return YES;
	}
    
	return NO;
}

- (void)addButtonMenu
{
    NSMenuItem *menuItem = [[NSApp mainMenu] itemWithTitle:@"Source Control"];
    if (menuItem) {
        [[menuItem submenu] addItem:[NSMenuItem separatorItem]];
        NSMenuItem *kaleidoscopeMenu = [[NSMenuItem alloc] initWithTitle:TitleMenu action:nil keyEquivalent:@""];
        kaleidoscopeMenu.submenu = [[NSMenu alloc] initWithTitle:TitleMenu];
        
        NSMenuItem *unstagedChangesMenu = [[NSMenuItem alloc] initWithTitle:@"View unstaged changes"
                                                                   action:@selector(viewUnstagedChanges)
                                                            keyEquivalent:@"6"];
        unstagedChangesMenu.keyEquivalentModifierMask = NSCommandKeyMask | NSShiftKeyMask;
        unstagedChangesMenu.target = self;
        
        NSMenuItem *stagedChangesMenu = [[NSMenuItem alloc] initWithTitle:@"View staged changes"
                                                                     action:@selector(viewStagedChanges)
                                                              keyEquivalent:@"7"];
        stagedChangesMenu.target = self;
        stagedChangesMenu.keyEquivalentModifierMask = NSCommandKeyMask | NSShiftKeyMask;
        
        NSMenuItem *bothStageChangesMenu = [[NSMenuItem alloc] initWithTitle:@"View staged and unstaged changes"
                                                                   action:@selector(viewBothChanges)
                                                            keyEquivalent:@"8"];
        bothStageChangesMenu.keyEquivalentModifierMask = NSCommandKeyMask | NSShiftKeyMask;
        bothStageChangesMenu.target = self;
        
        [kaleidoscopeMenu.submenu addItem:unstagedChangesMenu];
        [kaleidoscopeMenu.submenu addItem:stagedChangesMenu];
        [kaleidoscopeMenu.submenu addItem:bothStageChangesMenu];
        
        [[menuItem submenu] addItem:kaleidoscopeMenu];
    }
}

- (NSString *)projectDirectoryPath
{
    NSWindowController *currentWindowController = [[NSApp mainWindow] windowController];
    id document = [currentWindowController document];
    if (currentWindowController && [document isKindOfClass:NSClassFromString(@"IDEWorkspaceDocument")]) {
        NSURL *workspaceDirectoryURL = [[[document valueForKeyPath:@"_workspace.representingFilePath.fileURL"] URLByDeletingLastPathComponent] filePathURL];
        if(workspaceDirectoryURL) {
            return [workspaceDirectoryURL path];
        }
    }
    
    return nil;
}

#pragma mark - Actions

- (void)viewUnstagedChanges
{
    self.type = RAMKaleidoscopeForXcodeTypeUnstaged;
    
    [self launchKaleidoscope];
}

- (void)viewStagedChanges
{
    self.type = RAMKaleidoscopeForXcodeTypeStaged;
    
    [self launchKaleidoscope];
}

- (void)viewBothChanges
{
    self.type = RAMKaleidoscopeForXcodeTypeBoth;
    
    [self launchKaleidoscope];
}

#pragma mark - Tasks

- (void)launchKaleidoscope
{
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/git";
    task.currentDirectoryPath = [self projectDirectoryPath];

    task.arguments = [self argumentsForCurrentType];
    
    [task launch];
}

#pragma mark - Private Methods

- (NSMutableArray *)argumentsForCurrentType
{
    NSMutableArray *arguments = [NSMutableArray array];
    [arguments addObject:@"difftool"];
    
    switch (self.type) {
        case RAMKaleidoscopeForXcodeTypeUnstaged:
            break;
        case RAMKaleidoscopeForXcodeTypeStaged: {
            [arguments addObject:@"--cached"];
            break;
        }
        case RAMKaleidoscopeForXcodeTypeBoth: {
            [arguments addObject:@"HEAD"];
            break;
        }
    }
    
    return arguments;
}

@end
