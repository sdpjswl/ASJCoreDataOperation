//
//  SavePhotosOperation.swift
//  CoreDataOperation
//
//  Created by sudeep on 23/05/16.
//  Copyright © 2016 sudeep. All rights reserved.
//

import UIKit
import ASJCoreDataOperation_Swift
import CoreData

public class SavePhotosOperation: ASJCoreDataOperation
{
    public var photos: [[String: AnyObject]] = []
    
    override public func coreDataOperation()
    {
        for photoInfo in photos
        {
            let fetchRequest = NSFetchRequest<Photo>(entityName: "Photo")
            fetchRequest.fetchLimit = 1
            
            if let photoId = photoInfo["id"] as? NSNumber
            {
                let predicate = NSPredicate(format: "photoId == %@", photoId)
                fetchRequest.predicate = predicate
            }
            
            do
            {
                let result = try privateMoc.fetch(fetchRequest) as [Photo]
                if result.count > 0 {
                    continue
                }
            }
            catch let error as NSError {
                print("error fetching existing photos: \(error.localizedDescription)")
            }
            
            let photoManagedObject = NSEntityDescription.insertNewObject(forEntityName: "Photo", into: privateMoc) as! Photo
            
            photoManagedObject.albumId = photoInfo["albumId"] as? NSNumber
            photoManagedObject.photoId = photoInfo["id"] as? NSNumber
            photoManagedObject.title = photoInfo["title"] as? String
            photoManagedObject.url = photoInfo["url"] as? String
            photoManagedObject.thumbnailUrl = photoInfo["thumbnailUrl"] as? String
            
            do {
                try privateMoc.save()
            }
            catch let error as NSError {
                print("error saving photo: \(error.localizedDescription)")
            }
        }
        
    }
}
