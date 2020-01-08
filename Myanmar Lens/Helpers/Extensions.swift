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
extension UIColor {
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
extension UIFont {
    
    static let myanmarFont = UIFont(name:"MyanmarSansPro", size: UIFont.labelFontSize)!
    static let engFont = UIFont.systemFont(ofSize: UIFont.labelFontSize, weight: .regular)
    static let myanmarFontBold = UIFontMetrics.default.scaledFont(for: UIFont(name: "MyanmarPhetsot", size: 25)!)
    
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
extension UIFont {
    func sizeOfString (string: String, constrainedToWidth width: CGFloat) -> CGSize {
        let attributes = [NSAttributedString.Key.font: self.fontName,]
        let attString = NSAttributedString(string: string,attributes: attributes)
        let framesetter = CTFramesetterCreateWithAttributedString(attString)
        return CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRange(location: 0,length: 0), nil, CGSize(width: width, height: .greatestFiniteMagnitude), nil)
    }
}

extension CGImage {
    var uiImage: UIImage { return UIImage(cgImage: self)}
}

extension UIImage {
    var greysCaled: UIImage {
        
        let saturationFilter = Luminance()
        //        let adaptive = AdaptiveThreshold()
        //        adaptive.blurRadiusInPixels = 15
        
        return self.filterWithOperation(saturationFilter)
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

extension CGAffineTransform {
    func scale() -> Double {
        return sqrt(Double(self.a * self.a + self.c * self.c))
    }
    
    func translation() -> CGPoint {
        return CGPoint(x: self.tx, y: self.ty)
    }
}
extension UIImage {
    // 2
    func scaledImage(_ maxDimension: CGFloat) -> UIImage? {
        // 3
        var scaledSize = CGSize(width: maxDimension, height: maxDimension)
        // 4
        if size.width > size.height {
            scaledSize.height = size.height / size.width * scaledSize.width
        } else {
            scaledSize.width = size.width / size.height * scaledSize.height
        }
        // 5
        UIGraphicsBeginImageContext(scaledSize)
        draw(in: CGRect(origin: .zero, size: scaledSize))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        // 6
        return scaledImage
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
