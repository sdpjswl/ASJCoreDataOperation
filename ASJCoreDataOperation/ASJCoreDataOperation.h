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
@import CoreData;

NS_ASSUME_NONNULL_BEGIN

@interface ASJCoreDataOperation : NSOperation

/**
 *  The private managed object context, either the one passed during initialization OR created internally. You can use it with a NSFetchedResultsController to do asynchronous fetches.
 */
@property (readonly, strong, nonatomic) NSManagedObjectContext *privateMoc;

/**
 *  The designated initializer. If you create an instance using 'init', a managed object context on a private queue will be created for you and it will attempt to access the main queue managed object context from the project's AppDelegate.m.
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

@end

NS_ASSUME_NONNULL_END