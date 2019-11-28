//
//  ViewController.swift
//  FavouriteAuthors
//
//  Created by Iordan, Raluca on 27/11/2019.
//  Copyright © 2019 Iordan, Raluca. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {
    
    //MARK: Outlets
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var booksReadLabel: UILabel!
    @IBOutlet weak var lastReadLabel: UILabel!
    @IBOutlet weak var favouriteLabel: UILabel!
    @IBOutlet weak var favouriteLabelCenterConstraint: NSLayoutConstraint!
    
    
    //MARK: Variables
    var managedObjectContext: NSManagedObjectContext!
    var selectedAuthor: Author!
    
    //MARK: Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIView.animate(withDuration: 1, animations: {
            let newConstraint = self.favouriteLabelCenterConstraint.constraintWithMultiplier(0.18)
            self.view.removeConstraint(self.favouriteLabelCenterConstraint)
            self.view.addConstraint(newConstraint)
            self.view.layoutIfNeeded()
            self.favouriteLabelCenterConstraint = newConstraint
        }, completion: nil)
        
        insertDataSamples()
        fetchData()
    }
    
    //MARK: CoreData
    func insertDataSamples() {
        
        let fetch: NSFetchRequest<Author> = Author.fetchRequest()
        fetch.predicate = NSPredicate(format: "searchKey != nil")
        
        let count = try! managedObjectContext.count(for: fetch)
        
        if count > 0 { //meaning that the data from plist is already stored
            return
        }
        
        let plistPath = Bundle.main.path(forResource: "SampleData", ofType: "plist")
        let dataArray = NSArray(contentsOfFile: plistPath!)!
        for dictionary in dataArray {
            let entity = NSEntityDescription.entity(
                forEntityName: "Author",
                in: managedObjectContext)!
            let author = Author(entity: entity,
                                insertInto: managedObjectContext)
            let authorDict = dictionary as! [String: Any]
            author.id = UUID(uuidString: authorDict["id"] as! String)
            author.name = authorDict["name"] as? String
            author.searchKey = authorDict["searchKey"] as? String
            author.rating = authorDict["rating"] as! Double
            
            let imageName = authorDict["imageName"] as? String
            let image = UIImage(named: imageName!)
            let photoData = image!.pngData()!
            author.photo = NSData(data: photoData) as Data
            author.lastRead = authorDict["lastRead"] as? Date
            let number = authorDict["booksRead"] as! NSNumber
            author.booksRead = number.int32Value
            author.isTopFavourite = authorDict["isTopFavourite"] as! Bool
            author.url = URL(string: authorDict["url"] as! String)
            
        }
        
        try! managedObjectContext.save()
    }
    
    func fetchData() {
        let request: NSFetchRequest<Author> = Author.fetchRequest()
        let firstTitle = segmentedControl.titleForSegment(at: 0)!
        request.predicate = NSPredicate(format: "%K = %@", argumentArray: [#keyPath(Author.searchKey), firstTitle])
        
        do {
            let results = try managedObjectContext.fetch(request)
            selectedAuthor = results.first
            setupUI(author: results.first!)
        } catch let error as NSError {
            print(error.debugDescription)
        }
    }
    
    func setupUI(author: Author) {
        guard let imageData = author.photo as Data?,
            let lastRead = author.lastRead as Date? else {
                return
        }
        
        imageView.image = UIImage(data: imageData)
        nameLabel.text = author.name
        ratingLabel.text = "Rating: \(author.rating)/5"
        booksReadLabel.text = "Books read: \(author.booksRead)"
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        lastReadLabel.text = "Last read: " + dateFormatter.string(from: lastRead)
        favouriteLabel.isHidden = !author.isTopFavourite
        
    }
    
    func update(rating: String?) {
        guard let ratingString = rating,
            let rating = Double(ratingString) else {
                return
        }
        do {
            selectedAuthor.rating = rating
            try managedObjectContext.save()
            setupUI(author: selectedAuthor)
        } catch let error as NSError {
            if error.domain == NSCocoaErrorDomain &&
                (error.code == NSValidationNumberTooLargeError ||
                    error.code == NSValidationNumberTooSmallError) {
                rate(selectedAuthor as Any)
            } else {
                print(error.description)
            }
        }
    }
    
    //MARK: Actions
    @IBAction func segmentedControl(_ sender: Any) {
        guard let segmentedControl = sender as? UISegmentedControl, let selectedSegment = segmentedControl.titleForSegment(at: segmentedControl.selectedSegmentIndex) else {
            return
        }
        
        let request: NSFetchRequest<Author> = Author.fetchRequest()
        request.predicate = NSPredicate(format: "%K = %@", argumentArray: [#keyPath(Author.searchKey), selectedSegment])

        do {
            let results = try managedObjectContext.fetch(request)
            selectedAuthor = results.first
            setupUI(author: selectedAuthor)
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    @IBAction func read(_ sender: Any) {
        let numberOfBooks = selectedAuthor.booksRead
        selectedAuthor.booksRead = numberOfBooks + 1
        selectedAuthor.lastRead = Date()
        
        do {
            try managedObjectContext.save()
            setupUI(author: selectedAuthor)
        } catch let error as NSError {
            print(error.description)
        }
    }
    
    @IBAction func rate(_ sender: Any) {
        let alert = UIAlertController(title: "New Rating",
                                      message: "Rate this author",
                                      preferredStyle: .alert)
        
        alert.view.tintColor = UIColor.hexStringToUIColor(hex: "B08317")
               alert.setValue(NSAttributedString(string: alert.title!, attributes: [NSAttributedString.Key.foregroundColor : UIColor.hexStringToUIColor(hex: "B08317")]), forKey: "attributedTitle")
               alert.setValue(NSAttributedString(string: alert.message!, attributes: [ NSAttributedString.Key.foregroundColor :  UIColor.hexStringToUIColor(hex: "B08317")]), forKey: "attributedMessage")

        alert.addTextField { (textField) in
            textField.keyboardType = .decimalPad
        }
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .cancel)
        let saveAction = UIAlertAction(title: "Save",
                                       style: .default) {
                                        [weak self] action in
                                        if let textField = alert.textFields?.first {
                                            self?.update(rating: textField.text)
                                        }
        }
        alert.addAction(cancelAction)
        alert.addAction(saveAction)
        present(alert, animated: true)
    }
}
