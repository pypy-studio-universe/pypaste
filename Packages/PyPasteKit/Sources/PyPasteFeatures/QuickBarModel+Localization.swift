import PyPasteSharedUI

public extension QuickBarModel {
    var selectedCollectionName: String {
        guard let selectedCollectionID,
            let collection = collections.first(where: { $0.id == selectedCollectionID })
        else {
            return localization.text(.clipboard)
        }

        return collection.name
    }
}
