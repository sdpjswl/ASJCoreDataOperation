//
//  ViewController.swift
//  CoreDataOperation
//
//  Created by sudeep on 22/05/16.
//  Copyright © 2016 sudeep. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController
{
    @IBOutlet var photosTableView: UITableView!
    let operationQueue = OperationQueue()
    
    let photosUrl = "http://jsonplaceholder.typicode.com/photos"
    let cellIdentifier = "cell"
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        setup()
    }
    
    // MARK: - Setup
    
    func setup()
    {
        photosTableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        
        let leftView = UIBarButtonItem(customView: activityIndicator)
        navigationItem.leftBarButtonItem = leftView
    }
    
    lazy var activityIndicator: UIActivityIndicatorView =
    {
        var indicator = UIActivityIndicatorView(style: .gray)
        indicator.hidesWhenStopped = true
        indicator.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        return indicator
    }()
    
    // MARK: - IBAction
    
    @IBAction func downloadTapped(_ sender: Any)
    {
        shouldShowIndicator = true
        downloadPhotos()
    }
    
    var shouldShowIndicator: Bool = false
    {
        didSet
        {
            DispatchQueue.main.async {
                
                self.navigationItem.rightBarButtonItem?.isEnabled =  !self.shouldShowIndicator
                
                if self.shouldShowIndicator {
                    self.activityIndicator.startAnimating()
                }
                else {
                    self.activityIndicator.stopAnimating()
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    func downloadPhotos()
    {
        let operation = BlockOperation { () -> Void in
            
            let url = URL(string: self.photosUrl)
            URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, error) -> Void in
                
                if let jsonData = data {
                    do {
                        var photos = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as! [[String: AnyObject]]
                        
                        // limit to 500
                        photos = Array(photos[0...499])
                        
                        // save
                        self.savePhotosToCoreData(photos: photos)
                    }
                    catch let error as NSError {
                        print("error parsing response to json: \(error.localizedDescription)")
                    }
                }
                else if let error = error {
                    print("error downloading photos: \(error.localizedDescription)")
                }
                
            }).resume()
        }
        
        operationQueue.addOperation(operation)
    }
    
    func savePhotosToCoreData(photos: [[String: AnyObject]])
    {
        let operation = SavePhotosOperation(privateMoc: photosPrivateMoc, mainMoc: nil)
        operation.photos = photos
        operationQueue.addOperation(operation)
        
        operation.saveBlock =
        {
            // saved
        }
        
        operation.completionBlock =
        {
            // hide indicator
            self.shouldShowIndicator = false
        }
    }
    
    // MARK: - Getters
    
    lazy var photosPrivateMoc: NSManagedObjectContext =
    {
        var privateMoc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        privateMoc.persistentStoreCoordinator = appDelegate.persistentStoreCoordinator
        
        return privateMoc
    }()
    
    lazy var fetchedResultsController: NSFetchedResultsController<Photo> =
    {
        let fetchRequest = NSFetchRequest<Photo>(entityName: "Photo")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "photoId", ascending: false)]
        
        let frc: NSFetchedResultsController<Photo> = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.photosPrivateMoc, sectionNameKeyPath: nil, cacheName: nil)
        frc.delegate = self
        
        do {
            try frc.performFetch()
        }
        catch let error as NSError {
            print("error performing fetch: \(error.localizedDescription)")
        }
        
        return frc
    }()
}

// MARK: - UITableViewDataSource

extension ViewController: UITableViewDataSource
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        let sectionInfo: NSFetchedResultsSectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        
        let photo: Photo = fetchedResultsController.object(at: indexPath)
        cell.textLabel?.text = "\(photo.photoId!) - \(photo.title!)"
        
        return cell
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension ViewController: NSFetchedResultsControllerDelegate
{
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>)
    {
        OperationQueue.main.addOperation { () -> Void in
            self.photosTableView.reloadData()
        }
    }
}
