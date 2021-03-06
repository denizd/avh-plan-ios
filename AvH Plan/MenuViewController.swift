//
//  MenuViewController.swift
//  AvH Plan
//
//  Created by Deniz Duezgoeren on 11.07.19.
//  Copyright © 2019 Deniz Duezgoeren. All rights reserved.
//

import UIKit
import MagazineLayout

class MenuViewController : UICollectionViewController, UICollectionViewDelegateMagazineLayout, UITabBarControllerDelegate {
    
    var items = [String]()
    private let refreshControl = UIRefreshControl()
    let df = DataFetcher.sharedInstance
    let layout = MagazineLayout()
    let identifier = "menu_cell"
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    }
    
    override func loadView() {
        super.loadView()
        self.collectionView.isPrefetchingEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = true
        
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.superview!.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        collectionView.register(UINib(nibName: "MenuViewCell", bundle: nil), forCellWithReuseIdentifier: identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = UIColor(named: "colorBackground")
        
        if #available(iOS 10.0, *) {
            collectionView.refreshControl = refreshControl
        } else {
            collectionView.addSubview(refreshControl)
        }
        refreshControl.addTarget(self, action: #selector(objDoAsync(_:)), for: .valueChanged)
        refreshControl.tintColor = #colorLiteral(red: 0.07843137255, green: 0.5568627451, blue: 1, alpha: 1)
        refreshControl.attributedTitle = NSAttributedString(string: NSLocalizedString("fetch_menu", comment: ""))
        self.tabBarController?.delegate = self
        
        self.items = self.df.readMenu()
        self.collectionView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.extendedLayoutIncludesOpaqueBars = true
        self.collectionView.contentInsetAdjustmentBehavior = .always
        self.navigationController?.navigationBar.topItem?.title = NSLocalizedString("food_menu", comment: "")
    }
    
    @objc private func objDoAsync(_ sender: Any) {
        df.doAsync(do: "menu") {
            DispatchQueue.main.async {
                self.items = self.df.readMenu()
//            UIView.performWithoutAnimation {
                self.collectionView.reloadData()
//            }
                
                self.refreshControl.endRefreshing()
                self.df.setTabBarBadge(for: self.tabBarController?.tabBar.items)
            }
        }
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if let alert = self.df.presentInformationAlert(for: tabBarController, at: 3) {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.items.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath as IndexPath) as! MenuViewCell
        
        cell.content.text = self.items[indexPath.item]
        cell.tintView.backgroundColor = UIColor(named: "colorDefault")
        let layer = cell.tintView.layer
        df.setCardFormatting(for: layer)
        return cell
    }
    
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
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetsForSectionAtIndex index: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetsForItemsInSectionAtIndex index: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
}

