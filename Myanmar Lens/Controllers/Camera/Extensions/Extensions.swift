//
//  Extensions.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 20/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import UIKit

extension Collection where Indices.Iterator.Element == Index {
    subscript (exist index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension UIApplication {
    
    class func topViewController(_ viewController: UIViewController? = SceneDelegate.sharedInstance?.window?.rootViewController) -> UIViewController? {
        if let nav = viewController as? UINavigationController {
            return topViewController(nav.visibleViewController)
        }
        if let tab = viewController as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(selected)
            }
        }
        if let presented = viewController?.presentedViewController {
            return topViewController(presented)
        }
        
        return viewController
    }
}

extension UIFont {
    
    static let myanmarFont = UIFont(name:"MyanmarSansPro", size: 35)!
    static let engFont = UIFont.systemFont(ofSize: UIFont.labelFontSize, weight: .regular)
    static let myanmarFontBold = UIFontMetrics.default.scaledFont(for: UIFont(name: "MyanmarPhetsot", size: 35)!)
    
    static var monoSpacedFont: UIFont {
        let defaultFontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
        let fontDescriptor = defaultFontDescriptor.withSymbolicTraits(.traitMonoSpace)
        fontDescriptor?.withDesign(.monospaced)
        let font: UIFont

        if let fontDescriptor = fontDescriptor {
            font = UIFont(descriptor: fontDescriptor, size: 22)
        } else {
            font = UIFont.monospacedSystemFont(ofSize: 22, weight: .medium)
        }

        return font
    }
    
}

extension CGImage {
    var uiImage: UIImage { return UIImage(cgImage: self, scale: UIScreen.main.scale, orientation: .up)}
}

//extension UIImage {
//    var greysCaled: UIImage {
//
//        let saturationFilter = Luminance()
//        //        let adaptive = AdaptiveThreshold()
//        //        adaptive.blurRadiusInPixels = 15
//
//        return self.filterWithOperation(saturationFilter)
//    }
//}
extension UIImage {
    var noir: UIImage? {
        let context = CIContext(options: nil)
        guard let currentFilter = CIFilter(name: "CIPhotoEffectNoir") else { return nil }
        currentFilter.setValue(CIImage(image: self), forKey: kCIInputImageKey)
        if let output = currentFilter.outputImage,
            let cgImage = context.createCGImage(output, from: output.extent) {
            return UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
        }
        return nil
    }
}

extension CGFloat {
    func roundToNearest(_ x : CGFloat) -> CGFloat {
        return x * (self / x).rounded()
    }
    var int: Int { return Int(self)}
}
extension Int {
    var cgFloat: CGFloat { return CGFloat(self) }
}

extension Set {
    var array: [Element] { return Array(self)}
}

extension Double {
    func roundToNearest(_ fractionDigits: Int) -> Double {
        let multiplier = pow(10, Double(fractionDigits))
        return Darwin.round(self * multiplier) / multiplier
    }
}

extension BidirectionalCollection where Iterator.Element: Equatable {
    
    typealias Element = Self.Iterator.Element
    
    func after(_ item: Element, loop: Bool = false) -> Element? {
        if let itemIndex = self.firstIndex(of: item) {
            let lastItem: Bool = (index(after:itemIndex) == endIndex)
            if loop && lastItem {
                return self.first
            } else if lastItem {
                return nil
            } else {
                return self[index(after:itemIndex)]
            }
        }
        return nil
    }
    
    func before(_ item: Element) -> Element? {
        if let itemIndex = self.firstIndex(of: item) {
            guard itemIndex != startIndex else { return nil }
            return self[index(before: itemIndex)]
        }
        return nil
    }
}


extension UIBarButtonItem {
    
    static let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
}

extension Optional where Wrapped == String {
    var string: String {
        return self ?? String()
    }
}


extension Date {
    
    var relativeString: String {
        return AppUtilities.dateFormatter_relative.localizedString(for: self, relativeTo: Date())
    }
    var dateString: String {
        return AppUtilities.dateFormatter.string(from: self)
    }
}




extension UIViewController {
    
    func addDefaultBackgroundImageView() {
        let background = UIImageView(image: UIImage(named: "background"))
        background.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        background.frame = view.bounds
        view.addSubview(background)
    }
}
extension Locale {
    
    static func locale(forCountry countryName: String) -> String? {
        return Locale.isoRegionCodes.filter { self.countryName(fromLocaleCode: $0) == countryName }.first
    }
    
    static func countryName(fromLocaleCode localeCode : String) -> String {
        return (Locale(identifier: "en_UK") as NSLocale).displayName(forKey: .countryCode, value: localeCode) ?? ""
    }
}

extension UIColor {
    func lighter(by percentage:CGFloat = 15.0) -> UIColor {
        return self.adjust(by: abs(percentage) ) ?? self
    }
    
    func darker(by percentage:CGFloat = 12.0) -> UIColor {
        return self.adjust(by: -1 * abs(percentage) ) ?? self
    }
    
    func adjust(by percentage:CGFloat = 30.0) -> UIColor? {
        var r: CGFloat=0, g: CGFloat=0, b: CGFloat=0, a: CGFloat = 0
        if(self.getRed(&r, green: &g, blue: &b, alpha: &a)){
            return UIColor(red: min(r + percentage/100, 1.0),
                           green: min(g + percentage/100, 1.0),
                           blue: min(b + percentage/100, 1.0),
                           alpha: a)
        }else{
            return nil
        }
    }
    
    var isLightColor: Bool {
        var white: CGFloat = 0
        self.getWhite(&white, alpha: nil)
        return white > 0.5
    }
    
    func isBrightColor() -> Bool {
        guard let components = cgColor.components else { return false }
        let brightness = ((components[0] * 299) + (components[1] * 587) + (components[2] * 114)) / 1000
        return brightness < 0.5 ? false : true
    }
    
    func isLight() -> Bool {
        if let colorSpace = self.cgColor.colorSpace {
            if colorSpace.model == .rgb {
                guard let components = cgColor.components, components.count > 2 else {return false}

                let brightness = ((components[0] * 299) + (components[1] * 587) + (components[2] * 114)) / 1000

                return (brightness > 0.5)
            }
            else {
                var white : CGFloat = 0.0

                self.getWhite(&white, alpha: nil)

                return white >= 0.5
            }
        }

        return false
    }
}
