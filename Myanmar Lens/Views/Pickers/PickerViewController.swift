//
//  PickerViewController.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 7/12/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import UIKit

extension UIAlertController {
    
    func addPickerView(values: PickerViewViewController.Values,  initialSelection: PickerViewViewController.Index? = nil, action: PickerViewViewController.Action?) {
        let pickerView = PickerViewViewController(values: values, initialSelection: initialSelection, action: action)
        set(vc: pickerView, height: 216)
    }
}

final class PickerViewViewController: UIViewController {
    
    typealias Values = [[String]]
    typealias Index = (column: Int, row: Int)
    typealias Action = (_ vc: UIViewController, _ picker: UIPickerView, _ index: Index, _ values: Values) -> ()
    
    private var action: Action?
    private var values: Values = [[]]
    private var initialSelection: Index?
    
    private let pickerView: UIPickerView = {
        return $0
    }(UIPickerView())
    
    init(values: Values, initialSelection: Index? = nil, action: Action?) {
        super.init(nibName: nil, bundle: nil)
        self.values = values
        self.initialSelection = initialSelection
        self.action = action
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("Deinit Pickers")
    }
    
    override func loadView() {
        view = pickerView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        view.backgroundColor = nil
        modalPresentationStyle = .formSheet
        pickerView.dataSource = self
        pickerView.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let initialSelection = initialSelection, values.count > initialSelection.column, values[initialSelection.column].count > initialSelection.row {
            SoundManager.vibrate(vibration: .light)
            pickerView.selectRow(initialSelection.row, inComponent: initialSelection.column, animated: true)
        }
    }
}

extension PickerViewViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return values.count
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return values[component].count
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let language = values[component][row]
        pickerView.subviews[1].isHidden = true
        pickerView.subviews[2].isHidden = true
        return NSAttributedString(string: language, attributes: [.foregroundColor: UIColor.systemYellow, .font: UIFont.monoSpacedFont])
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        action?(self, pickerView, Index(column: component, row: row), values)
    }
}

