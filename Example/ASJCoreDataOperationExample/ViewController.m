//
//  ViewController.m
//  ASJCoreDataOperationExample
//
//  Created by sudeep_MAC02 on 12/05/16.
//  Copyright © 2016 sudeep. All rights reserved.
//

#import "ViewController.h"
#import "Photo.h"
#import "AppDelegate.h"
#import "SavePhotosOperation.h"

@import CoreData;

static NSString *const kPhotosUrl = @"http://jsonplaceholder.typicode.com/photos";
static NSString *const kCellIdentifier = @"cell";

@interface ViewController () <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *photosTableView;

@property (assign, nonatomic) BOOL shouldShowIndicator;
@property (strong, nonatomic) NSOperationQueue *operationQueue;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *photosPrivateMoc;
@property (strong, nonatomic) UIActivityIndicatorView *indicator;

- (void)setup;
- (IBAction)downloadTapped:(id)sender;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setup];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Setup

- (void)setup
{
    _operationQueue = [[NSOperationQueue alloc] init];
    
    Class cellClass = [UITableViewCell class];
    [_photosTableView registerClass:cellClass forCellReuseIdentifier:kCellIdentifier];
    
    _indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    _indicator.transform = CGAffineTransformMakeScale(0.75f, 0.75f);
    
    UIBarButtonItem *leftView = [[UIBarButtonItem alloc] initWithCustomView:_indicator];
    self.navigationItem.leftBarButtonItem = leftView;
}

#pragma mark - IBAction

- (IBAction)downloadTapped:(id)sender
{
    self.shouldShowIndicator = YES;
    [self downloadPhotos];
}

- (void)downloadPhotos
{
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        
        NSURL *url = [NSURL URLWithString:kPhotosUrl];
        [[[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)
          {
            if (!data.length || error) {
                NSLog(@"error downloading photos: %@", error.localizedDescription);
                return;
            }
            
            NSError *parseError = nil;
            NSArray *photos = (NSArray *)[NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
            if (!photos.count || parseError) {
                NSLog(@"error parsing response to json: %@", parseError.localizedDescription);
                return;
            }
            
            // save
            [self savePhotosToCoreData:photos];
            
        }] resume];
    }];
    
    [_operationQueue addOperation:operation];
}

- (void)setShouldShowIndicator:(BOOL)shouldShowIndicator
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        weakSelf.shouldShowIndicator = shouldShowIndicator;
        self.navigationItem.rightBarButtonItem.enabled = !shouldShowIndicator;
        
        if (shouldShowIndicator) {
            [weakSelf.indicator startAnimating];
        }
        else
        {
            [weakSelf.indicator stopAnimating];
            [weakSelf.indicator removeFromSuperview];
        }
    });
}

#pragma mark - Saving

- (void)savePhotosToCoreData:(NSArray *)photos
{
    SavePhotosOperation *operation = [[SavePhotosOperation alloc] initWithPrivateMoc:self.photosPrivateMoc mainMoc:nil];
    operation.photos = photos;
    [_operationQueue addOperation:operation];
    
    [operation setSaveBlock:^
     {
        // hide indicator
        self.shouldShowIndicator = NO;
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id<NSFetchedResultsSectionInfo> sectionInfo = self.fetchedResultsController.sections[section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Photo *photoManagedObject = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@", photoManagedObject.photoId.stringValue, photoManagedObject.title];
}

#pragma mark - NSFetchedResultsController

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController) {
        return _fetchedResultsController;
    }
    
    @synchronized(self)
    {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Photo"];
        fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"photoId" ascending:NO]];
        
        _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.photosPrivateMoc sectionNameKeyPath:nil cacheName:nil];
        _fetchedResultsController.delegate = self;
        
        NSError *error = nil;
        BOOL success = [_fetchedResultsController performFetch:&error];
        if (!success || error) {
            NSLog(@"error performing fetch: %@", error.localizedDescription);
            return nil;
        }
        
        return _fetchedResultsController;
    }
}

- (NSManagedObjectContext *)photosPrivateMoc
{
    if (_photosPrivateMoc) {
        return _photosPrivateMoc;
    }
    
    @synchronized(self)
    {
        _photosPrivateMoc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        
        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        _photosPrivateMoc.persistentStoreCoordinator = appDelegate.persistentStoreCoordinator;
        
        return _photosPrivateMoc;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    __weak typeof(self) weakSelf = self;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [weakSelf.photosTableView reloadData];
    }];
}

@end
