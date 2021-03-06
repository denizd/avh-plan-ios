//
//  FirstViewController.swift
//  AvH Plan
//
//  Created by Deniz Duezgoeren on 25.05.19.
//  Copyright © 2019 Deniz Duezgoeren. All rights reserved.
//

import UIKit
import MagazineLayout
import Crashlytics
import Firebase

class PlanViewController : UICollectionViewController, UICollectionViewDelegateMagazineLayout, UITabBarControllerDelegate {
    
    let identifier = "plan_cell"
    var substs = [SubstModel]()
    let refreshControl = UIRefreshControl()
    let df = DataFetcher.sharedInstance
    let layout = MagazineLayout()
    var url = ""
    var indexOfPSA: Int? = nil
    let cancellations = ["eigenverantwortliches arbeiten", "entfall", "entfällt", "fällt aus", "freisetzung", "vtr. ohne lehrer"]
    let prefs = UserDefaults.standard
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        if !self.prefs.bool(forKey: "logged_in") {
            if let s = storyboard?.instantiateViewController(withIdentifier: "Login") as? UINavigationController {
                s.modalPresentationStyle = .fullScreen
                self.present(s, animated: true)
            }
        } else if !self.prefs.bool(forKey: "setup_finished") {
            if let s = storyboard?.instantiateViewController(withIdentifier: "FirstTime") as? UINavigationController {
                s.modalPresentationStyle = .fullScreen
                self.present(s, animated: true)
            }
        }
        
        super.viewWillAppear(animated)
        
        if self.prefs.bool(forKey: "logged_in") {
            Messaging.messaging().subscribe(toTopic: "substitutions-ios")
            Messaging.messaging().subscribe(toTopic: "substitutions-broadcast")
            
            if self.prefs.bool(forKey: "subscribed_to_dev_channel") {
                Messaging.messaging().subscribe(toTopic: "substitutions-debug")
            } else {
                Messaging.messaging().unsubscribe(fromTopic: "substitutions-debug")
            }
        }
        
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = true
        
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.superview!.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.superview!.bottomAnchor),
            ])
        collectionView.register(UINib(nibName: "PlanViewCell", bundle: nil), forCellWithReuseIdentifier: identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = UIColor(named: "colorBackground")!
        
        if #available(iOS 10.0, *) {
            collectionView.refreshControl = refreshControl
        } else {
            collectionView.addSubview(refreshControl)
        }
        refreshControl.addTarget(self, action: #selector(objDoAsync(_:)), for: .valueChanged)
        refreshControl.tintColor = #colorLiteral(red: 0.07843137255, green: 0.5568627451, blue: 1, alpha: 1)
        refreshControl.attributedTitle = NSAttributedString(string: getRefreshViewString())
        self.tabBarController?.delegate = self
        
        self.substs = self.getFromDatabase()
        self.collectionView.reloadData()
        
        if self.df.shouldRefresh || (self.prefs.bool(forKey: "setup_finished") && !self.prefs.bool(forKey: "first_refresh")) {
            self.collectionView.setContentOffset(CGPoint(x: 0, y: -self.refreshControl.frame.size.height), animated: true)
            self.refreshControl.beginRefreshing()
            self.refreshControl.sendActions(for: .valueChanged)
            self.df.shouldRefresh = false
            self.prefs.set(true, forKey: "first_refresh")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView.contentInsetAdjustmentBehavior = .always
        self.df.setTabBarBadge(for: self.tabBarController?.tabBar.items)
        self.collectionView.isPrefetchingEnabled = false
    }
    
    func getViewType() -> String {
        return "plan"
    }
    
    func getFromDatabase() -> [SubstModel] {
        return self.df.getSubstitutionsFromDatabase()
    }
    
    func getRefreshViewString() -> String {
        return NSLocalizedString("fetch_plan", comment: "")
    }
    
    func getIndex() -> Int {
        return 0
    }
    
    @objc private func objDoAsync(_ sender: Any) {
        self.df.doAsync(do: self.getViewType()) {
            DispatchQueue.main.async {
                self.substs = self.getFromDatabase()
    //            UIView.performWithoutAnimation {
                    self.collectionView.reloadData()
    //            }
                self.refreshControl.endRefreshing()
                self.df.setTabBarBadge(for: self.tabBarController?.tabBar.items)
            }
        }
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if let alert = self.df.presentInformationAlert(for: tabBarController, at: self.getIndex()) {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.substs.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexOfPSA == indexPath.item {
            UIApplication.shared.open(URL(string: url)!)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath as IndexPath) as! PlanViewCell
        
        let course = self.substs[indexPath.item].course
        var image = df.getImage(from: course)
        
        let layer = cell.tintView.layer
        df.setCardFormatting(for: layer)
        cell.tintView.backgroundColor = self.df.getColour(for: course)
        
        let dateString = self.substs[indexPath.item].date
        if dateString.count > 2 && dateString[dateString.startIndex...dateString.index(dateString.startIndex, offsetBy: 2)] == "psa" {
            cell.date.text = ""
            if dateString.count > 9 && dateString[dateString.index(dateString.startIndex, offsetBy: 3)...dateString.index(dateString.startIndex, offsetBy: 6)] == "http" {
                url = "\(dateString[dateString.index(dateString.startIndex, offsetBy: 3)...])"
                indexOfPSA = indexPath.item
            }
            image = UIImage(named: "ic_idea_psa_white")
            cell.tintView.backgroundColor = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
            cell.course.textColor = UIColor(named: "colorBackground")!
        } else {
            cell.date.text = self.substs[indexPath.item].date
        }
        
        let mutableStrings = [
            NSMutableAttributedString(string: self.substs[indexPath.item].group),
            NSMutableAttributedString(string: self.substs[indexPath.item].time),
            NSMutableAttributedString(string: self.substs[indexPath.item].course),
            NSMutableAttributedString(string: self.substs[indexPath.item].room),
            NSMutableAttributedString(string: self.substs[indexPath.item].teacher)
        ]
        let strings = [
            self.substs[indexPath.item].group,
            self.substs[indexPath.item].time,
            self.substs[indexPath.item].course,
            self.substs[indexPath.item].room,
            self.substs[indexPath.item].teacher
        ]
        
        for i in 0...4 {
            if let qmark = strings[i].firstIndex(of: "?") {
                let distance = strings[i].distance(from: strings[i].startIndex, to: qmark)
                mutableStrings[i].addAttribute(NSAttributedString.Key.strikethroughStyle, value: 2, range: NSMakeRange(0, distance))
            }
        }
        
        let add = self.substs[indexPath.item].additional.lowercased()
        let type = self.substs[indexPath.item].type.lowercased()
        if add.contains("eigenverantwortliches arbeiten") || add.contains("entfall") || add.contains("fällt aus"){
            
        }
        
        if !add.isEmpty {
            if check(string: add, for: cancellations) {
                for i in 2...4 {
                    mutableStrings[i].addAttribute(NSAttributedString.Key.strikethroughStyle, value: 2, range: NSMakeRange(0, mutableStrings[i].length))
                }
            }
        } else {
            if check(string: type, for: cancellations) {
                for i in 2...4 {
                    mutableStrings[i].addAttribute(NSAttributedString.Key.strikethroughStyle, value: 2, range: NSMakeRange(0, mutableStrings[i].length))
                }
            }
        }
        
        cell.group.attributedText = mutableStrings[0]
        if self.substs[indexPath.item].additional.isEmpty {
            cell.additional.text = self.substs[indexPath.item].type
        } else {
            cell.additional.text = self.substs[indexPath.item].additional
        }
        cell.time.attributedText = mutableStrings[1]
        cell.room.attributedText = mutableStrings[3]
        
        var courseText = NSMutableAttributedString(string: "")
        if image != nil {
            let attachment: NSTextAttachment = NSTextAttachment()
            if indexOfPSA == indexPath.item {
                attachment.bounds = CGRect(x: 0, y: -3, width: 14, height: 20)
            } else {
                attachment.bounds = CGRect(x: 0, y: -3, width: 20, height: 20)
            }
            attachment.image = image
            
            let courseImage = NSMutableAttributedString(string: "")
            courseImage.append(NSAttributedString(attachment: attachment))
            courseImage.append(NSAttributedString(string: " "))
            let courseString = mutableStrings[2]
            courseImage.append(courseString)
            
            courseText = courseImage
        } else {
            courseText = mutableStrings[2]
        }
        if !courseText.isEqual(to: NSAttributedString(string: "")) && !substs[indexPath.item].teacher.isEmpty {
            courseText.append(NSAttributedString(string: " • "))
            courseText.append(mutableStrings[4])
        } else if courseText.isEqual(to: NSAttributedString(string: "")) && !substs[indexPath.item].teacher.isEmpty {
            courseText.append(mutableStrings[4])
        }
        cell.course.attributedText = courseText
        
        return cell
    }
    
    private func check(string s: String, for array: [String]) -> Bool {
        var b = false
        array.forEach { string in
            if s.contains(string) {
                b = true
            }
        }
        return b
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeModeForItemAt indexPath: IndexPath) -> MagazineLayoutItemSizeMode {
        var widthMode: MagazineLayoutItemWidthMode
        if UIDevice.current.userInterfaceIdiom == .pad { // iPad
            if UIDevice.current.orientation.isLandscape {
                widthMode = MagazineLayoutItemWidthMode.thirdWidth
            } else {
                widthMode = MagazineLayoutItemWidthMode.halfWidth
            }
        } else { // iPhone
            if UIDevice.current.orientation.isLandscape {
                widthMode = MagazineLayoutItemWidthMode.halfWidth
            } else {
                widthMode = MagazineLayoutItemWidthMode.fullWidth(respectsHorizontalInsets: true)
            }
        }
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
        return 0 // change this if needed
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetsForSectionAtIndex index: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetsForItemsInSectionAtIndex index: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
}

