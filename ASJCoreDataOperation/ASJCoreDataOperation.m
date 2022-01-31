//
// ASJCoreDataOperation.m
//
// Copyright (c) 2016 Sudeep Jaiswal
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "ASJCoreDataOperation.h"
#import <UIKit/UIApplication.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSPersistentContainer.h>

@interface ASJCoreDataOperation ()

@property (strong, nonatomic) NSManagedObjectContext *privateMoc;
@property (strong, nonatomic) NSManagedObjectContext *mainMoc;
@property (readonly, weak, nonatomic) NSManagedObjectContext *appDelegateMoc;
@property (readonly, weak, nonatomic) NSNotificationCenter *notificationCenter;

- (void)setup;
- (void)setupMocs;
- (void)listenForMocSavedNotification;

@end

@implementation ASJCoreDataOperation

- (instancetype)init
{
    return [self initWithPrivateMoc:nil mainMoc:nil];
}

- (instancetype)initWithPrivateMoc:(NSManagedObjectContext *)privateMoc mainMoc:(NSManagedObjectContext *)mainMoc
{
    self = [super init];
    if (self)
    {
        _privateMoc = privateMoc;
        _mainMoc = mainMoc;
        [self setup];
    }
    return self;
}

#pragma mark - Setup

- (void)setup
{
    [self setupMocs];
    [self listenForMocSavedNotification];
}

- (void)setupMocs
{
    // fallback to app delegate's moc if user has not provided one
    if (!_mainMoc) {
        _mainMoc = self.appDelegateMoc;
    }
    
    // create a new private moc on private queue if user has not provided one
    if (!_privateMoc)
    {
        _privateMoc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        _privateMoc.persistentStoreCoordinator = _mainMoc.persistentStoreCoordinator;
    }
    
    // must provide this to resolve any conflicts while merging
    _privateMoc.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
    _privateMoc.undoManager = nil;
}

- (NSManagedObjectContext *)appDelegateMoc
{
    __block id<UIApplicationDelegate> appDelegate = nil;
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        appDelegate = [UIApplication sharedApplication].delegate;
    });
    
    SEL managedObjectContext = NSSelectorFromString(@"managedObjectContext");
    if ([appDelegate respondsToSelector:managedObjectContext])
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        return [appDelegate performSelector:managedObjectContext];
#pragma clang diagnostic pop
    }
    
    SEL persistentContainer = NSSelectorFromString(@"persistentContainer");
    if ([appDelegate respondsToSelector:persistentContainer])
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        NSPersistentContainer *container = [appDelegate performSelector:persistentContainer];
        return container.viewContext;
#pragma clang diagnostic pop
    }
    
    NSAssert(NO, @"Error: No 'managedObjectContext' found that operates on the main queue.\nSolution: Make sure that a 'managedObjectContext' or 'persistentContainer' is present in AppDelegate or pass a 'managedObjectContext' while initializing the operation.");
    
    return nil;
}

#pragma mark - Notifications

- (void)listenForMocSavedNotification
{
    [self.notificationCenter addObserver:self selector:@selector(contextDidSave:) name:NSManagedObjectContextDidSaveNotification object:_privateMoc];
}

- (void)contextDidSave:(NSNotification *)note
{
    if ([note.object isEqual:_mainMoc]) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [_mainMoc performBlock:^
     {
        [weakSelf.mainMoc mergeChangesFromContextDidSaveNotification:note];
        
        // saving is complete here
        if (weakSelf.saveBlock) {
            weakSelf.saveBlock();
        }
    }];
}

- (void)dealloc
{
    [self.notificationCenter removeObserver:self];
}

- (NSNotificationCenter *)notificationCenter
{
    return [NSNotificationCenter defaultCenter];
}

#pragma mark - Overrides

- (void)main
{
    [_privateMoc performBlockAndWait:^{
        [self coreDataOperation];
    }];
}

- (void)coreDataOperation
{
    NSAssert(NO, @"Method must be overridden in subclass: %s", __PRETTY_FUNCTION__);
}

@end
