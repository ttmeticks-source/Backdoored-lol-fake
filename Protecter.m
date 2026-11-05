#import <Cocoa/Cocoa.h>

@interface ProtecterAppDelegate : NSObject <NSApplicationDelegate>
@property (strong) NSWindow *window;
@property (strong) NSTextField *statusLabel;
@property (strong) NSTextField *countLabel;
@property (strong) NSButton *scanButton;
@property (strong) NSTextView *resultsView;
@property (strong) NSProgressIndicator *spinner;
@end

@implementation ProtecterAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    NSRect frame = NSMakeRect(0, 0, 760, 570);
    self.window = [[NSWindow alloc] initWithContentRect:frame
        styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
                   NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable)
        backing:NSBackingStoreBuffered defer:NO];
    self.window.title = @"Protecter";
    self.window.minSize = NSMakeSize(650, 500);
    [self.window center];

    NSView *root = self.window.contentView;
    NSImageView *shield = [[NSImageView alloc] initWithFrame:NSMakeRect(25, 493, 44, 44)];
    shield.image = [NSImage imageWithSystemSymbolName:@"checkmark.shield.fill"
        accessibilityDescription:@"Protecter shield"];
    shield.contentTintColor = [NSColor systemBlueColor];
    [root addSubview:shield];

    NSTextField *title = [self label:@"Protecter" size:29 weight:NSFontWeightBold];
    title.frame = NSMakeRect(82, 505, 500, 36);
    [root addSubview:title];

    NSTextField *subtitle = [self label:@"Local Downloads security review" size:13 weight:NSFontWeightRegular];
    subtitle.textColor = NSColor.secondaryLabelColor;
    subtitle.frame = NSMakeRect(84, 484, 400, 20);
    [root addSubview:subtitle];

    self.statusLabel = [self label:@"Ready to scan your Downloads folder." size:13 weight:NSFontWeightMedium];
    self.statusLabel.textColor = NSColor.secondaryLabelColor;
    self.statusLabel.frame = NSMakeRect(26, 442, 560, 22);
    [root addSubview:self.statusLabel];

    self.countLabel = [self label:@"Files checked: 0     Items to review: 0" size:13 weight:NSFontWeightRegular];
    self.countLabel.textColor = NSColor.secondaryLabelColor;
    self.countLabel.frame = NSMakeRect(26, 414, 500, 21);
    [root addSubview:self.countLabel];

    self.scanButton = [NSButton buttonWithTitle:@"Scan Downloads" target:self action:@selector(startScan:)];
    self.scanButton.frame = NSMakeRect(26, 370, 150, 32);
    self.scanButton.bezelStyle = NSBezelStyleRounded;
    self.scanButton.keyEquivalent = @"";
    [root addSubview:self.scanButton];

    self.spinner = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(187, 376, 20, 20)];
    self.spinner.style = NSProgressIndicatorStyleSpinning;
    self.spinner.controlSize = NSControlSizeSmall;
    self.spinner.hidden = YES;
    [root addSubview:self.spinner];

    NSTextField *resultsTitle = [self label:@"Review results" size:16 weight:NSFontWeightSemibold];
    resultsTitle.frame = NSMakeRect(26, 330, 300, 25);
    [root addSubview:resultsTitle];

    NSScrollView *scroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(26, 76, 708, 244)];
    scroll.hasVerticalScroller = YES;
    scroll.autohidesScrollers = YES;
    scroll.borderType = NSBezelBorder;
    self.resultsView = [[NSTextView alloc] initWithFrame:scroll.bounds];
    self.resultsView.editable = NO;
    self.resultsView.selectable = YES;
    self.resultsView.font = [NSFont monospacedSystemFontOfSize:12 weight:NSFontWeightRegular];
    self.resultsView.string = @"No scan has been run yet. Select “Scan Downloads” to inspect common script files.";
    scroll.documentView = self.resultsView;
    [root addSubview:scroll];

    NSTextField *note = [self label:@"Protecter reports heuristic matches only. It does not delete or modify files, and it is not a full antivirus." size:11 weight:NSFontWeightRegular];
    note.textColor = NSColor.secondaryLabelColor;
    note.frame = NSMakeRect(26, 24, 708, 36);
    note.maximumNumberOfLines = 2;
    [root addSubview:note];

    [self.window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
}

- (NSTextField *)label:(NSString *)text size:(CGFloat)size weight:(NSFontWeight)weight {
    NSTextField *field = [NSTextField labelWithString:text];
    field.font = [NSFont systemFontOfSize:size weight:weight];
    return field;
}

- (void)startScan:(id)sender {
    self.scanButton.enabled = NO;
    self.spinner.hidden = NO;
    [self.spinner startAnimation:nil];
    self.statusLabel.stringValue = @"Scanning Downloads…";
    self.countLabel.stringValue = @"Checking files…";
    self.resultsView.string = @"Scanning local files. This window will update when finished.";

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSURL *downloads = [[NSFileManager defaultManager].homeDirectoryForCurrentUser
            URLByAppendingPathComponent:@"Downloads" isDirectory:YES];
        NSArray<NSURLResourceKey> *keys = @[
            NSURLIsRegularFileKey, NSURLIsDirectoryKey, NSURLIsSymbolicLinkKey, NSURLFileSizeKey
        ];
        NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager]
            enumeratorAtURL:downloads
            includingPropertiesForKeys:keys
            options:(NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants)
            errorHandler:^BOOL(NSURL *url, NSError *error) { return YES; }];

        NSArray<NSString *> *extensions = @[@"sh", @"command", @"py", @"js", @"jsx", @"applescript", @"scpt"];
        NSArray<NSString *> *patterns = @[
            @"curl.{0,160}\\|\\s*(bash|sh)",
            @"base64\\s+(-d|--decode)",
            @"osascript\\s+-e",
            @"launchctl\\s+(load|bootstrap|enable)",
            @"security\\s+find-(generic|internet)-password"
        ];
        NSMutableArray<NSRegularExpression *> *regexes = [NSMutableArray array];
        for (NSString *pattern in patterns) {
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                options:NSRegularExpressionCaseInsensitive error:nil];
            if (regex) [regexes addObject:regex];
        }

        NSUInteger checked = 0;
        NSMutableArray<NSString *> *findings = [NSMutableArray array];
        for (NSURL *url in enumerator) {
            @autoreleasepool {
                NSNumber *regular = nil, *symbolic = nil, *size = nil;
                [url getResourceValue:&regular forKey:NSURLIsRegularFileKey error:nil];
                [url getResourceValue:&symbolic forKey:NSURLIsSymbolicLinkKey error:nil];
                if (symbolic.boolValue || !regular.boolValue) continue;
                checked++;

                if (![extensions containsObject:url.pathExtension.lowercaseString]) continue;
                [url getResourceValue:&size forKey:NSURLFileSizeKey error:nil];
                if (size.unsignedLongLongValue > 2 * 1024 * 1024) continue;

                NSError *readError = nil;
                NSString *contents = [NSString stringWithContentsOfURL:url
                    encoding:NSUTF8StringEncoding error:&readError];
                if (!contents || readError) continue;

                NSUInteger matches = 0;
                NSMutableArray<NSString *> *names = [NSMutableArray array];
                NSArray<NSString *> *descriptions = @[
                    @"Encoded shell pipeline", @"Base64 decoding command",
                    @"Script execution command", @"Persistence-related command",
                    @"Credential lookup command"
                ];
                for (NSUInteger i = 0; i < regexes.count; i++) {
                    NSUInteger found = [regexes[i] numberOfMatchesInString:contents
                        options:0 range:NSMakeRange(0, contents.length)];
                    if (found > 0) {
                        matches++;
                        [names addObject:descriptions[i]];
                    }
                }
                if (matches >= 2) {
                    [findings addObject:[NSString stringWithFormat:
                        @"%@\n  %@\n  %@\n", url.lastPathComponent,
                        [names componentsJoinedByString:@", "], url.path]];
                }
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            self.spinner.hidden = YES;
            [self.spinner stopAnimation:nil];
            self.scanButton.enabled = YES;
            self.countLabel.stringValue = [NSString stringWithFormat:
                @"Files checked: %lu     Items to review: %lu",
                (unsigned long)checked, (unsigned long)findings.count];
            if (findings.count == 0) {
                self.statusLabel.stringValue = @"Scan complete. No heuristic matches found.";
                self.resultsView.string = @"No files matched Protecter’s current heuristic rules.\n\nThis does not prove that every file is safe.";
            } else {
                self.statusLabel.stringValue = @"Scan complete. Review the flagged items below.";
                self.resultsView.string = [findings componentsJoinedByString:@"\n"];
            }
        });
    });
}

@end

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSApplication *application = [NSApplication sharedApplication];
        ProtecterAppDelegate *delegate = [[ProtecterAppDelegate alloc] init];
        application.delegate = delegate;
        [application setActivationPolicy:NSApplicationActivationPolicyRegular];
        [application run];
    }
    return 0;
}
