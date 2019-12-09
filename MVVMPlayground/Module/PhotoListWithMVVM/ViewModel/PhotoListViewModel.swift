//
//  PhotoListViewModel.swift
//  MVVMPlayground
//
//  Created by Neo on 03/10/2017.
//  Copyright © 2017 ST.Huang. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class PhotoListViewModel {
    
    let apiService: APIServiceProtocol

    private var photos: [Photo] = [Photo]()
    
    // Rx:
    let cellViewModels: PublishSubject<[PhotoListCellViewModel]> = PublishSubject()
    let state: PublishSubject<State> = PublishSubject()
    let alertMessage: PublishSubject<String> = PublishSubject()

    var isAllowSegue: PublishSubject<Bool> = PublishSubject()
    
    var selectedPhoto: Photo?

    var reloadTableViewClosure: (()->())?
    var showAlertClosure: (()->())?
    var updateLoadingStatus: (()->())?

    init( apiService: APIServiceProtocol = APIService()) {
        self.apiService = apiService
    }
    
    func initFetch() {
        state.onNext(.loading)
        apiService.fetchPopularPhoto { [weak self] (success, photos, error) in
            guard let self = self else {
                return
            }

            guard error == nil else {
                self.state.onNext(.error)
                self.alertMessage.onNext(error?.rawValue ?? "Error")
                return
            }

            self.processFetchedPhoto(photos: photos)
            self.state.onNext(.populated)
        }
    }
        
    func createCellViewModel( photo: Photo ) -> PhotoListCellViewModel {

        //Wrap a description
        var descTextContainer: [String] = [String]()
        if let camera = photo.camera {
            descTextContainer.append(camera)
        }
        if let description = photo.description {
            descTextContainer.append( description )
        }
        let desc = descTextContainer.joined(separator: " - ")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        return PhotoListCellViewModel( titleText: photo.name,
                                       descText: desc,
                                       imageUrl: photo.image_url,
                                       dateText: dateFormatter.string(from: photo.created_at) )
    }
    
    private func processFetchedPhoto( photos: [Photo] ) {
        self.photos = photos // Cache
        var vms = [PhotoListCellViewModel]()
        for photo in photos {
            vms.append( createCellViewModel(photo: photo) )
        }
        self.cellViewModels.onNext(vms)
    }
    
}

extension PhotoListViewModel {
    func userPressed( at indexPath: IndexPath ) {
        let photo = self.photos[indexPath.row]
        if photo.for_sale {
            self.selectedPhoto = photo
            self.isAllowSegue.onNext(true)
        }else {
            self.selectedPhoto = nil
            self.isAllowSegue.onNext(false)
            self.alertMessage.onNext("This item is not for sale")
        }
        
    }
}
