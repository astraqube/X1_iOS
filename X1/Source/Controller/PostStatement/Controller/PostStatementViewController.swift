//
//  PostStatementViewController.swift
//  Solviant
//
//  Created by Rohit Kumar on 18/05/2018.
//  Copyright © 2018 AstraQube. All rights reserved.
//

import UIKit
import ALCameraViewController
import M13Checkbox
import Popover
import CoreLocation
import Whisper

class PostStatementViewController: UIViewController {

    // MARK: - IB Outlet
    
    @IBOutlet weak var searchTagTextField: UITextField!
    @IBOutlet weak var statmentTextView: UITextView!
    @IBOutlet weak var placeholderLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var postStatementButton: UIButton!
    @IBOutlet weak var viewSimilarStatementButton: UIButton!
    @IBOutlet weak var checkBoxView: M13Checkbox!
    @IBOutlet weak var blurView: UIVisualEffectView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var textViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var ratingView: UIView!
    @IBOutlet var ratingButtonsCollections: [UIButton]!
    @IBOutlet var categoryView: UIView!
    @IBOutlet weak var tagsCollectionView: TTGTextTagCollectionView!
    @IBOutlet weak var subcategoryActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var priorityLabel: UILabel!
    @IBOutlet var selectedRatingButtons: [UIButton]!
    @IBOutlet weak var selectTagsCollectionView: TTGTextTagCollectionView!
    @IBOutlet weak var selectedExpertLabel: UILabel!
    @IBOutlet var postUrgencyView: UIView!
    @IBOutlet weak var urgencyTableView: UITableView!
    @IBOutlet weak var ratingButtonsStackView: UIStackView!
    @IBOutlet weak var imageCollectionView: UICollectionView!
    @IBOutlet weak var heightConstraintCollectioView: NSLayoutConstraint!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var editPostButtonsStackView: UIStackView!
    @IBOutlet weak var newPostButtonStackView: UIStackView!
    

    // MARK: - Other Property
    
    var accessoryView:PostStatmentAccessory!
    var popover:Popover?
    var selectedPriority     = PostUrgency.low
    var selectedLevel        = ExpertLevel.rookie
    var locationManager      = LocationManager()
    var currentLocation:CLLocationCoordinate2D?
    var selectedImages:[UIImage]?
    var selectedStatement:Statement!
    var user:User!
    var hasKeyboardLayoutApplied = false
    let webManager = WebRequestManager()
    var hashtags:[String]?
    var textTagConfig:TTGTextTagConfig  {
        let textConfig = TTGTextTagConfig()
        textConfig.tagSelectedTextColor = .white
        textConfig.tagTextColor         = UIColor.lightTheme()
        textConfig.tagBackgroundColor   = .white
        textConfig.tagSelectedBackgroundColor = UIColor.lightTheme()
        return textConfig
    }
    var textTagConfigSelected:TTGTextTagConfig  {
        let textConfig = TTGTextTagConfig()
        textConfig.tagTextColor = .white
        textConfig.tagBackgroundColor = UIColor.lightTheme()
        textConfig.tagBorderColor     = .clear
        return textConfig
    }
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        customizeUI()
        
        // Add notification to observe Keyboard
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        // Get user's location first
        weak var weakSelf = self
        locationManager.currentLocation(location: { (latitude, longitude) in
            weakSelf?.currentLocation = CLLocationCoordinate2D.init(latitude: latitude, longitude: longitude)
        }) { (isGranted) in
            
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        // Remove Keyboard observer before it gets deallocated
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    // MARK: - Utility
    
    private func setRating(with buttonIndex:Int) {
        // Set selected rating for user
        let count = ratingButtonsCollections.count
        for index in 0..<count {
            let isSelected = index <= buttonIndex
            let ratingButton         = ratingButtonsCollections[index]
            let selectedRatingButton = selectedRatingButtons[index]
            ratingButton.isSelected = isSelected
            selectedRatingButton.isSelected = isSelected
        }
        if let expertLevel = ExpertLevel(rawValue: buttonIndex) {
            let (name, _) = expertLevel.description()
            selectedExpertLabel.text = name
        }
        ratingButtonsStackView.isHidden = false
    }
    
    private func customizeUI() {
        postStatementButton.backgroundColor = .clear
        postStatementButton.darkShadow(withRadius: 5)
        postStatementButton.layer.borderWidth = 1.0
        postStatementButton.layer.cornerRadius = 8
        postStatementButton.layer.backgroundColor = UIColor.white.cgColor
        postStatementButton.layer.sublayers?.last?.cornerRadius = 8.0
        postStatementButton.layer.sublayers?.last?.masksToBounds = true
        postStatementButton.layer.borderColor  = UIColor.lightTheme().cgColor
        postStatementButton.setTitleColor(UIColor.darkTheme(), for: .normal)
        postStatementButton.alpha = 0.5
        postStatementButton.isEnabled = false
        
        viewSimilarStatementButton.backgroundColor = .clear
        viewSimilarStatementButton.darkShadow(withRadius: 5)
        viewSimilarStatementButton.layer.borderWidth = 1.0
        viewSimilarStatementButton.layer.backgroundColor = UIColor.white.cgColor
        viewSimilarStatementButton.layer.cornerRadius = 8
        viewSimilarStatementButton.layer.borderColor  = UIColor.lightTheme().cgColor
        viewSimilarStatementButton.setTitleColor(UIColor.darkTheme(), for: .normal)
        
        containerView.backgroundColor = .clear
        containerView.darkShadow(withRadius: 10)
        containerView.layer.backgroundColor = UIColor.white.cgColor
        containerView.layer.cornerRadius = 8
        
        setupKeyboardAccesory()
        
        // Setup tags collectionview
        tagsCollectionView.alignment        = .fillByExpandingWidthExceptLastLine
        selectTagsCollectionView.alignment  = .left
        selectTagsCollectionView.enableTagSelection = false
        selectTagsCollectionView.scrollDirection    = .horizontal
        tagsCollectionView.delegate         = self
        
        // Check if it is opened in editing mode
        if selectedStatement != nil {
            // Set data for this statement
            placeholderLabel.isHidden = true
            statmentTextView.text     = selectedStatement.problemText
            selectedLevel             = selectedStatement.expertLevel
            setRating(with: selectedLevel.rawValue)
            priorityLabel.text        = PostUrgency.low.description().0
            editPostButtonsStackView.isHidden = false
            newPostButtonStackView.isHidden   = true
            titleLabel.text                   = NSLocalizedString("editStatement", comment: "")
            if let tags = selectedStatement.tags {
                for tag in tags {
                    selectTagsCollectionView.addTag(tag, with: textTagConfigSelected)
                }
            }
        }
    }
    
    private func createUpdateStatement(isUpdating: Bool, shouldPublish: Bool = true) {
        let text = statmentTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            return
        }
        let isValidStatement = isValidProblemStatement(with: text)
        guard isValidStatement  else {
            showAlert(with: NSLocalizedString("invaildProblemStatmentTitle", comment: ""), message: NSLocalizedString("invaildProblemStatmentMessage", comment: ""))
            return
        }
        popover?.dismiss()
        view.endEditing(true)
        showActivity()
        var parameters:[String: Any] = Dictionary()
        parameters[PostStatementKey.statement] = text
        
        if let selectedTags = selectTagsCollectionView.allTags(), selectedTags.count > 0 {
            parameters[PostStatementKey.category] = selectedTags
        }
        parameters[PostStatementKey.expertLevel] = selectedLevel.identifier()
        parameters[PostStatementKey.priority]    = selectedPriority.name()
        if let coordinate = currentLocation {
            parameters[PostStatementKey.latitude]  = coordinate.latitude
            parameters[PostStatementKey.longitude] = coordinate.longitude
        }
        parameters[PostStatementKey.location] = PostStatementKey.global
        parameters[APIKeys.status] = shouldPublish.convertForWeb()
        if isUpdating {
            // Update statement
            updateStatment(with: parameters, statement: selectedStatement.identifier, for: user.userId, attachment: selectedImages?.first)
        }
        else {
            // New satement
            postStatment(with: parameters, for: user.userId, attachment: selectedImages?.first)
        }
    }
    
    private func setupKeyboardAccesory() {
        // Set Keyboard Accessory
        accessoryView                           = PostStatmentAccessory.init(frame: CGRect.init(x: 0, y: 0, width: self.view.frame.size.width, height: 40))
        accessoryView.delegate                  = self
        statmentTextView.inputAccessoryView     = accessoryView
        searchTagTextField.inputAccessoryView   = accessoryView
        if(selectedStatement != nil) {
            accessoryView.postStatementButton.setTitle(NSLocalizedString("done", comment: ""), for: .normal)
            accessoryView.postStatementButton.isEnabled = true
            accessoryView.postStatementButton.alpha     = 1.0
        }
        
    }
    
    private func isValidProblemStatement(with text: String) -> Bool {
        // Validate Problem Statment
        if text.contains("?") {
            return false
        }
        return true
    }
    
    private func showAlert(with title:String, message: String) {
        // Show alert to user
        let announcement = Announcement(title: title, subtitle: message, image: #imageLiteral(resourceName: "info"))
        Whisper.show(shout: announcement, to: self, completion: {
            
        })
    }
    
    private func resetTagSearch() {
        // Finish tag searching
        searchTagTextField.text = nil
        if let allTags = hashtags {
            tagsCollectionView.removeAllTags()
            tagsCollectionView.alignment  = .fillByExpandingWidthExceptLastLine
            tagsCollectionView.addTags(allTags, with: textTagConfig)
            // Set selected tags
            setSelectedTags(for: tagsCollectionView.allTags())
        }
    }
    
    private func setSelectedTags(for tagCollection:Array<String>) {
        // Set selecected tags
        if let selectedTags = selectTagsCollectionView.allTags(), selectedTags.count > 0 {
            for tag in selectedTags {
                if let index = tagCollection.index(of: tag) {
                    tagsCollectionView.setTagAt(UInt(index), selected: true)
                }
            }
        }
    }
    
    // MARK: - IB Action
    
    @IBAction func updateStatment(_ sender: Any) {
        // Save the edited post temporarily
        createUpdateStatement(isUpdating: true, shouldPublish: false)
    }
    
    @IBAction func repostStatement(_ sender: Any) {
        // Repost the edited statement
        createUpdateStatement(isUpdating: true)
    }
    
    
    @IBAction func postStatement(_ sender: Any) {
        // Post statement
        createUpdateStatement(isUpdating: false)
    }
    
    @IBAction func viewSimilarStatement(_ sender: Any) {
    }
    
    @IBAction func closeController(_ sender: Any) {
        view.endEditing(true)
        dismiss(animated: true) {
            
        }
    }
    
    @IBAction func addImage(_ sender: Any) {
        // Add image to the question
        view.endEditing(true)
        popover?.dismiss()
        openPhotos()
    }
    
    @IBAction func selectRating(_ sender: UIView) {
        // Show Rating view
        popover?.dismiss()
        if let tag = popover?.tag, tag == sender.tag {
            popover?.tag = -1
            return
        }
        popover = nil
        let options = [
            .type(.up),
            .cornerRadius(5),
            .animationIn(0.3),
            .blackOverlayColor(UIColor.lightGray.withAlphaComponent(0.3)),
            .arrowSize(CGSize.init(width: 10, height: 10))
            ] as [PopoverOption]
        popover = Popover(options: options, showHandler: nil, dismissHandler: nil)
        popover?.tag = sender.tag
        ratingView.frame = CGRect.init(x: 0, y: 0, width: 240, height: 128)
        popover?.show(ratingView, fromView: sender)
        selectedLevel = ExpertLevel(rawValue: sender.tag)!
    }
    
    @IBAction func addCategories(_ sender: UIButton) {
        popover?.dismiss()
        if let tag = popover?.tag, tag == sender.tag {
            popover?.tag = -1
            return
        }
        popover = nil
        resetTagSearch()
        searchTagTextField.becomeFirstResponder()
        let options = [
            .type(.up),
            .cornerRadius(5),
            .animationIn(0.3),
            .blackOverlayColor(UIColor.lightGray.withAlphaComponent(0.3)),
            .arrowSize(CGSize.init(width: 10, height: 10))
            ] as [PopoverOption]
        popover = Popover(options: options, showHandler: nil, dismissHandler: nil)
        categoryView.frame = CGRect.init(x: 0, y: 0, width: 300, height: 200)
        popover?.show(categoryView, fromView: sender)
        weak var weakSelf = self
        popover?.willDismissHandler = {
            weakSelf?.statmentTextView.becomeFirstResponder()
        }
        popover?.tag = sender.tag
        if hashtags == nil {
            requestFetchSubCategory()
        }
    }
    
    @IBAction func addDuration(_ sender: UIButton) {
        popover?.dismiss()
        if let tag = popover?.tag, tag == sender.tag {
            popover?.tag = -1
            return
        }
        popover = nil
        let options = [
            .type(.up),
            .cornerRadius(5),
            .animationIn(0.3),
            .blackOverlayColor(UIColor.lightGray.withAlphaComponent(0.3)),
            .arrowSize(CGSize.init(width: 10, height: 10))
            ] as [PopoverOption]
        popover = Popover(options: options, showHandler: nil, dismissHandler: nil)
        popover?.tag = sender.tag
        postUrgencyView.frame = CGRect.init(x: 0, y: 0, width: 300, height: 200)
        popover?.show(postUrgencyView, fromView: sender)
    }
    
    
    @IBAction func didTapOnEmptyArea(_ sender: Any) {
        view.endEditing(true)
    }
    
    @IBAction func selectRatingForPost(_ sender: UIButton) {
        setRating(with: sender.tag)
    }
    
    @IBAction func removeImage(_ sender: UIButton) {
        // Remove attachment
        if selectedImages!.count > sender.tag {
            selectedImages?.remove(at: sender.tag)
            let indexPath = IndexPath.init(item: sender.tag, section: 0)
            imageCollectionView.deleteItems(at: [indexPath])
        }
    }
    
    @IBAction func textFieldDidChange(_ sender: UITextField) {
        if let categories = hashtags {
            if let text = sender.text?.trimmingCharacters(in: .whitespaces), !text.isEmpty {
                // Show suggested tags
                tagsCollectionView.removeAllTags()
                tagsCollectionView.alignment = .left
                let filteredArray = categories.filter { $0.starts(with: text)}
                if filteredArray.count > 0 {
                    tagsCollectionView.addTags(filteredArray, with: textTagConfig)
                    setSelectedTags(for: filteredArray)
                }
            }
            else {
                // Show all tags
                resetTagSearch()
            }
        }
    }
    
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
    }
    
    private func dissmissController () {
        if(selectedStatement != nil) {
            let rootViewController = (UIApplication.shared.delegate as! AppDelegate).window?.rootViewController as! UINavigationController
            rootViewController.popToViewController(rootViewController.viewControllers[rootViewController.viewControllers.count - 2], animated: true)
        }
        dismiss(animated: true) {
            
        }
    }
    
}

extension PostStatementViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 83
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableViewCell = tableView.dequeueReusableCell(withIdentifier: ReusableIdentifier.postUrgencyCell, for: indexPath) as! PostUrgencyTableViewCell
        if let urgency = PostUrgency(rawValue: indexPath.row) {
            let (title, subtitle, duration) = urgency.description()
            tableViewCell.urgencyTitleLabel.text    = title
            tableViewCell.urgencySubTitleLabel.text = subtitle
            tableViewCell.urgencyValidDuration.text = duration
        }
        tableViewCell.accessoryType = selectedPriority.rawValue == indexPath.row ? .checkmark : .none
        return tableViewCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let earlierSelectedCell = tableView.cellForRow(at: IndexPath.init(row: selectedPriority.rawValue, section: 0)) {
            earlierSelectedCell.accessoryType = .none
        }
        let tableViewCell = tableView.cellForRow(at: indexPath) as! PostUrgencyTableViewCell
        tableViewCell.accessoryType = .checkmark
        selectedPriority = PostUrgency(rawValue: indexPath.row)!
        priorityLabel.text = selectedPriority.description().0
        priorityLabel.isHidden    = false
    }
}

extension PostStatementViewController: PostStatmentAccessoryDelegate, UITextViewDelegate, UITextFieldDelegate {
    
    // MARK: - Keyboard Accessory Delegate
    
    func didSelect(post accessory: PostStatmentAccessory, sender button: UIButton, action type: AttachmentAccesoryType) {
        // Keyboard accesory action detected
        switch type {
        case .image:
            addImage(button)
        case .category:
            addCategories(button)
        case .priority:
            addDuration(button)
        case .rating:
            selectRating(button)
        case .post:
            if selectedStatement == nil {
                postStatement(button)
            }
            else {
                popover?.dismiss()
                view.endEditing(true)
            }
        }
    }
    
    // MARK: - TextView Delegate
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            postStatementButton.alpha                   = 0.5
            postStatementButton.isEnabled               = false
            placeholderLabel.isHidden                   = false
            accessoryView.postStatementButton.alpha     = 0.5
            accessoryView.postStatementButton.isEnabled = false
            
        }
        else {
            postStatementButton.alpha                   = 1.0
            postStatementButton.isEnabled               = true
            placeholderLabel.isHidden                   = true
            accessoryView.postStatementButton.alpha     = 1.0
            accessoryView.postStatementButton.isEnabled = true
        }
    }
    
    // MARK: - TextField Delegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Continue Editing Problem Statment
        resetTagSearch()
        popover?.dismiss()
        statmentTextView.becomeFirstResponder()
        statmentTextView.text = statmentTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        return true
    }
    
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return true
    }
    
    // MARK: - Keyboard Notification
    
    @objc func keyboardWillShow(notification: NSNotification) {
        placeholderLabel.numberOfLines = 1
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if !hasKeyboardLayoutApplied {
                hasKeyboardLayoutApplied = true
                let padding:CGFloat = 10
                let containerViewBottomSpace = self.view.frame.size.height - (containerView.frame.origin.y + containerView.frame.size.height)
                let effectiveInset = keyboardSize.height - containerViewBottomSpace + padding
                textViewHeightConstraint.constant -= effectiveInset
            }
            textViewHeightConstraint.priority = UILayoutPriority(rawValue: 900)
            UIView.animate(withDuration: 0.5) {
                self.containerView.layoutIfNeeded()
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        placeholderLabel.numberOfLines = 0
        textViewHeightConstraint.priority = UILayoutPriority(rawValue: 500)
        UIView.animate(withDuration: 0.5) {
            self.containerView.layoutIfNeeded()
        }
    }
    
}

// MARK: - Attachment Work

extension PostStatementViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
   
    // MARK: - UICollectionView Datasource and Delegate
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selectedImages?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let imageViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: ReusableIdentifier.selectImageCollectionCell, for: indexPath) as! ImageSelectionCollectionViewCell
        imageViewCell.closeButton.tag = indexPath.row
        imageViewCell.imageView.image = selectedImages?[indexPath.row]
        return imageViewCell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize.init(width: 80, height: 80)
    }
    
    // MARK: - Image Picker
    
    func openPhotos() {
        // Open camera or photos
        let croppingParameters = CroppingParameters.init(isEnabled: true, allowResizing: true, allowMoving: true)
        weak var weakSelf = self
        let cameraController = CameraViewController.init(croppingParameters: croppingParameters, allowsLibraryAccess: true, allowsSwapCameraOrientation: true, allowVolumeButtonCapture: true) { (image, asset) in
            // Dismiss controller
            weakSelf?.dismiss(animated: true, completion: {
                if let selectedImage = image {
                    // If image was selected
                    weakSelf?.didPickImage(image: selectedImage)
                }
            });
        }
        
        present(cameraController, animated: true) {
            
        }
    }
    
    func didPickImage(image:UIImage) {
        if selectedImages == nil {
            selectedImages = Array()
        }
        selectedImages?.append(image)
        heightConstraintCollectioView.priority = UILayoutPriority.init(rawValue: 500)
        imageCollectionView.layoutIfNeeded()
        imageCollectionView.insertItems(at: [IndexPath.init(item: selectedImages!.count-1, section: 0)])
    }
    
    func showActivity() {
        blurView.isHidden = false
        activityIndicator.startAnimating()
    }
    
    @objc func showCheckMark() {
        checkBoxView.isHidden = false
        checkBoxView.tintColor = UIColor.darkTheme()
        checkBoxView.animationDuration = 2.0
        checkBoxView.stateChangeAnimation = .stroke
        checkBoxView.setCheckState(.checked, animated: true)
        activityIndicator.stopAnimating()
        perform(#selector(closeView), with: nil, afterDelay: 2.0)
    }
    
    @objc func closeView() {
        dissmissController()
    }
}

extension PostStatementViewController: TTGTextTagCollectionViewDelegate {
    // MARK: - Tag selection
    func textTagCollectionView(_ textTagCollectionView: TTGTextTagCollectionView!, didTapTag tagText: String!, at index: UInt, selected: Bool, tagConfig config: TTGTextTagConfig!) {
        if selected, !selectTagsCollectionView.allTags().contains(tagText) {
            selectTagsCollectionView.addTag(tagText, with: textTagConfigSelected)
        }
        else {
            selectTagsCollectionView.removeTag(tagText)
        }
    }
}

extension PostStatementViewController {
    
    // MARK: - Network Request
    
    private func requestFetchSubCategory() {
        // Fetch categories
        subcategoryActivityIndicator.startAnimating()
        let apiURL = APIURL.url(apiEndPoint: String(APIEndPoint.intersts.dropLast()))
        weak var weakSelf = self
        webManager.httpRequest(method: .get, apiURL: apiURL, body: [:], completion: { (response) in
            // Category fetched
            weakSelf?.didFetchSubCategory(with: response)
            weakSelf?.subcategoryActivityIndicator.stopAnimating()
        }) { (error) in
            // Error in fetching category
            weakSelf?.subcategoryActivityIndicator.stopAnimating()
        }
    }
    
    private func updateStatment(with parameters: Dictionary<String, Any>, statement identifier:String, for principal:String, attachment: UIImage?) {
        // Fetch categories
        let apiURL   = APIURL.statementUrl(apiEndPoint: APIEndPoint.updateStatement + identifier)
        weak var weakSelf = self
        webManager.uploadImage(htttpMethod: .put, apiURL: apiURL, parameters: parameters, image: attachment, completion: { (response) in
            // Post created successfully
            weakSelf?.showCheckMark()
        }) { (error) in
            // Error in createing statement
            weakSelf?.activityIndicator.stopAnimating()
            weakSelf?.blurView.isHidden = true
        }
    }
    
    private func postStatment(with parameters: Dictionary<String, Any>, for principal:String, attachment: UIImage?) {
        // Fetch categories
        let endPoint = APIEndPoint.statement(with: principal)
        let apiURL   = APIURL.statementUrl(apiEndPoint: endPoint)
        weak var weakSelf = self
        webManager.uploadImage(htttpMethod: .post, apiURL: apiURL, parameters: parameters, image: attachment, completion: { (response) in
            // Post created successfully
            weakSelf?.showCheckMark()
        }) { (error) in
            // Error in createing statement
            weakSelf?.activityIndicator.stopAnimating()
            weakSelf?.blurView.isHidden = true
        }
    }
    
    // MARK: - Request Completion
    
    private func didFetchSubCategory(with response: Dictionary<String, Any>) {
        // Intialize model from response
        if let subcategories = response[APIKeys.result] as? Array<Dictionary<String, Any>> {
            hashtags = Array()
            for categoryInfo in subcategories {
                if let category = Category.init(with: categoryInfo) {
                    hashtags?.append(category.name)
                    // Add tag
                    tagsCollectionView.addTag(category.name, with: textTagConfig)
                }
            }
            
            // Set selected tags for edit mode
            if selectedStatement != nil, let selectedTags = selectedStatement.tags {
                for selectedTag in selectedTags {
                    if let index = hashtags?.index(of: selectedTag.lowercased()) {
                        tagsCollectionView.setTagAt(UInt(index), selected: true)
                    }
                }
            }
        }
    }
    
}
