//
//  ProfileViewController.swift
//  WWDCScholars
//
//  Created by Andrew Walker on 16/04/2017.
//  Copyright © 2017 WWDCScholars. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import DeckTransition
import CoreLocation
import SafariServices
import MessageUI
import Nuke
import CloudKit
import Agrume

internal final class ProfileViewController: UIViewController {
    
    // MARK: - Internal Properties
    internal var scholarId: CKRecord.ID? = nil
    
    // MARK: - Private Properties
    @IBOutlet private weak var profilePictureImageView: UIImageView!
    @IBOutlet private weak var profilePictureContainerView: UIView?
    @IBOutlet private weak var teamImageView: UIImageView?
    @IBOutlet private weak var teamContainerView: UIView?
    @IBOutlet private weak var nameLabel: UILabel?
    @IBOutlet private weak var locationLabel: UILabel?
    @IBOutlet private weak var ageTitleLabel: UILabel?
    @IBOutlet private weak var ageContentLabel: UILabel?
    @IBOutlet private weak var countryTitleLabel: UILabel?
    @IBOutlet private weak var countryContentLabel: UILabel?
    @IBOutlet private weak var batchTitleLabel: UILabel?
    @IBOutlet private weak var batchContentLabel: UILabel?
    @IBOutlet private weak var bioLabel: UILabel?
    @IBOutlet private weak var bioLabelHeightConstraint: NSLayoutConstraint?
    @IBOutlet private weak var socialAccountsStackView: UIStackView?
    @IBOutlet private weak var savedButton: UIButton!
    
    private let bioLabelHeightConstraintUpdateValue: CGFloat = 1.0
    
    private var scholar: Scholar? = nil
    private var batch: WWDCYearInfo? = nil
    private var profileSocialAccountsFactory: ProfileSocialAccountsFactory?
    
    // MARK: - File Private Properties
    
    @IBOutlet fileprivate weak var mapView: MKMapView?
    
    fileprivate var mapViewHeight: CGFloat = 0.0
    
    // MARK: - Lifecycle
    
    internal override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let _ = scholarId else {
            print ("ScholarID is nil")
            return
        }
        
        self.styleUI()
        self.configureUI()
        self.loadScholarData()
        
    }
    
    internal override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.mapViewHeight = self.mapView?.frame.height ?? 0.0
        
        self.configureBioLabel()
    }
    
    // MARK: - UI
    
    private func styleUI() {
        self.view.applyBackgroundStyle()
        
        self.nameLabel?.applyDetailHeaderTitleStyle()
        self.locationLabel?.applyDetailContentStyle()
        self.ageTitleLabel?.applyDetailTitleStyle()
        self.ageContentLabel?.applyDetailContentStyle()
        self.countryTitleLabel?.applyDetailTitleStyle()
        self.countryContentLabel?.applyDetailContentStyle()
        self.batchTitleLabel?.applyDetailTitleStyle()
        self.batchContentLabel?.applyDetailContentStyle()
        self.bioLabel?.applyDetailContentStyle()
        
        self.profilePictureContainerView?.roundCorners()
        self.teamContainerView?.roundCorners()
        
        self.teamImageView?.roundCorners()
        
        self.profilePictureImageView?.roundCorners()
        
        self.profilePictureImageView?.tintColor = .backgroundElementGray
        self.profilePictureImageView?.contentMode = .center
        
        self.savedButton.setImage(UIImage(named: "Saved")?.tinted(with: .scholarsPurple), for: .normal)
    }
    
    private func configureUI() {
        self.title = "Profile"
        
        self.mapView?.isUserInteractionEnabled = false
        self.countryTitleLabel?.text = "Country"
        self.batchTitleLabel?.text = "Attended"
        self.ageTitleLabel?.text = "Age"

        self.nameLabel?.text = ""
        self.locationLabel?.text = ""
        self.ageContentLabel?.text = ""
        self.countryContentLabel?.text = ""
        self.batchContentLabel?.text = ""
        self.bioLabel?.text = ""
        
        self.profilePictureImageView?.image = UIImage.loading
        
        configureTeamImageView()
    }
    
    private func configureTeamImageView(){
        if self.scholar?.fullName == "Sam Eckert" ||
            self.scholar?.fullName == "Moritz Sternemann" ||
            self.scholar?.fullName == "Andrew Walker" ||
            self.scholar?.fullName == "Matthijs Logemann" {
            self.teamContainerView?.isHidden = false
        }else{
            self.teamContainerView?.isHidden = true
        }
    }
    
    private func configureBioLabel() {
        let font = self.bioLabel?.font
        let width = self.bioLabel?.frame.width ?? 0.0
        let height = self.scholar?.biography?.height(for: width, font: font) ?? 0
        self.bioLabelHeightConstraint?.constant = height + self.bioLabelHeightConstraintUpdateValue
    }
    
    @IBAction func profilePicturePressed(_ sender: Any) {
        let agrume = Agrume(image: (profilePictureImageView?.image!)!)
        agrume.show(from: self)
    }
    
    @IBAction func savedButtonPressed(_ sender: Any) {
        
    }
    
    // MARK: - Private Functions
    
    private func loadScholarData() {
        DispatchQueue.init(label: "ScholarLoading").async {
            self.scholar = CKDataController.shared.scholar(for: self.scholarId!)
            
            DispatchQueue.main.async {
                self.populateHeaderContent()
                self.populateBasicInfoContent()
                self.populateBioContent()
                self.configureMapView()
                
                if let profileURL = self.scholar?.profilePicture?.fileURL{
                    Nuke.loadImage(with: profileURL, into: self.profilePictureImageView!)
                }
 
                self.profilePictureImageView?.contentMode = .scaleAspectFill
                
                if let socialMedia = self.scholar?.socialMedia?.recordID{
                    print("socialMedia is \(socialMedia)")
                    
                    CloudKitManager.shared.loadSocialMedia(with: socialMedia, recordFetched: { socialMedia in
                        self.profileSocialAccountsFactory = ProfileSocialAccountsFactory(socialMedia: socialMedia)
                        DispatchQueue.main.async {
                            self.populateSocialAccountsContent()
                        }
                    }, completion: nil)
                }else{
                    print("No socialMediaID")
                }
            }
        }
    }
    
    private func configureMapView() {
        guard let scholar = scholar else {
            return
        }
        
        self.mapView?.setCenter(scholar.location.coordinate, animated: false)
    }
    
    private func populateHeaderContent() {
        guard let scholar = scholar else {
            return
        }
        
        self.nameLabel?.text = scholar.fullName
        
        let geocoder = CLGeocoder.init()
        geocoder.reverseGeocodeLocation(scholar.location, completionHandler: { placemarks,err in
            //todo: error handling?
            
            var placeMark: CLPlacemark!
            placeMark = placemarks?[0]
            
            let city = placeMark.locality ?? ""
            
            let country = placeMark.country ?? ""
            
            DispatchQueue.main.async {
                self.locationLabel?.text = "\(city), \(country)"
                self.countryContentLabel?.text = country
            }
        })
    }
    
    private func populateBasicInfoContent() {
        guard let scholar = scholar else {
            return
        }
        
        self.ageContentLabel?.text = "\(scholar.birthday?.age ?? 18)"
        
        var years = [String]()
        for yearInfo in scholar.wwdcYears ?? []{
            years.append(yearInfo.recordID.recordName)
        }
        
        self.batchContentLabel?.text = years.map { (string) -> String in
            let year = String(string.split(separator: " ").last ?? "")
            return "'" + String(year[2...])
        }.joined(separator: ", ")
        
    }
    
    private func populateBioContent() {
        guard let scholar = scholar else {
            return
        }
        
        self.bioLabel?.text = scholar.biography
    }
    
    private func populateSocialAccountsContent() {
        print("populateSocialAccountsContent")
        let socialAccountButtons = self.profileSocialAccountsFactory?.accountButtons() ?? []
        for button in socialAccountButtons {
            self.socialAccountsStackView?.addArrangedSubview(button)
			button.addTarget(self, action: #selector(self.openURL), for: .touchUpInside)
        }
    }
	
    @objc private func openURL(_ sender: SocialAccountButton){
        guard let urlString = sender.accountDetail else { return }
        guard let type = sender.type else { return }
        
        var vc: UIViewController?
        
        switch(type){
        case .imessage:
            let mvc = MFMessageComposeViewController()
            mvc.recipients = [urlString]
            mvc.messageComposeDelegate = self
            vc = mvc
        case .discord:
            let alert = UIAlertController(title: "Discord", message: urlString, preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Copy", style: .default, handler: { action in
                UIPasteboard.general.string = urlString
            }))
            alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
            
            self.present(alert, animated: true)
        default:
            guard let url = URL(string: urlString) else { return }
            vc = SFSafariViewController(url: url)
        }
        
        if let vc = vc {
            //TODO: change status bar colour when opening urls!
            present(vc, animated: true, completion: nil)
        }
	}
}

extension ProfileViewController: UIScrollViewDelegate, DeckTransitionScrollAssist, HeaderParallaxAssist {
    
    // MARK: - Internal Functions
    
    internal func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.updateDeckTransition(for: scrollView)
        self.updateHeaderParallax(for: scrollView, on: self.mapView, baseHeight: self.mapViewHeight)
    }
}
extension ProfileViewController: MFMessageComposeViewControllerDelegate {
	func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
		dismiss(animated: true, completion: nil)
	}
}
