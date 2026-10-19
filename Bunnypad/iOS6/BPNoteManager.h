//
//  BPNoteManager.h
//  BunnyPad iOS 6 Edition
//

#import <Foundation/Foundation.h>

@interface BPNote : NSObject

@property (nonatomic, copy) NSString *filename;
@property (nonatomic, copy) NSString *content;
@property (nonatomic, strong) NSDate *modificationDate;

@end

@interface BPNoteManager : NSObject

+ (instancetype)sharedManager;

- (NSString *)documentsDirectory;
- (NSArray<BPNote *> *)allNotes;
- (BPNote *)createNoteWithTitle:(NSString *)title content:(NSString *)content;
- (BPNote *)createQuickNote;
- (BOOL)saveNote:(BPNote *)note error:(NSError **)error;
- (BOOL)deleteNote:(BPNote *)note error:(NSError **)error;
- (BPNote *)loadNoteWithFilename:(NSString *)filename;

@end
