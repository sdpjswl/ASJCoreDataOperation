//
// ASJCoreDataOperation.h
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

@import Foundation;

@class NSManagedObjectContext;

NS_ASSUME_NONNULL_BEGIN

typedef void(^SaveBlock)(void);

@interface ASJCoreDataOperation : NSOperation

/**
 *  If you pass in your own managed object context during initialization, this property will hold it. If you don't, one will be created internally and will be available publicly with this property. You can use this managed object context property to create an NSFetchedResultsController and do asynchronous fetches. It is recommended that you do your fetches in the background and update UI on the main queue.
 */
@property (readonly, strong, nonatomic) NSManagedObjectContext *privateMoc;

/**
 *  A block you can listen to that is fired when a save operation is completed.
 */
@property (copy) SaveBlock saveBlock;

/**
 *  The designated initializer that requires you to pass two NSManagedObjectContexts; one created on a private queue, and one on the main queue. If you checked "Use Core Data" while creating your project, you will have a "managedObjectContext" property in AppDelegate.h. It is created on the main queue, and if you want, you can pass it but you don't need to. Both arguments here are optional and if the "mainMoc" is not specified, the library will attempt to access the one defined in the app delegate. However, things will not work if moc is not present in the app delegate. In that case, you must provide one yourself. Parallelly, you can provide a private moc or not. If you don't, one will be created and will be available as a public property, as shown above.
 *
 *  @param privateMoc You can pass a managed object context of your own with  "NSPrivateQueueConcurrencyType". You can tie it with a "NSFetchedResultsController" to do async fetches so that the main thread is not blocked. This parameter is optional, and if you don't provide a managed object context, one will be created internally.
 *  @param mainMoc You can pass a managed object context with "NSMainQueueConcurrencyType". If you have created your project with CoreData enabled, the default moc in AppDelegate.m is of this type. You can, if you wish pass it in this argument, but it you keep it nil, it will attempt to access the same from your AppDelegate.
 *
 *  @return An instance of ASJCoreDataOperation.
 */
- (instancetype)initWithPrivateMoc:(nullable NSManagedObjectContext *)privateMoc mainMoc:(nullable NSManagedObjectContext *)mainMoc NS_DESIGNATED_INITIALIZER;

/**
 *  Override this method in your ASJCoreDataOperation subclass and write your logic there. Any fetching/saving to core data must happen in this method. Whenever you want to access the managed object context, ALWAYS use the "privateMoc" property declared above.
 */
- (void)coreDataOperation;

/**
 *  The setter for the save block. You can listen to this block to get the save operation completiion event.
 *
 *  @param saveBlock The block that will be fired when a save operation is completed.
 */
- (void)setSaveBlock:(SaveBlock _Nonnull)saveBlock;

@end

NS_ASSUME_NONNULL_END
