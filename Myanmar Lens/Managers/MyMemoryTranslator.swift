//
//  MyMemoryTranslator.swift
//  mMsgr
//
//  Created by Aung Ko Min on 21/10/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import Foundation
import CoreData
import NaturalLanguage
struct Translator {
    
    static let shared = Translator()
//    lazy var context = PersistanceManager.shared.container.newBackgroundContext()
    
    struct API {
        static let base = "https://api.mymemory.translated.net/get?"
    
        struct translate {
            static let method = "GET"
            static let url = API.base
        }
    
    }
    
    private let session = URLSession(configuration: .default)
 
    init() {
        
    }
    func translate(text: String, from: NLLanguage, to: NLLanguage, wifiiAddress: String?, email: String,  _ completion: @escaping ((_ result: String?, _ error: Error?) -> Void)) {

        guard var urlComponents = URLComponents(string: API.translate.url) else {
            completion(text, nil)
            return
        }
       
        let pair = "\(from.rawValue.trimmed)|\(to.rawValue.trimmed)"
        
        var queryItems = [URLQueryItem]()
        queryItems.append(URLQueryItem(name: "q", value: text.lowercased()))
        queryItems.append(URLQueryItem(name: "langpair", value: pair))
        queryItems.append(URLQueryItem(name: "mt", value: "1"))
        
        if let ip = wifiiAddress {
            queryItems.append(URLQueryItem(name: "ip", value: ip))
        }
        queryItems.append(URLQueryItem(name: "de", value: email))
       
        urlComponents.queryItems = queryItems
    
        guard let url = urlComponents.url else {
            completion(text, nil)
            return
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = API.translate.method
        
        let task = session.dataTask(with: urlRequest) { (data, response, error) in
            guard let data = data, let response = response as? HTTPURLResponse, (200 ..< 300) ~= response.statusCode, error == nil else {
               
                    completion(nil, error)
                    return
            }
            guard
                let string = String(data: data, encoding: .utf8),
                let dataString = string.data(using: .utf8),
                let json = try? JSONSerialization.jsonObject(with: dataString , options: []),
                let dictionary = json as? [String: Any],
                let responseData = dictionary["responseData"] as? NSDictionary,
                let translated = responseData["translatedText"] as? String else {
                
                completion(text, nil)
                return
            }
           
            let lower = translated.lowercased()
            
            guard !lower.isWhitespace else {
                completion(text, nil)
                return
            }
            completion(lower, nil)
            self.save(text, lower, language: to.rawValue)
            
        }
        task.resume()
    }
    
    func getWiFiAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }

                if let interface = ptr?.pointee {
                    let addrFamily = interface.ifa_addr.pointee.sa_family
                    if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                        let name: String = String(cString: interface.ifa_name)
                        if name == "en0" {
                            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                            getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
                            address = String(cString: hostname)
                        }
                    }
                }
                
            }
            freeifaddrs(ifaddr)
        }
        return address
    }

    private func save(_ from: String, _ to: String, language: String) {
        TranslatePair.save(from, to, language: language, date: Date(), isFavourite: false, context: PersistanceManager.shared.container.newBackgroundContext())
    }

}
