//
//  Luban.swift
//  XMImagePicker
//
//  Created by tiger on 2017/2/16.
//  Copyright © 2017年 xinma. All rights reserved.
//

import UIKit
import Foundation
protocol ConstraintHelperDelegate {
    func didChangeKeyboardAppearance(_ constraint :CGFloat?)
}

class ConstraintHelper {
    static let helper = ConstraintHelper()
    var constraint: NSLayoutConstraint?
    var adjusment: CGFloat = 0.0
    var isCenter: Bool = false
    var delegate :ConstraintHelperDelegate?
}

extension UIImage {    
    class func imageWithColor(_ color: UIColor, size: CGSize) -> UIImage {
        let rect: CGRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(rect)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
}

extension UIViewController {
    var swipeDismissGesture :UISwipeGestureRecognizer {
        get {
            return UISwipeGestureRecognizer(target: self, action: #selector(dismiss(fromGesture:)))
        }
    }
    
    @objc func dismiss(fromGesture gesture: UISwipeGestureRecognizer) {
        popMe()
    }
    
    func getCustomSwipeGesture(_ direction :UISwipeGestureRecognizerDirection) -> UISwipeGestureRecognizer {
        let gesture = UISwipeGestureRecognizer(target: self, action: #selector(dismiss(fromGesture:)))
        gesture.direction = direction
        return gesture
    }
    
    func addToolBar(_ textField :UITextField) {
        let numberToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 44))
        numberToolbar.barStyle = UIBarStyle.default
        let button = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.doneWithNumberPad))
        numberToolbar.items = [button]
        textField.inputAccessoryView = numberToolbar
        numberToolbar.barTintColor = UIColor.black
        numberToolbar.tintColor = UIColor.blue
    }
    
    @objc func doneWithNumberPad() {
        self.view.endEditing(true)
    }
    
    func displayContentController(_ content: UIViewController) {
        let window = UIApplication.shared.keyWindow!.rootViewController!
        window.addChildViewController(content)
        content.view.alpha = 0.0
        content.view.frame = CGRect(x: 0, y: 0, width: window.view.frame.width, height: window.view.frame.height)
        window.view.addSubview(content.view)
        
        UIView.animate(withDuration: 0.15, animations: {
            content.view.alpha = 1.0
        })
    }
    
    func updateForLeftBarButtonAction() {
        let button = self.navigationItem.leftBarButtonItem
        button?.action = #selector(self.popMe)
    }
    
    @objc func popMe() {
        if self.navigationController == nil {
            if let index = self.tabBarController?.selectedIndex, let nvc = self.tabBarController?.childViewControllers[index] as? UINavigationController {
                nvc.popViewController(animated: true)
            } else {
                self.dismiss(animated: true, completion: nil)
            }
        } else {
            _ = self.navigationController?.popViewController(animated: true)
        }
    }
    
    func addKeyboardListnerWithDelegate(_ constraint :NSLayoutConstraint, adjusment :CGFloat?, delegate :ConstraintHelperDelegate) {
        ConstraintHelper.helper.delegate = delegate
        addKeyboardListner(constraint, adjusment: adjusment, isCenter: false)
    }
    
    func addKeyboardListner(_ constraint :NSLayoutConstraint, adjusment :CGFloat?, isCenter :Bool) {
        ConstraintHelper.helper.constraint = constraint
        ConstraintHelper.helper.adjusment = adjusment ?? 0.0
        ConstraintHelper.helper.isCenter = isCenter
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(_:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardDidHide(_:)), name: .UIKeyboardWillHide, object: nil)
    }
    
    func removeKeyboardListner() {
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardDidHide, object: nil)
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let userInfo = notification.userInfo {
            let kayBoard = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            let duration:TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIViewAnimationOptions().rawValue
            let animationCurve:UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)
            let constant :CGFloat = kayBoard!.height - ConstraintHelper.helper.adjusment
            
            if ConstraintHelper.helper.isCenter == true {
                ConstraintHelper.helper.constraint?.constant = -constant/2
            } else {
                ConstraintHelper.helper.constraint?.constant = constant
            }
            
            UIView.animate(withDuration: duration,
                           delay: TimeInterval(0),
                           options: animationCurve,
                           animations: {
                            DispatchQueue.main.async {
                                self.view.layoutIfNeeded()
                            }
                            
            },
                           completion: nil)
            
            ConstraintHelper.helper.delegate?.didChangeKeyboardAppearance(constant)
        }
    }
    
    @objc func keyboardDidHide(_ notification: Notification) {
        if let userInfo = notification.userInfo {
//            let kayBoard = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            let duration:TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIViewAnimationOptions().rawValue
            let animationCurve:UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)
            
            ConstraintHelper.helper.constraint?.constant = 0.0
            ConstraintHelper.helper.delegate?.didChangeKeyboardAppearance(0.0)
            
            UIView.animate(withDuration: duration,
                           delay: TimeInterval(0),
                           options: animationCurve,
                           animations: {
                            
                            DispatchQueue.main.async {
                                self.view.layoutIfNeeded()
                            }
                            
            },
                           completion: nil)
        }
    }
    
    internal func applyStatusBarView(_ isClear :Bool) {
        guard isClear == false else {
            UIApplication.shared.statusBarView?.backgroundColor = UIColor.clear
            return
        }
        
        UIApplication.shared.statusBarView?.backgroundColor = UIColor().initWithAlpha(hexCode: 0x7F7F7F, alpha: 0.8)
        
    }
    
    internal func applyGreenStatusBarView() {
        UIApplication.shared.statusBarView?.backgroundColor = UIColor(hexCode: 0x00222B)
    }
}

extension UINavigationController {
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        self.isNavigationBarHidden = true
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        UINavigationBar.appearance().shadowImage = UIImage()
        self.navigationBar.isTranslucent = false
    }
    
    func displayInfo(text :String) {
        guard let viewController = self.childViewControllers.last else {
            return
        }
        
        if let label = viewController.view.viewWithTag(1200) as? UILabel {
            label.text = text
            return
        }
        
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: viewController.view.frame.width, height: 100))
        label.textColor = UIColor.white
        label.text = text
        label.textAlignment = .center
        label.backgroundColor = UIColor(white: 0.22, alpha: 0.8)
        label.tag = 1200
        label.font = UIFont.systemFont(ofSize: 12)
        label.sizeToFit()
        label.frame.size.width = viewController.view.frame.size.width
        label.frame.size.height = label.frame.size.height * 2.0
        label.alpha = 0.0
        viewController.view.addSubview(label)
        
        UIView.animate(withDuration: 0.25, animations: {
            label.alpha = 1.0
        })
    }
    
    @objc func hideInfo() {
        guard let viewController = self.childViewControllers.last else {
            return
        }
        
        if let view = viewController.view.viewWithTag(1200) {
            UIView.animate(withDuration: 0.5, animations: {
                view.alpha = 0.0
            }, completion: { (success) in
                view.removeFromSuperview()
            })
        }
    }
    
    func hideInfoAt(duration :Int) {
        self.perform(#selector(self.hideInfo), with: nil, afterDelay: TimeInterval(duration))
    }
    
    var progressBar :UIProgressView {
        get {
            let pv = UIProgressView(frame: CGRect(x: 0, y: 64, width: UIScreen.main.bounds.size.width, height: 4.0))
            pv.progress = 0.0
            pv.tag = 140
            pv.alpha = 1.0
            return pv
        }
    }
    
    func showProgress(_ value :CGFloat) {
        DispatchQueue.main.async {
            if value == 1.0 {
                self.hideProgress()
            }

            if let view = self.view {
                if let pb = view.viewWithTag(140) as? UIProgressView {
                    pb.progress = Float(value)
                    return
                }
                
                if view.subviews.contains(self.progressBar) {
                    self.progressBar.setProgress(Float(value), animated: true)
                } else {
                    view.addSubview(self.progressBar)
                    self.showProgress(value)
                }
            }
        }
    }
    
    func hideProgress() {
        DispatchQueue.main.async {
            if let view = self.view {
                if let pb = view.viewWithTag(140) as? UIProgressView {
                    UIView.animate(withDuration: 0.5, animations: {
                        pb.alpha = 0.0
                    }, completion: { (success) in
                        pb.removeFromSuperview()
                    })
                    return
                }
                
                if view.subviews.contains(self.progressBar) {
                    UIView.animate(withDuration: 0.5, animations: {
                        self.progressBar.alpha = 0.0
                    }, completion: { (success) in
                        self.progressBar.removeFromSuperview()
                    })
                }
            }
        }
    }
}

extension UICollectionView {
    typealias ClosureLongPress = ((_ indexPath :IndexPath)->Void)
    
    static var longPressClosure :ClosureLongPress?
    
    func enableLongPressOnCell(closure :@escaping ClosureLongPress) {
        UITableView.longPressClosure = closure
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(gesture:)))
        self.addGestureRecognizer(gesture)
    }
    
    @objc func handleLongPress(gesture : UILongPressGestureRecognizer!) {
        if gesture.state != .ended {
            return
        }
        
        let pointer = gesture.location(in: self)
        
        if let indexPath = self.indexPathForItem(at: pointer) {
            UITableView.longPressClosure?(indexPath)
        } else {
            print("couldn't find index path")
        }
    }
}

extension UITableView {
    typealias ClosureLongPress = ((_ indexPath :IndexPath)->Void)
    
    static var longPressClosure :ClosureLongPress?
    
    func enableLongPressOnCell(closure :@escaping ClosureLongPress) {
        UITableView.longPressClosure = closure
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(gesture:)))
        self.addGestureRecognizer(gesture)
    }
    
    @objc func handleLongPress(gesture : UILongPressGestureRecognizer!) {
        if gesture.state != .ended {
            return
        }
        
        let pointer = gesture.location(in: self)
        
        if let indexPath = self.indexPathForRow(at: pointer) {
            UITableView.longPressClosure?(indexPath)
        } else {
            print("couldn't find index path")
        }
    }
    
    func updateTableContentInset() {
        let numSections = self.numberOfSections
        var contentInsetTop = self.bounds.size.height
        for section in 0..<numSections {
            let numRows = self.numberOfRows(inSection: section)
            let sectionHeaderHeight = self.rectForHeader(inSection: section).size.height
            let sectionFooterHeight = self.rectForFooter(inSection: section).size.height
            contentInsetTop -= sectionHeaderHeight + sectionFooterHeight
            for i in 0..<numRows {
                let rowHeight = self.rectForRow(at: IndexPath(item: i, section: section)).size.height
                contentInsetTop -= rowHeight
                if contentInsetTop <= 0 {
                    contentInsetTop = 0
                    break
                }
            }
            
            if contentInsetTop == 0 {
                break
            }
        }
        
        self.alwaysBounceVertical = contentInsetTop < 0
        self.contentInset = UIEdgeInsetsMake(contentInsetTop, 0, 0, 0)
    }
    
    func scrollToBottom(_ animated: Bool = false) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
            if self.numberOfSections == 0 {
                if self.contentSize.height > self.frame.size.height {
                    let offset = CGPoint(x: 0, y: self.contentSize.height - self.frame.size.height)
                    self.setContentOffset(offset, animated: animated)
                }
                return
            }
            
            let section = self.numberOfSections == 0 ? 0 : (self.numberOfSections - 1)
            let row = self.numberOfRows(inSection: section) == 0 ? 0 : (self.numberOfRows(inSection: section) - 1)
            if section == 0 && row == 0 {
                return
            }
            self.scrollToRow(at: IndexPath(row: row, section: section), at: .bottom, animated: false)
        }
    }
}

extension UITableViewCell {
    func toggleColor(_ index :Int) {
        if (index % 2) == 1 {
            self.backgroundColor = UIColor(hexCode: 0xF6F6F6)
        } else {
            self.backgroundColor = UIColor(hexCode: 0xFFFFFF)
        }
    }
}

protocol RecordingControlActionsDelegate {
    func didClickOnDelete(sender :UIButton, object :AnyObject, cell :UITableViewCell)
    func didClickOnModify(sender :UIButton, object :AnyObject, cell :UITableViewCell)
}

class RecordingControlTableViewCell :UITableViewCell {
    
    static var currentCell : RecordingControlTableViewCell?
    
    var upperView :UIView?
    var idealRect :CGRect?
    var expanded = false
    var buttonCount :CGFloat = 2
    
    var delegate :RecordingControlActionsDelegate?
    
    func awakeFromNib(swipeable :UIView, with buttonCount :CGFloat) {
        super.awakeFromNib()
        
        self.buttonCount = buttonCount
        self.upperView = swipeable
        
        if upperView == nil {
            return
        }
        
        addPanGesture()
    }
    
    func awakeFromNib(swipeable :UIView) {
        awakeFromNib(swipeable: swipeable, with: 2)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {}
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {}
    
    func addPanGesture() {
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(self.pangesture))
        pan.delegate = self
        self.addGestureRecognizer(pan)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.close))
        self.addGestureRecognizer(tap)
    }
    
    @objc func close() {
        if expanded {
            collapse()
        }
    }
    
    @objc func pangesture(_ gesture :UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        
        if fabs(translation.y) > fabs(translation.x) {
            return
        }
        
        if gesture.state == .began {
            idealRect = self.upperView?.frame
            
            if self.expanded == false && translation.x > 0 {
                return
            } else if self.expanded == true && (idealRect!.origin.x - translation.x) < -(72 * buttonCount) {
                return
            }
        } else if gesture.state == .changed {
            if translation.x < 0 {
                if fabs(translation.x) > fabs((-(72 * buttonCount)-10)) {
                    return
                }
            } else {
                if self.upperView!.frame.origin.x > -62.0 {
                    return
                }
            }
            if idealRect == nil { return }
            self.upperView!.frame = CGRect(x: idealRect!.origin.x + translation.x, y: 0, width: self.upperView!.frame.width, height: self.upperView!.frame.height)
        } else if gesture.state == .ended {
            if translation.x < (-(72 * buttonCount)-10)/2.0 {
                expand()
            } else {
                collapse()
            }
        }
    }
    
    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func collapse() {
        UIView.animate(withDuration: 0.2, animations: {
            self.upperView!.frame = CGRect(x: 0, y: 0, width: self.upperView!.frame.width, height: self.upperView!.frame.height)
        }, completion: { (success) in
            self.expanded = false
        })
    }
    
    func expand() {
        if RecordingControlTableViewCell.currentCell != self {
            RecordingControlTableViewCell.currentCell?.collapse()
            RecordingControlTableViewCell.currentCell = self
        }
        
        UIView.animate(withDuration: 0.2, animations: {
            self.upperView!.frame = CGRect(x: -(72 * self.buttonCount)-10, y: 0, width: self.upperView!.frame.width, height: self.upperView!.frame.height)
        }, completion: { (success) in
            self.expanded = true
        })
    }
    
}

class DateHelper {
    static let calendar = {
        return Calendar.current
    }()
}

extension NSRange {
    func range(for str: String) -> Range<String.Index>? {
        guard location != NSNotFound else { return nil }
        
        guard let fromUTFIndex = str.utf16.index(str.utf16.startIndex, offsetBy: location, limitedBy: str.utf16.endIndex) else { return nil }
        guard let toUTFIndex = str.utf16.index(fromUTFIndex, offsetBy: length, limitedBy: str.utf16.endIndex) else { return nil }
        guard let fromIndex = String.Index(fromUTFIndex, within: str) else { return nil }
        guard let toIndex = String.Index(toUTFIndex, within: str) else { return nil }
        
        return fromIndex ..< toIndex
    }
}

extension UIImage {
    func encodeToBase64() -> String {
        let data = UIImagePNGRepresentation(self)
        if let imageData = data {
            return imageData.base64EncodedString(options: NSData.Base64EncodingOptions())
        }
        return Data().base64EncodedString(options: NSData.Base64EncodingOptions())
    }
}

extension UIImage {
    func imageResize(_ sizeChange:CGSize)-> UIImage {
        let hasAlpha = false
        let scale: CGFloat = 0.0
        
        UIGraphicsBeginImageContextWithOptions(sizeChange, !hasAlpha, scale)
        self.draw(in: CGRect(origin: CGPoint.zero, size: sizeChange))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage!
    }
    
    func resize(to width: CGFloat) -> UIImage {
        let scale = width / self.size.width
        let newHeight = self.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: width, height: newHeight))
        self.draw(in: CGRect(x: 0, y: 0, width: width, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}

enum DateType :String {
    case ddMMyyyyHHmmss = "dd/MM/yyyy HH:mm:ss"
    case hhmm = "HH:mm"
    case hhmmss = "HH:mm:ss"
    case ddMMMMyyyy = "dd MMMM yyyy"
    case eeeeddMMMM = "EEEE, dd MMMM"
    case yyyyMMddHHmmss = "yyyy'-'MM'-'dd HH':'mm':'ss"
    case eeeeddMMHHmm = "EEEE, dd MMMM '-' HH':'mm"
    case eeeddMMMyyyyHHmmssZ = "EEE, dd MMM yyyy HH':'mm':'ss'Z'"
    case yyyyMMddTHHmmssZ = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
    case osiFormatted = "osi"
}

extension Date {
    var yesterday: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: noon)!
    }
    var tomorrow: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: noon)!
    }
    var sevenBefour: Date {
        return Calendar.current.date(byAdding: .day, value: -7, to: noon)!
    }
    var monthBefour: Date {
        return Calendar.current.date(byAdding: .day, value: -30, to: noon)!
    }
    var twoMonthsBefour: Date {
        return Calendar.current.date(byAdding: .day, value: -60, to: noon)!
    }
    var yearBefour: Date {
        return Calendar.current.date(byAdding: .day, value: -365, to: noon)!
    }
    var noon: Date {
        return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: self)!
    }
    var month: Int {
        return Calendar.current.component(.month,  from: self)
    }
    var isLastDayOfMonth: Bool {
        return tomorrow.month != month
    }
    
    ///"yyyy-MM-dd"
    func formattedStringFromDate2() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: self)
    }
    
    ///"Thursday, December 25, 2014"
    func formattedStringFromDate4() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.full
        return dateFormatter.string(from: self)
    }
    
    var zeroCurrentDate :String {
        get {
            return formattedDate(.yyyyMMddTHHmmssZ, isZeroGMT: true)
        }
    }
    
    func formattedDate(_ format :DateType, isZeroGMT :Bool) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format.rawValue
        if isZeroGMT == true {
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        }
        return dateFormatter.string(from: self)
    }
    
    func formattedStringFromDate6() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return dateFormatter.string(from: self)
    }
    
    ///"2016-09-15"
    func formattedDateString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        return dateFormatter.string(from: self)
    }
    
    ///"15:31:00"
    func formattedTimeString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a"
        return dateFormatter.string(from: self)
    }
    
    func formattedTimeString2() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        return dateFormatter.string(from: self)
    }
    
    func formattedDate(_ format :DateType) -> String {
        return formattedDate(format, isZeroGMT: false)
    }
    
    func osiFormattedDate() -> String {
        let day = formattedDate(.eeeeddMMHHmm).replacingOccurrences(of: "\(cday)", with: "\(cday.daySuffix)")
        return day
    }
    
    var foodDiaryFormattedDate :String {
        get {
            return "\(cdayString), \(cday.daySuffix) \(cmonth.month)"
        }
    }
    
    func year() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy"
        return dateFormatter.string(from: self)
    }
    
    var cmonth :Int {
        get {
            let calendar: Calendar = Calendar.current
            let flags = NSCalendar.Unit.month
            let components = (calendar as NSCalendar).components(flags, from: self)
            return components.month ?? 0
        }
    }
    
    var cdayString :String {
        get {
            let calendar: Calendar = Calendar.current
            let flags = NSCalendar.Unit.weekdayOrdinal
            let components = (calendar as NSCalendar).components(flags, from: self)
            return ((components.weekdayOrdinal ?? 0) + 1).dayString
        }
    }
    
    var cyear :Int {
        get {
            let calendar: Calendar = Calendar.current
            let flags = NSCalendar.Unit.year
            let components = (calendar as NSCalendar).components(flags, from: self)
            return components.year ?? 0
        }
    }
    
    var cday :Int {
        get {
            let calendar: Calendar = Calendar.current
            let flags = NSCalendar.Unit.day
            let components = (calendar as NSCalendar).components(flags, from: self)
            return components.day ?? 0
        }
    }
    
    var chour :Int {
        get {
            let calendar: Calendar = Calendar.current
            let flags = NSCalendar.Unit.hour
            let components = (calendar as NSCalendar).components(flags, from: self)
            return components.hour ?? 0
        }
    }
    
    var cminute :Int {
        get {
            let calendar: Calendar = Calendar.current
            let flags = NSCalendar.Unit.minute
            let components = (calendar as NSCalendar).components(flags, from: self)
            return components.minute ?? 0
        }
    }
    
    var formattedTime: String {
        get {
            let date = self
            let date1 = DateHelper.calendar.startOfDay(for: date)
            let date2 = DateHelper.calendar.startOfDay(for: Date())
            let components = (DateHelper.calendar as NSCalendar).components([.day, .hour, .minute, .second], from: date1, to: date2, options: [])
            
            let offset = Int(Date().timeIntervalSinceNow - date.timeIntervalSinceNow)
            
            if let d = components.day, d > 1 {
                return "\(components.day!) days ago"
            } else if let d = components.day, d > 0 {
                return "\(components.day!) day ago"
            } else if offset > 3600 {
                return "\(Int(offset / 3600)) hours ago"
            } else if offset > 60 {
                return "\(Int(offset / 60)) minutes ago"
            } else {
                return "\(offset) seconds ago"
            }
        }
    }
    
    var formattedDate: String {
        get {
            let date1 = DateHelper.calendar.startOfDay(for: self)
            let date2 = DateHelper.calendar.startOfDay(for: Date())
            let components = (DateHelper.calendar as NSCalendar).components([.day, .hour, .minute, .second], from: date1, to: date2, options: [])
            let days = components.day ?? 0
            
            switch days {
            case 0:
                return "Today"
            case 1:
                return "Yesterday"
            case let d where d < 7:
                return "Last Week"
            case let d where d < 30:
                return "Last Month"
            case let d where d < 365:
                return "Last Year"
            default:
                return "Year Ago"
            }
        }
    }
}

extension Double {
    var formattedTime: String? {
        get {
            var formattedTime = ""
            let fhours: Int = Int(self / 3600)
            let fminutes: Int = Int((self.truncatingRemainder(dividingBy: 3600)) / 60)
            let fseconds: Int = Int(self.truncatingRemainder(dividingBy:60))
            if fhours > 0 {
                formattedTime = formattedTime + ("\(fhours < 10 ? "0\(fhours)" : "\(fhours)"):\(fminutes < 10 ? "0\(fminutes)" : "\(fminutes)"):\(fseconds < 10 ? "0\(fseconds)" : "\(fseconds)")")
            } else if fminutes > 0 {
                formattedTime = formattedTime + ("\(fminutes < 10 ? "0\(fminutes)" : "\(fminutes)"):\(fseconds < 10 ? "0\(fseconds)" : "\(fseconds)")")
            } else {
                formattedTime = formattedTime + ("\(fseconds < 10 ? "0\(fseconds)" : "\(fseconds)")s")
            }
            return formattedTime
        }
    }
    
    var formattedSecondsTime: String? {
        get {
            var formattedTime = ""
            let fminutes: Int = Int(self / 60.0)
            let fseconds: Int = Int(self.truncatingRemainder(dividingBy:60))
            formattedTime = formattedTime + ("\(fminutes < 10 ? "0\(fminutes)" : "\(fminutes)"):\(fseconds < 10 ? "0\(fseconds)" : "\(fseconds)")")
            
            return formattedTime
        }
    }
}

extension UILabel {
    func superScriptText(_ text :String, superText :String) -> NSMutableAttributedString {
        let attString:NSMutableAttributedString = NSMutableAttributedString(string: text, attributes: [NSAttributedStringKey.font:font!])
        attString.setAttributes([NSAttributedStringKey.font:UIFont.systemFont(ofSize: 12),NSAttributedStringKey.baselineOffset:10], range: NSRange(location:attString.length-1,length:1))
        return attString
    }
    
    func coloredLable(_ text :String?, color :UIColor) {
        guard let string = self.text else {
            return
        }
        
        guard let coloredText = text else {
            return
        }
        
        let mutableString = NSMutableAttributedString(string: string)
        let range = NSString(string: string).range(of: coloredText)
        mutableString.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor.orange, range: range)
        self.attributedText = mutableString
    }
}

extension UILabel {
    func updateWithFormat() {
        guard self.text != nil else {
            return
        }
        
        var r1 = 0
        
        let chars = Array(self.text!.characters)
        
        for idx in 0 ... chars.count-1 {
            let char = chars[idx]
            if char == "(" {
                r1 = idx
            }
        }
        
        if r1 == 0 {
            return
        }
        
        let range = NSMakeRange(r1, chars.count-r1)
        let mutableString = NSMutableAttributedString(string: self.text!)
        mutableString.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor(white: 0.0, alpha: 0.56), range: range)
        self.attributedText = mutableString
    }
}

protocol RegularExpressionMatchable {
    func match(_ pattern: String, options: NSRegularExpression.Options) throws -> Bool
}

class SuperScriptLabel: UILabel {
    override func layoutSubviews() {
        let font:UIFont? = UIFont(name: "Helvetica", size:20)
        let fontSuper:UIFont? = UIFont(name: "Helvetica", size:14)
        let attString:NSMutableAttributedString = NSMutableAttributedString(string: "m2", attributes: [NSAttributedStringKey.font:font!])
        attString.setAttributes([NSAttributedStringKey.font:fontSuper!,NSAttributedStringKey.baselineOffset:10], range: NSRange(location:1,length:1))
        self.attributedText = attString
    }
}

typealias ClosureTextOutjet = (_ text :String)->Void

@IBDesignable class CustomColoredLable :UILabel {
    @IBInspectable var orangeColoredText : String? {
        set (newValue) {
            guard let string = self.text else {
                return
            }
            
            guard newValue != nil else {
                return
            }
            
            let mutableString = NSMutableAttributedString(string: string)
            let range = NSString(string: string).range(of: newValue!)
            mutableString.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor.orange, range: range)
            self.attributedText = mutableString
        }
        get {
            return self.text
        }
    }
}

class CustomDoubleColoredLable :UILabel {
    @IBInspectable var textWithCommaSeperated : String? {
        set (newValue) {
            guard self.text != nil else {
                return
            }
            
            guard newValue != nil else {
                return
            }

            guard let values = newValue?.components(separatedBy: ","), values.count > 0 else {
                return
            }
            
            let mutableString = NSMutableAttributedString(string: self.text!)
            
            for value in values {
                guard self.text!.contains(value) else {
                    continue
                }
                
                mutableString.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor.blue, range: NSString(string: self.text!).range(of: value))
            }
            
            self.attributedText = mutableString
        }
        get {
            return self.text
        }
    }
}

class BBCorrectSelectorView :UIControl {
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
    }
    
    @IBOutlet var buttons: [UIButton]!
    
    var value :Int? = 1
    
    func resetButtons(_ type :Int) {
        buttons.forEach { (button) in
            button.isSelected = false
        }
        buttons[type].isSelected = !buttons[type].isSelected
    }
    
    @IBAction func actionClickBasal(_ sender :UIButton?) {
        resetButtons(0)
        self.value = 1
        self.sendActions(for: UIControlEvents.valueChanged)
    }
    
    @IBAction func actionClickBosul(_ sender :UIButton?) {
        resetButtons(1)
        self.value = 2
        self.sendActions(for: UIControlEvents.valueChanged)
    }
    
    @IBAction func actionClickCorrection(_ sender :UIButton?) {
        resetButtons(2)
        self.value = 3
        self.sendActions(for: UIControlEvents.valueChanged)
    }
}

class FieldsLimitationWrapper  {
    var textOutjet :ClosureTextOutjet?
    var view: UITextFieldDelegate?
    static let defaultWrapper = FieldsLimitationWrapper()
    
    
    func setDelegate(_ view :UITextFieldDelegate) -> FieldsLimitationWrapper {
        self.view = view
        return FieldsLimitationWrapper.defaultWrapper
    }
    
    func setDelegate(_ view :UITextFieldDelegate, constraints :[Int]) -> FieldsLimitationWrapper {
        self.view = view
        return FieldsLimitationWrapper.defaultWrapper
    }
    
    var limitationsFields: [UITextField:Int]? = [UITextField:Int]() {
        didSet {
            limitationsFields?.forEach({ (field, value) in
                if field.delegate == nil {
                    field.delegate = view
                } else {
                    print(field.text ?? "")
                }
            })
        }
    }
    
    var valueConstraints : [UITextField : [Int]] = [UITextField:[Int]]()
    
    static func discard() {
        defaultWrapper.limitationsFields?.removeAll()
        defaultWrapper.view = nil
    }
}

class TextInputTableViewCell: UITableViewCell, UITextFieldDelegate {

    @objc func textFeildTextChange(textField :UITextField) {}
    
    @objc func textFeildStartTyping(textField :UITextField) {}
    
    func initializeTextLimits(_ limit :Int, forTextField textField: UITextField?) {
        guard let field = textField else {
            return
        }
        
        FieldsLimitationWrapper.defaultWrapper.setDelegate(self).limitationsFields?[field] = limit
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if string == "" {
            self.perform(#selector(self.textFeildTextChange(textField:)), with: textField, afterDelay: 0.01)
            return true
        }
        
        if let length = FieldsLimitationWrapper.defaultWrapper.limitationsFields?[textField], length < (textField.text?.count)! {
            return false
        }
        
        self.perform(#selector(self.textFeildTextChange(textField:)), with: textField, afterDelay: 0.01)
        
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.rightViewMode == .always {
            textField.rightViewMode = .never
        }
        
        self.perform(#selector(self.textFeildStartTyping(textField:)), with: textField, afterDelay: 0.01)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        makeValidation { (success) in
            
        }
    }
    
    func makeValidation(validation :((_ valid :Bool)->Void)) {
        
    }
    
    func resetFields() {
        
    }
}

class TextInputViewController: UIViewController, UITextFieldDelegate {
    
    @objc func textFeildTextChange(textField :UITextField) {}
    
    @objc func textFeildStartTyping(textField :UITextField) {}
    
    func initializeTextLimits(_ limit :Int, forTextField textField: UITextField?) {
        guard let field = textField else {
            return
        }
        FieldsLimitationWrapper.defaultWrapper.setDelegate(self).limitationsFields?[field] = limit
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if string == "" {
            self.perform(#selector(self.textFeildTextChange(textField:)), with: textField, afterDelay: 0.01)
            return true
        }
        
        if let length = FieldsLimitationWrapper.defaultWrapper.limitationsFields?[textField], length < (textField.text?.count)! {
            return false
        }
        
        self.perform(#selector(self.textFeildTextChange(textField:)), with: textField, afterDelay: 0.01)
        
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.rightViewMode == .always {
            textField.rightViewMode = .never
        }
        
        self.perform(#selector(self.textFeildStartTyping(textField:)), with: textField, afterDelay: 0.01)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        makeValidation { (success) in
            
        }
    }
    
    func makeValidation(validation :((_ valid :Bool)->Void)) {
        
    }
    
    func resetFields() {
        
    }
}

extension UITextField: UITextFieldDelegate {
    @IBInspectable var placeHolderColor: UIColor? {
        get {
            return self.placeHolderColor
        }
        set {
            self.attributedPlaceholder = NSAttributedString(string: (self.placeholder != nil ? self.placeholder! : ""), attributes: [NSAttributedStringKey.foregroundColor : newValue!])
        }
    }
    
    func limitSize(_ length :Int = 10) {
        FieldsLimitationWrapper.defaultWrapper.limitationsFields?[self] = length
        self.delegate = self
    }
    
    func limitSize(_ length :Int = 10, textOutjet :@escaping ClosureTextOutjet) {
        FieldsLimitationWrapper.defaultWrapper.textOutjet = textOutjet
        limitSize(length)
    }
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if string == "" {
            self.perform(#selector(self.outcast), with: nil, afterDelay: 0.1)
            return true
        }
        
        if let length = FieldsLimitationWrapper.defaultWrapper.limitationsFields?[textField],let text = textField.text, length < text.count {
            return false
        }
        self.perform(#selector(self.outcast), with: nil, afterDelay: 0.1)
        
        return true
    }

    @objc func outcast() {
        FieldsLimitationWrapper.defaultWrapper.textOutjet?(self.text!)
    }
}

extension PickerWrapper :UITextFieldDelegate {

    func checkDelegate() {
        if field?.delegate == nil {
            field?.delegate = self
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if let text = textField.text, text.characters.count == 0, let cnt = count, cnt > 0 {
            self.selectRow(0, inComponent: 0, animated: true)
            self.closure?(0)
        }
    }
    
}

class PickerWrapper :UIPickerView, UIPickerViewDelegate, UIPickerViewDataSource {
    var count :Int?
    var field :UITextField?
    
    typealias SelectionClosure = ((_ index: Int)->Void)
    typealias DataClosure = ((_ index: Int)->String)
    
    var closure :SelectionClosure?
    var closureData :DataClosure?
    
    func populate(_ count :Int, dataClosure :@escaping DataClosure, selection :@escaping SelectionClosure) {
        self.closureData = dataClosure
        self.closure = selection
        self.count = count
        self.reloadAllComponents()
    }
    
    convenience init(field :UITextField, count :Int, selection :@escaping SelectionClosure, dataClosure :@escaping DataClosure) {
        self.init()
        
        self.closure = selection
        self.closureData = dataClosure
        
        self.field = field
        self.field?.inputView = self
        self.count = count
        self.delegate = self
        self.dataSource = self
        self.reloadAllComponents()
        
        checkDelegate()
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return count ?? 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return closureData!(row)
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if count! > 0 {
            self.closure?(row)
        } else {
            endEditing(true)
        }
    }
    
}

class TextChangeListner :UIView, UITextFieldDelegate {
    static let helper = TextChangeListner()
    typealias ClosureEdit = ((_ text :String?)->Void)
    var closure :ClosureEdit? = nil

    var field = Set<UITextField>() {
        didSet {
            field.forEach { (field) in
                if field.delegate == nil {
                    field.delegate = self
                }
            }
        }
    }

    func config(field :UITextField!, closure :ClosureEdit?) {
        TextChangeListner.helper.closure = closure
        TextChangeListner.helper.field.insert(field)
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        self.perform(#selector(self.changeText(textField:)), with: textField, afterDelay: 0.1)
        return true
    }

    @objc func changeText(textField: UITextField) {
        closure?(textField.text)
    }
}

class CustomSearchBar :UITextField {
    static let helper = CustomSearchBar()
    typealias ClosureEdit = ((_ text :String?)->Void)
    var closure :ClosureEdit? = nil
    
    typealias ClosureResponder = ((_ isBecome :Bool?)->Void)
    var closureResponder :ClosureResponder? = nil
    
    var field = Set<UITextField>() {
        didSet {
            field.forEach { (field) in
                if field.delegate == nil {
                    field.delegate = self
                }
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.returnKeyType = .done
    }
    
    func textChangeListner(closure :ClosureEdit?) {
        CustomSearchBar.helper.closure = closure
        CustomSearchBar.helper.field.insert(self)
    }
    
    func textFieldResponderListner(closure :ClosureResponder?) {
        CustomSearchBar.helper.closureResponder = closure
        CustomSearchBar.helper.field.insert(self)
    }

    override func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        self.perform(#selector(self.changeText(textField:)), with: textField, afterDelay: 0.1)
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.perform(#selector(self.textFieldBeginEditing(textField:)), with: textField, afterDelay: 0.0)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.perform(#selector(self.textFieldEndEditing(textField:)), with: textField, afterDelay: 0.0)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    @objc func changeText(textField: UITextField) {
        closure?(textField.text)
    }
    
    @objc func textFieldBeginEditing(textField: UITextField) {
        closureResponder?(true)
    }
    
    @objc func textFieldEndEditing(textField: UITextField) {
        closureResponder?(false)
    }
}

extension UIView {
    func loadFromNibNamed(nibNamed: String) -> UIView? {
        let view = UINib(nibName: nibNamed, bundle: nil).instantiate(withOwner: nil, options: nil)[0] as? UIView
        return view
    }
    
    @objc var acv : UIActivityIndicatorView {
        get {
            let gap = CGFloat(0.0)
            let aiv = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)
            aiv.frame = CGRect(x: gap, y: gap, width: self.frame.width - gap*2, height: self.frame.height - gap*2)
            aiv.color = UIColor.white
            aiv.tintColor = UIColor.white
            aiv.layer.cornerRadius = 0.0
            aiv.startAnimating()
            aiv.tag = 215
            aiv.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
            return aiv
        }
    }
    
    @objc var acvCenter : UIActivityIndicatorView {
        get {
            let aiv = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)
            aiv.frame = CGRect(x: (self.frame.width/2 - 10), y: (self.frame.height/2 - 10), width: 20, height: 20)
            aiv.color = UIColor.white
            aiv.tintColor = UIColor.white
            aiv.layer.cornerRadius = 0.0
            aiv.startAnimating()
            aiv.tag = 215
            aiv.backgroundColor = UIColor.clear
            return aiv
        }
    }
    
    func progressive(align :Int) {
        if align == -1 {
            
        } else if align == 1 {
        
        } else {
            
        }
    }
    
    func disableInteration() {
        self.isUserInteractionEnabled = false
    }
    
    func progressiveCenter() {
        if let _ = self.viewWithTag(215) as? UIActivityIndicatorView {
        } else {
            self.addSubview(acvCenter)
            self.bringSubview(toFront: acvCenter)
        }
        
        self.isUserInteractionEnabled = false
        self.clipsToBounds = true
    }
    
    func progressive() {
        if let _ = self.viewWithTag(215) as? UIActivityIndicatorView {
        } else {
            self.addSubview(acv)
            self.bringSubview(toFront: acv)
        }
        
        self.isUserInteractionEnabled = false
        self.clipsToBounds = true
    }
    
    func progressive(intensity :CGFloat) {
        progressive()
        acv.backgroundColor = UIColor(white: 0.0, alpha: intensity)
        acv.tintColor = UIColor(white: 1.0, alpha: intensity)
    }
    
    func progressive(color :UIColor) {
        progressive()
        acv.backgroundColor = UIColor.clear
        acv.tintColor = color
    }
    
    func progressiveIconless(color :UIColor) {
        progressive()
        acv.backgroundColor = UIColor.clear
        acv.tintColor = color
    }
    
    func deprogressive() {
        if let aciv = self.viewWithTag(215) as? UIActivityIndicatorView {
            aciv.removeFromSuperview()
            
            if let btn = self as? UIButton {
                btn.imageView?.isHidden = false
            }
        }
        
        if let text = self.accessibilityValue {
            if let btn = self as? UIButton {
                btn.setTitle(text, for: .normal)
                self.accessibilityValue = nil
            }
        }
        
        self.isUserInteractionEnabled = true
    }
    
    internal func applyGradientLayer(colors :[CGColor], frame :CGRect) {
        let gradientLayer = CAGradientLayer()
        
        gradientLayer.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
        
        gradientLayer.colors = colors
        gradientLayer.locations = [0.0, 1.0]
        
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0, y: 1)
        
        self.layer.addSublayer(gradientLayer)
        gradientLayer.zPosition = -1
    }
    
    internal func applyGradientLayerForVc() {
        let colors = [UIColor(hexCode: 0x004455).cgColor, UIColor(hexCode: 0x0088AA).cgColor]
        let frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        
        self.applyGradientLayer(colors: colors, frame: frame)
    }
    
    func applyGradientLayerForHorizontal(_ height: CGFloat) {
        let colors = [UIColor(hexCode: 0x004455).cgColor, UIColor(hexCode: 0x0088AA).cgColor]
        
        let gradientLayer = CAGradientLayer()
        
        gradientLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: height)
        
        gradientLayer.colors = colors
        
        gradientLayer.startPoint = CGPoint(x: 1, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 0, y: 0.5)
        
        self.layer.addSublayer(gradientLayer)
        gradientLayer.zPosition = -1
    }
    
    func applyGradientLayerHorizontal(colors :[CGColor], frame :CGRect) {
        let gradientLayer = CAGradientLayer()
        
        gradientLayer.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
        
        gradientLayer.colors = colors
        
        gradientLayer.startPoint = CGPoint(x: 1, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 0, y: 0.5)
        
        self.layer.addSublayer(gradientLayer)
        gradientLayer.zPosition = -1
    }
}

extension UIImageView {
    override var acv : UIActivityIndicatorView {
        get {
            let gap = CGFloat(0.0)
            let aiv = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.white)
            aiv.frame = CGRect(x: gap, y: gap, width: self.frame.width - gap*2, height: self.frame.height - gap*2)
            aiv.color = UIColor.white
            aiv.tintColor = UIColor.white
            aiv.layer.cornerRadius = 10.0
            aiv.startAnimating()
            aiv.tag = 215
            aiv.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
            return aiv
        }
    }
    
    override var acvCenter : UIActivityIndicatorView {
        get {
            let aiv = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.white)
            aiv.frame = CGRect(x: (self.frame.width/2 - 10), y: (self.frame.height/2 - 10), width: 20, height: 20)
            aiv.color = UIColor.white
            aiv.tintColor = UIColor.white
            aiv.layer.cornerRadius = 10.0
            aiv.startAnimating()
            aiv.tag = 215
            aiv.backgroundColor = UIColor.clear
            return aiv
        }
    }
}

extension UIPrintPageRenderer {
    func printToPDF() -> NSData {
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, self.paperRect, nil)
        self.prepare(forDrawingPages: NSMakeRange(0, self.numberOfPages))
        let bounds = UIGraphicsGetPDFContextBounds()
        for i in 0 ..< self.numberOfPages {
            UIGraphicsBeginPDFPage()
            self.drawPage(at: i, in: bounds)
        }
        UIGraphicsEndPDFContext()
        return pdfData;
    }
}

extension UIWebView {
    func pdfFile(printFormatter: UIViewPrintFormatter) -> NSData {
        let renderer = UIPrintPageRenderer()
        renderer.addPrintFormatter(printFormatter, startingAtPageAt: 0);
        let paperSize = CGSize(width: self.frame.size.width, height: self.frame.size.height)
        let printableRect = CGRect(x: 0, y: 0, width: paperSize.width, height: paperSize.height)
        let paperRect = CGRect(x: 0, y: 0, width: paperSize.width, height: paperSize.height)
        renderer.setValue(NSValue(cgRect: paperRect), forKey: "paperRect")
        renderer.setValue(NSValue(cgRect: printableRect), forKey: "printableRect")
        return renderer.printToPDF()
    }
    
    func clearCache() {
        URLCache.shared.removeAllCachedResponses()
        
        if let cookies = HTTPCookieStorage.shared.cookies {
            for cookie in cookies {
                HTTPCookieStorage.shared.deleteCookie(cookie)
            }
        }
    }
}

extension UITextView {
    var isNewLine: Bool {
        get {
            return self.text.last == "\n"
        }
    }
    
    func numberOfLines() -> Int {
        let layoutManager:NSLayoutManager = self.layoutManager
        let numberOfGlyphs = layoutManager.numberOfGlyphs
        var numberOfLines = 0
        var index = 0
        var lineRange:NSRange = NSRange()
    
        while (index < numberOfGlyphs) {
            layoutManager.lineFragmentRect(forGlyphAt: index, effectiveRange: &lineRange)
            index = NSMaxRange(lineRange);
            numberOfLines = numberOfLines + 1
        }
        
        return numberOfLines
    }
}



class ExpandableTextView :UITextView, UITextViewDelegate {
    typealias ClosureType = (_ text :String, _ isBeginEditing :Bool, _ isEndEditing :Bool)->Void
    var typeCallback :ClosureType?
    
    var isFirstFocus = true
    let placeholderLabel = UILabel()
    
    var placeholder :String = "" {
        didSet {
            if self.text == "" {
                placeholderLabel.text = placeholder
                placeholderLabel.isHidden = false
            }
        }
    }
    
    override internal var text : String! {
        didSet {
            placeholderLabel.isHidden = !text.isEmpty
        }
    }
    
    var isFitToScreen = false {
        didSet {

        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.delegate = self
        
        self.layer.borderColor = UIColor.red.cgColor
        self.layer.borderWidth = 0.0
        self.layer.cornerRadius = 0.0
        self.clipsToBounds = true
        
        placeholderLabel.text = placeholder
        placeholderLabel.textColor = UIColor(hexCode: 0xCCCCCC)
        placeholderLabel.font = UIFont.systemFont(ofSize: 18)
        self.addSubview(placeholderLabel)
        
        self.tintColor = UIColor(hexCode: 0xFF6600)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        placeholderLabel.isHidden = !self.text.isEmpty
        
        if isFirstFocus == true {
            placeholderLabel.frame = CGRect(x: 4, y: self.frame.height-32, width: self.frame.width-8, height: 32)
            
            placeholderLabel.center.y = (placeholderLabel.frame.size.height / 2.0)
            isFirstFocus = false
        }
    }
    
    func listenTypeCallback(textCallback :@escaping ClosureType) {
        typeCallback = textCallback
    }
    
    
    func textViewDidChange(_ textView: UITextView) {
        updateFrame()
        
        textView.sizeThatFits(CGSize(width: textView.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
        
        typeCallback?(textView.text, false, false)
        
        placeholderLabel.isHidden = !textView.text.isEmpty
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        typeCallback?(self.text, false, true)
        placeholderLabel.isHidden = !textView.text.isEmpty
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        typeCallback?(self.text, true, false)
        if textView.text.isEmpty == false && textView.text != placeholder {
            placeholderLabel.isHidden = true
        }
    }
    
    func updateFrame() {
        if self.frame.size.height > 120 {
            isScrollEnabled = true
            isFitToScreen = true
        }
        
        if self.contentSize.height < 120 {
            isScrollEnabled = false
            isFitToScreen = false
        }
    }
    
    func reset() {
        self.text = ""
        self.insertText("")
        self.insertText("")
        resignFirstResponder()
    }
}

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    //0xFFFFFF
    convenience init(hexCode:Int) {
        self.init(red:(hexCode >> 16) & 0xff, green:(hexCode >> 8) & 0xff, blue:hexCode & 0xff)
    }
    
    func initWithAlpha(hexCode:Int, alpha:CGFloat) -> UIColor {
        let red: Int = (hexCode >> 16) & 0xff
        let green: Int = (hexCode >> 8) & 0xff
        let blue: Int = hexCode & 0xff
        
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        return UIColor(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: alpha)
    }
    
    func fromHex(hex: String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.count) != 6) {
            return UIColor.gray
        }
        
        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        return UIColor(hexCode: Int(rgbValue))
    }
    
    //0xFFFFFF7D
    static func color(hexCode:Int64) -> UIColor {
        let cred = (hexCode >> 24) & 0xff
        let cgreen = (hexCode >> 16) & 0xff
        let cblue = (hexCode >> 8) & 0xff
        let calpha = hexCode & 0xff
        
        assert(cred >= 0 && cred <= 255, "Invalid red component")
        assert(cgreen >= 0 && cgreen <= 255, "Invalid green component")
        assert(cblue >= 0 && cblue <= 255, "Invalid blue component")
        assert(calpha >= 0 && calpha <= 255, "Invalid alpha component")
        
        return UIColor(red: CGFloat(cred) / 255.0, green: CGFloat(cgreen) / 255.0, blue: CGFloat(cblue) / 255.0, alpha: CGFloat(calpha) / 255.0)
    }
    
}

extension Collection {
    var pairs: [SubSequence] {
        var start = startIndex
        return (0...count/2).map { _ in
            let end = index(start, offsetBy: 2, limitedBy: endIndex) ?? endIndex
            defer { start = end }
            return self[start..<end]
        }
    }
}

extension StringProtocol where Self: RangeReplaceableCollection {
    mutating func insert(separator: String, every n: Int) {
        indices.reversed().forEach {
            if $0 != startIndex { if distance(from: startIndex, to: $0) % n == 0 { insert(contentsOf: separator, at: $0) } }
        }
    }
    func inserting(separator: String, every n: Int) -> Self {
        var string = self
        string.insert(separator: separator, every: n)
        return string
    }
}

extension Data {
    var hexString :String {
        get {
            let hfpst = self.reduce("") { return $0 + String(format: "%02x", $1) }
            return hfpst.uppercased().inserting(separator: " ", every: 8)
        }
    }
}

extension String {
    subscript (i: Int) -> Character {
        return self[index(startIndex, offsetBy: i)]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
//    subscript (r: Range<Int>) -> String {
//        let start = index(startIndex, offsetBy: r.lowerBound)
//        let end = index(startIndex, offsetBy: r.upperBound)
//        return String(self[Range(start ..< end)])
//    }
    
    var removePhoneNumberFormats :String? {
        get {
            var number = self
            if number.count < 1 {
                return ""
            }
            
            number = number.replacingOccurrences(of: " ", with: "")
            number = number.replacingOccurrences(of: "-", with: "")
            number = number.replacingOccurrences(of: "(", with: "")
            number = number.replacingOccurrences(of: ")", with: "")
            
            if number.hasPrefix("00") {
                number = String(number.suffix(from: number.index(number.startIndex, offsetBy: 2)))
            } else {
                if number.hasPrefix("0") {
                    number = String(number.suffix(from: number.index(number.startIndex, offsetBy: 1)))
                    number = "\(State.defaultCountry?.calling ?? "")\(number)"
                }
            }
            
            number = number.replacingOccurrences(of: "+", with: "")
            
            return number
        }
    }
    
    var getClass: Any? {
        get {
            if let namespace = Bundle.main.infoDictionary!["CFBundleExecutable"] as? String {
                return NSClassFromString("\(namespace).\(self)")
            }
            return nil
        }
    }
    
}

extension Error {
    var code :Int {
        get {
            let code = Int("\(self)".components(separatedBy: "HttpError(").last!.components(separatedBy: ",").first!.components(separatedBy: "statusCode: ").last!)
            return code ?? 0
        }
    }
}