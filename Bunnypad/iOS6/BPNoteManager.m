//
//  BPNoteManager.m
//  BunnyPad iOS 6 Edition
//

#import "BPNoteManager.h"

@implementation BPNote
@end

@implementation BPNoteManager

+ (instancetype)sharedManager {
    static BPNoteManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[BPNoteManager alloc] init];
    });
    return manager;
}

- (NSString *)documentsDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths firstObject];
}

- (NSArray<BPNote *> *)allNotes {
    NSString *docsDir = [self documentsDirectory];
    NSError *error = nil;
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:docsDir error:&error];
    if (!files) return @[];

    NSMutableArray *notes = [NSMutableArray array];
    for (NSString *file in files) {
        if ([file hasSuffix:@".txt"]) {
            NSString *fullPath = [docsDir stringByAppendingPathComponent:file];
            NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:fullPath error:nil];
            NSString *content = [NSString stringWithContentsOfFile:fullPath encoding:NSUTF8StringEncoding error:nil];

            BPNote *note = [[BPNote alloc] init];
            note.filename = file;
            note.content = content ?: @"";
            note.modificationDate = [attrs fileModificationDate] ?: [NSDate date];
            [notes addObject:note];
        }
    }

    [notes sortUsingComparator:^NSComparisonResult(BPNote *obj1, BPNote *obj2) {
        return [obj2.modificationDate compare:obj1.modificationDate];
    }];

    return notes;
}

- (BPNote *)createNoteWithTitle:(NSString *)title content:(NSString *)content {
    NSString *safeTitle = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (safeTitle.length == 0) {
        safeTitle = @"Untitled Note";
    }

    NSString *filename = [NSString stringWithFormat:@"%@.txt", safeTitle];
    NSString *docsDir = [self documentsDirectory];
    NSString *fullPath = [docsDir stringByAppendingPathComponent:filename];

    int counter = 1;
    while ([[NSFileManager defaultManager] fileExistsAtPath:fullPath]) {
        filename = [NSString stringWithFormat:@"%@ %d.txt", safeTitle, counter++];
        fullPath = [docsDir stringByAppendingPathComponent:filename];
    }

    BPNote *note = [[BPNote alloc] init];
    note.filename = filename;
    note.content = content ?: @"";
    note.modificationDate = [NSDate date];

    [self saveNote:note error:nil];
    return note;
}

- (BPNote *)createQuickNote {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterShortStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    NSString *timeStr = [formatter stringFromDate:[NSDate date]];

    NSString *initialText = [NSString stringWithFormat:@"--- Quick Note (%@) ---\n\n", timeStr];
    NSString *title = [NSString stringWithFormat:@"Quick Note %@", [formatter stringFromDate:[NSDate date]]];
    title = [title stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
    title = [title stringByReplacingOccurrencesOfString:@":" withString:@"."];

    return [self createNoteWithTitle:title content:initialText];
}

- (BOOL)saveNote:(BPNote *)note error:(NSError **)error {
    if (!note || !note.filename) return NO;
    NSString *fullPath = [[self documentsDirectory] stringByAppendingPathComponent:note.filename];
    BOOL success = [note.content writeToFile:fullPath atomically:YES encoding:NSUTF8StringEncoding error:error];
    if (success) {
        note.modificationDate = [NSDate date];
    }
    return success;
}

- (BOOL)deleteNote:(BPNote *)note error:(NSError **)error {
    if (!note || !note.filename) return NO;
    NSString *fullPath = [[self documentsDirectory] stringByAppendingPathComponent:note.filename];
    return [[NSFileManager defaultManager] removeItemAtPath:fullPath error:error];
}

- (BPNote *)loadNoteWithFilename:(NSString *)filename {
    NSString *fullPath = [[self documentsDirectory] stringByAppendingPathComponent:filename];
    if (![[NSFileManager defaultManager] fileExistsAtPath:fullPath]) return nil;

    NSString *content = [NSString stringWithContentsOfFile:fullPath encoding:NSUTF8StringEncoding error:nil];
    NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:fullPath error:nil];

    BPNote *note = [[BPNote alloc] init];
    note.filename = filename;
    note.content = content ?: @"";
    note.modificationDate = [attrs fileModificationDate] ?: [NSDate date];
    return note;
}

@end
