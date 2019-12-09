//
//  PhotoListViewController.swift
//  MVVMPlayground
//
//  Created by Neo on 01/10/2017.
//  Copyright © 2017 ST.Huang. All rights reserved.
//

import UIKit
import SDWebImage
import RxSwift
import RxCocoa

class PhotoListViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    lazy var viewModel: PhotoListViewModel = {
        return PhotoListViewModel()
    }()
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        // Init the static view
        initView()
        
        // init view model
        initVM()
    
    }
    
    func initView() {
        self.navigationItem.title = "Popular"
    }
    
    func initVM() {
        
        // Rx:
        
        viewModel.alertMessage
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] message in
                self?.showAlert(message)
            } )
            .disposed(by: disposeBag)
        
        
        viewModel.state
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { state in
                switch state {
                case .loading:
                    self.activityIndicator.startAnimating()
                    UIView.animate(withDuration: 0.2, animations: {
                        self.tableView.alpha = 0.0
                    })
                case .error, .empty:
                    self.activityIndicator.stopAnimating()
                    UIView.animate(withDuration: 0.2, animations: {
                        self.tableView.alpha = 0.0
                    })
                case .populated:
                    self.activityIndicator.stopAnimating()
                    UIView.animate(withDuration: 0.2, animations: {
                        self.tableView.alpha = 1.0
                    })
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.isAllowSegue
            .observeOn(MainScheduler.instance)
            .filter { $0 == true }
            .subscribe(onNext: { [weak self] _ in
                if let photoDetailVC = self?.storyboard?.instantiateViewController(withIdentifier: "PhotoDetail") as? PhotoDetailViewController, let photo = self?.viewModel.selectedPhoto {
                    photoDetailVC.imageUrl = photo.image_url
                    self?.navigationController?.pushViewController(photoDetailVC, animated: true)
                }
            })
            .disposed(by: disposeBag)
        
        
        viewModel.cellViewModels
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] photoListViewModels in
                self?.tableView.reloadData()
            })
            .disposed(by: disposeBag)
        
        viewModel.cellViewModels.bind(to: tableView.rx.items(cellIdentifier: "photoCellIdentifier")) { (row, cellViewModel, cell: PhotoListTableViewCell) in
            cell.photoListCellViewModel = cellViewModel
        }.disposed(by: disposeBag)
        
        tableView.rx.itemSelected
        .subscribe(onNext: { [weak self] indexPath in
            self?.viewModel.userPressed(at: indexPath)
        }).disposed(by: disposeBag)
        
        
        viewModel.initFetch()

    }
    
    
    func showAlert( _ message: String ) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alert.addAction( UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}

