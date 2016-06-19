# ASJCoreDataOperation

Adding concurrency/multi-threading to `CoreData` is not very straightforward and obvious. The main issue is with `NSManagedObjectContext`, which is thread unsafe. The default one created in `AppDelegate` is created on the main thread:

```objc
_managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
```

The main drawback of using `AppDelegate`'s managed object context is that whenever a save, fetch or delete operation is performed, the main thread/UI will get blocked. If you are doing small operations, this may not be noticeable. But for larger operations, it will pose a problem.

The solution is to do such `CoreData` operations in the background and only when you have to do any UI changes, say reloading a table, you call `reloadData` on the main queue.

# Installation

CocoaPods is the preferred way to install this library. Add this command to your `Podfile`:

```ruby
pod 'ASJCoreDataOperation'
```

For the same library in `Swift`, see [ASJCoreDataOperation-Swift](https://github.com/sudeepjaiswal/ASJCoreDataOperation-Swift).

# Background

* **Key:** `NSManagedObjectContext` = `moc`

### Concurrency options

There are three concurrency types defined in `NSManagedObjectContext.h`:
- `NSConfinementConcurrencyType` (which is marked `NS_ENUM_DEPRECATED`)
- `NSPrivateQueueConcurrencyType`
- `NSMainQueueConcurrencyType`

You should not use `NSConfinementConcurrencyType` anymore since it's obsolete and Apple doesn't recommend it. `NSPrivateQueueConcurrencyType` creates an `moc` on a background thread and `NSMainQueueConcurrencyType` creates one on the main queue. The one we are interested in is `NSPrivateQueueConcurrencyType`.

### Creating an `NSManagedObjectContext`

You can create as many `moc`s as you wish. During saving, it must go through an `NSPersistentStoreCoordinator` to write data to an sqlite file. You can use the one implemented in `AppDelegate` or provide your own. Just make sure that no matter what kind of store your app has; `NSSQLiteStoreType`, `NSXMLStoreType`, `NSBinaryStoreType` or `NSInMemoryStoreType`, the coordinator object must be tied to the same destination.

```objc
NSManagedObjectContext *privateMoc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
privateMoc.persistentStoreCoordinator = appDelegatesPersistentStoreCoordinator;
```

There are two methods for `moc`s, `performBlock:(void (^)())block` and `performBlockAndWait:(void (^)())block`. Any code written in those blocks is **guaranteed** to be executed on the same queue the `moc` is created. You **must** write your `CoreData` logic inside one of these methods. The difference between the two is that `performBlockAndWait:` will block the queue until it's operation is completed.

### Saving on a private queue

Whenever a `save` happens on a private `moc`, data will be written to the sqlite file but the main queue will not be notified about it. If you have an `NSFetchedResultsController` setup on the main queue, control will **not** reach its delegate methods. However, if the `CoreData` operation and `NSFetchedResultsController` share the same `moc`, it will work.

If you need the main queue to be notified about any changes made by a private context, you need to merge those changes from the private `moc` to the main `moc`. To do so, you have to start observing for `NSManagedObjectContextDidSaveNotification` on the private `moc`.

```objc
[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextDidSave:) name:NSManagedObjectContextDidSaveNotification object:privateMoc];
```

In `contextDidSave:` we need to merge the private `moc` changes into the main `moc`. You MUST use the `moc`'s `performBlock:` or `performBlockAndWait:` methods to ensure the merge happens on the correct thread.

```objc
- (void)contextDidSave:(NSNotification *)note
{
	[mainMoc performBlock:^{
		[mainMoc mergeChangesFromContextDidSaveNotification:note];
	}];
}
```

The `note` object has information of all modifications made to the managed objects. There can be issues however when merging data between two `moc`s and conflicts may arise. So, you must provide a `mergePolicy` so that `CoreData` knows how to resolve them.

```objc
privateMoc.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
```

* **Note:** There is another concurrency pattern, using child and parent `moc`s which has a simpler setup but it is not recommended because it blocks the main queue.

# What this library does

`ASJCoreDataOperation` is a subclass of `NSOperation` that provides private queue support out of the box. This class is designed to be subclassed and **will not** work without it.

```objc
- (instancetype)initWithPrivateMoc:(nullable NSManagedObjectContext *)privateMoc mainMoc:(nullable NSManagedObjectContext *)mainMoc NS_DESIGNATED_INITIALIZER;
```

This is the recommended way to create an instance of your subclass. You may pass `nil` in both arguments or use the `init` method. In those cases, a private moc will be created and `AppDelegate`'s `moc` will be accessed to be used as the `mainMoc`. If your `AppDelegate` does not have an `moc` object, you must provide one that is created on the main queue.

```objc
@property (readonly, strong, nonatomic) NSManagedObjectContext *privateMoc;
```

Irrespective of the way the private `moc` is created, it is publicly exposed and you may use it, say to tie an `NSFetchedResultsController` to it and do asynchronous fetches.

```objc 
- (void)coreDataOperation;
```

This is the method you are **required** to override in your subclass. Any `CoreData` operations you wish to perform should be written here. The library will ensure that this method is called on the correct thread.

### Usage

```objc
NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
SomeCoreDataOperationSubclass *operation = [[SomeCoreDataOperationSubclass alloc] initWithPrivateMoc:somePrivateMoc mainMoc:nil];
[operationQueue addOperation:operation];
```
As soon the `operation` is added to the `operationQueue`, it will start running on a background queue.

# Credits

- To [Shashank Pali](https://github.com/shashankpali) for fixing the UI issues in the example project.
- [Core Data Programming Guide - Concurrency](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/CoreData/Concurrency.html)
- [Core Data from Scratch: Concurrency](http://code.tutsplus.com/tutorials/core-data-from-scratch-concurrency--cms-22131)
- [A Networked Core Data Application](https://www.objc.io/issues/10-syncing-data/networked-core-data-application/)
- [Common Background Practices](https://www.objc.io/issues/2-concurrency/common-background-practices/)
- [Importing Large Data Sets](https://www.objc.io/issues/4-core-data/importing-large-data-sets-into-core-data/)

# To-do

- A completion block to know when operation is complete.
- A way to cancel operation midway.

# License

`ASJCoreDataOperation` is available under the MIT license. See the LICENSE file for more info.
