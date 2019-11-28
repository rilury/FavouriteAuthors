//
//  Author+CoreDataProperties.swift
//  FavouriteAuthors
//
//  Created by Iordan, Raluca on 28/11/2019.
//  Copyright © 2019 Iordan, Raluca. All rights reserved.
//
//

import Foundation
import CoreData


extension Author {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Author> {
        return NSFetchRequest<Author>(entityName: "Author")
    }

    @NSManaged public var url: URL?
    @NSManaged public var id: UUID?
    @NSManaged public var lastRead: Date?
    @NSManaged public var isTopFavourite: Bool
    @NSManaged public var name: String?
    @NSManaged public var searchKey: String?
    @NSManaged public var booksRead: Int32
    @NSManaged public var rating: Double
    @NSManaged public var photo: Data?

}
