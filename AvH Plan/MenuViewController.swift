//
//  MenuViewController.swift
//  AvH Plan
//
//  Created by Deniz Duezgoeren on 11.07.19.
//  Copyright © 2019 Deniz Duezgoeren. All rights reserved.
//

import UIKit
import MagazineLayout

class MenuViewController : UIViewController, UICollectionViewDataSource, UICollectionViewDelegateMagazineLayout {
    
    var items = [String]()
    private let refreshControl = UIRefreshControl()
    let df = DataFetcher()
    @IBOutlet weak var toolbar: UINavigationBar!
    let layout = MagazineLayout()
    var collectionView: UICollectionView
    let identifier = "menu_cell"
    
    required init?(coder decoder: NSCoder) {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(coder: decoder)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: self.toolbar.bottomAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        collectionView.register(UINib(nibName: "MenuViewCell", bundle: nil), forCellWithReuseIdentifier: identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        
        if #available(iOS 10.0, *) {
            collectionView.refreshControl = refreshControl
        } else {
            collectionView.addSubview(refreshControl) // likely unnecessary
        }
        refreshControl.addTarget(self, action: #selector(objDoAsync(_:)), for: .valueChanged)
        refreshControl.tintColor = UIColor(red: 0.39, green: 0.71, blue: 0.96, alpha: 1.0)
        refreshControl.attributedTitle = NSAttributedString(string: "Fetching the food menu...")
    }
    
    @objc private func objDoAsync(_ sender: Any) {
        df.doAsync(do: "menu") { menuItems in
            self.items = menuItems as! [String]
            self.collectionView.reloadData()
            self.refreshControl.endRefreshing()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.backgroundColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)
        
        self.items = self.df.readMenu()
        self.collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath as IndexPath) as! MenuViewCell
        if self.items.count != 0 {
            cell.content.text = self.items[indexPath.item]
        }

        cell.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("You selected cell#\(indexPath.item)!")
    }
    
    // generated stubs filled with return values
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeModeForItemAt indexPath: IndexPath) -> MagazineLayoutItemSizeMode {
        let widthMode = MagazineLayoutItemWidthMode.fullWidth(respectsHorizontalInsets: true)
        let heightMode = MagazineLayoutItemHeightMode.dynamic
        return MagazineLayoutItemSizeMode(widthMode: widthMode, heightMode: heightMode)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, visibilityModeForHeaderInSectionAtIndex index: Int) -> MagazineLayoutHeaderVisibilityMode {
        return .hidden
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, visibilityModeForFooterInSectionAtIndex index: Int) -> MagazineLayoutFooterVisibilityMode {
        return .hidden
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, visibilityModeForBackgroundInSectionAtIndex index: Int) -> MagazineLayoutBackgroundVisibilityMode {
        return .hidden
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, horizontalSpacingForItemsInSectionAtIndex index: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, verticalSpacingForElementsInSectionAtIndex index: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetsForSectionAtIndex index: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetsForItemsInSectionAtIndex index: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
}
