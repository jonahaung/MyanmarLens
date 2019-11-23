//
//  MyanmarLensView.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 20/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import UIKit

typealias LanguagePair = (Language, Language)

protocol MyanmarLensViewDelegate: class {
    func myanmarLensView(didtapToggleLanguageButton view: MyanmarLensView)
    func myanmarLensView(didtapLeftButton view: MyanmarLensView)
    func myanmarLensView(didtapRightButton view: MyanmarLensView)
    func myanmarLensView(didTapDoneButton view: MyanmarLensView)
    func myanmarLensView(didTapActionButton view: MyanmarLensView)
}

final class MyanmarLensView: UIView {
    
    weak var delegate: MyanmarLensViewDelegate?
    
    var languagePair = LanguagePair(.none, .none) {
        didSet {
            guard languagePair != oldValue else { return }
            leftButton.setTitle(languagePair.0.description, for: .normal)
            rightButton.setTitle(languagePair.1.description, for: .normal)
        }
    }
    
    private let excludeLayer: CAShapeLayer = {
        $0.fillRule = .evenOdd
        $0.fillColor = UIColor.black.cgColor
        $0.opacity = 0.5
        return $0
    }(CAShapeLayer())
    
    private let doneButton: UIButton = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.tintColor = UIColor.darkText
        return $0
    }(UIButton(type: .close))
    
    private let actionButton: UIButton = {
        $0.setPreferredSymbolConfiguration(.init(pointSize: 40, weight: .heavy), forImageIn: .normal)
        $0.setImage(UIImage(systemName: "circle.fill"), for: .normal)
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(UIButton(type: .custom))
    
    let translatedResultLabel: UILabel = {
        $0.textAlignment = .center
        $0.numberOfLines = 20
        $0.textColor = UIColor.white
        $0.font = UIFont.monoSpacedFont
        return $0
    }(UILabel())
    
    let recognizedLabel: UILabel = {
        $0.textAlignment = .center
        $0.numberOfLines = 20
        $0.textColor = UIColor.systemYellow
        $0.font = UIFont.myanmarFont
        return $0
    }(UILabel())
    
    let previewView: UIView = {
        $0.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return $0
    }(UIView())
    
    let regionOfInterest: UIView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.backgroundColor = .clear
        $0.isUserInteractionEnabled = true
        return $0
    }(UIView())
    
    private let leftButton: UIButton = {
        $0.setTitleColor(UIColor.systemTeal, for: .normal)
        $0.setTitle("LeftButton", for: .normal)
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(UIButton())
    
    private let rightButton: UIButton = {
        $0.setTitleColor(UIColor.systemTeal, for: .normal)
        $0.setTitle("RightButton", for: .normal)
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(UIButton())
    
    private let languageToggleButton: UIButton = {
        $0.setPreferredSymbolConfiguration(.init(font: UIFont.preferredFont(forTextStyle: .title1)), forImageIn: .normal)
        $0.setImage(UIImage(systemName: "arrow.right.arrow.left"), for: .normal)
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(UIButton())
    
    private lazy var languageStackView: UIStackView = {
        $0.axis = .horizontal
        $0.alignment = .center
        $0.distribution = .fill
        $0.spacing = UIStackView.spacingUseSystem
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(UIStackView(arrangedSubviews: [leftButton, languageToggleButton, rightButton]))
    
    private var regionOfInterestWidth: NSLayoutConstraint!
    private var regionOfInterestHeight: NSLayoutConstraint!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

extension MyanmarLensView {
    
    private func setup() {
        
        tintColor = UIColor.systemTeal
    
        let stackView: UIStackView = {
            $0.axis = .vertical
            $0.alignment = .center
            $0.distribution = .fill
            $0.spacing = UIStackView.spacingUseSystem
            $0.translatesAutoresizingMaskIntoConstraints = false
            return $0
        }(UIStackView(arrangedSubviews: [recognizedLabel, translatedResultLabel]))
        
        previewView.frame = bounds
        
        addSubview(previewView)
        previewView.addSubview(regionOfInterest)
        addSubview(doneButton)
        addSubview(languageStackView)
        addSubview(actionButton)
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            regionOfInterest.centerXAnchor.constraint(equalTo: previewView.centerXAnchor),
            regionOfInterest.bottomAnchor.constraint(equalTo: previewView.centerYAnchor, constant: 0),
            
            languageStackView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 40),
            languageStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            
            actionButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            actionButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -40),
            
            stackView.widthAnchor.constraint(equalTo: widthAnchor, constant: 20),
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.topAnchor.constraint(equalTo: centerYAnchor, constant: 20),
            
            doneButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 10),
            doneButton.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor, constant: -10)
        ])
        
        setupRegionOfInterestConstraints()
    
        setupActions()
    }
    
    private func setupRegionOfInterestConstraints() {
        regionOfInterestWidth = regionOfInterest.widthAnchor.constraint(equalToConstant: previewView.bounds.width / 1.5)
        regionOfInterestWidth.isActive = true
        regionOfInterestHeight = regionOfInterest.heightAnchor.constraint(equalToConstant: 50)
        regionOfInterestHeight.isActive = true
        addConstraint(regionOfInterestWidth)
        addConstraint(regionOfInterestHeight)
    }
    
    func fillOpaqueAroundAreaOfInterest() {
        let rect = previewView.bounds
        let areaOfInterestFrame = regionOfInterest.frame
        
        let path = UIBezierPath(rect: rect)
        let areaOfInterestPath = UIBezierPath(roundedRect: areaOfInterestFrame, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: 10, height: 10 ))
        path.append(areaOfInterestPath)
        path.usesEvenOddFillRule = true
        
        excludeLayer.path = path.cgPath
        previewView.layer.addSublayer(excludeLayer)
    }
    
    
    
    private func setupActions() {
        regionOfInterest.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:))))
        doneButton.addTarget(self, action: #selector(didTapDone(_:)), for: .touchUpInside)
        leftButton.addTarget(self, action: #selector(didTapLeftButton(_:)), for: .touchUpInside)
        rightButton.addTarget(self, action: #selector(didTapRightButton(_:)), for: .touchUpInside)
        languageToggleButton.addTarget(self, action: #selector(didTapToggleLanguageButton(_:)), for: .touchUpInside)
        actionButton.addTarget(self, action: #selector(didTapActionButton(_:)), for: .touchUpInside)
    }
    
    @objc private func didTapDone(_ sender: Any) {
        delegate?.myanmarLensView(didTapDoneButton: self)
    }
    
    @objc private func didTapRightButton(_ sender: Any) {
        delegate?.myanmarLensView(didtapRightButton: self)
    }
    
    @objc private func didTapLeftButton(_ sender: Any) {
        delegate?.myanmarLensView(didtapLeftButton: self)
    }
    
    @objc private func didTapToggleLanguageButton(_ sender: Any) {
        delegate?.myanmarLensView(didtapToggleLanguageButton: self)
    }
    
    @objc private func didTapActionButton(_ sender: Any) {
        SoundManager.playSound(tone: .Tock)
        recognizedLabel.text = nil
        translatedResultLabel.text = nil
        delegate?.myanmarLensView(didTapActionButton: self)
    }
    
    func setActionButtonImage(withSystemName name: String) {
        actionButton.setImage(UIImage(systemName: name), for: .normal)
    }
    @objc private func handlePan(_ sender: UIPanGestureRecognizer) {
        let translate = sender.translation(in: regionOfInterest)
        
        UIView.animate(withDuration: 0) {
            self.regionOfInterestWidth.constant += translate.x
            self.regionOfInterestHeight.constant += translate.y
        }
        
        sender.setTranslation(.zero, in: regionOfInterest)
        setNeedsLayout()
        layoutIfNeeded()
    }
}
