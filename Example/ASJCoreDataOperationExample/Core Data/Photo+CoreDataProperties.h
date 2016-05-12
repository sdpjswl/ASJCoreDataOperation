//
//  Photo+CoreDataProperties.h
//  ASJCoreDataOperationExample
//
//  Created by sudeep_MAC02 on 12/05/16.
//  Copyright © 2016 sudeep. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Photo.h"

NS_ASSUME_NONNULL_BEGIN

@interface Photo (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *albumId;
@property (nullable, nonatomic, retain) NSNumber *photoId;
@property (nullable, nonatomic, retain) NSString *thumbnailUrl;
@property (nullable, nonatomic, retain) NSString *title;
@property (nullable, nonatomic, retain) NSString *url;

@end

NS_ASSUME_NONNULL_END
