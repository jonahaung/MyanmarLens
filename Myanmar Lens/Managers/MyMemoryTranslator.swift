//
//  MyMemoryTranslator.swift
//  mMsgr
//
//  Created by Aung Ko Min on 21/10/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import Foundation
import CoreData

class MyMemoryTranslation {
    
    static let shared = MyMemoryTranslation()
    
    struct API {
        static let base = "https://api.mymemory.translated.net/get?"
    
        struct translate {
            static let method = "GET"
            static let url = API.base
        }
    
    }
    
    private let session = URLSession(configuration: .default)
    private lazy var context = PersistanceManager.shared.container.newBackgroundContext()
    
    private var wifiiAddress: String?
    
    init() {
        wifiiAddress = getWiFiAddress()
    }
    func translate(text: String, from: String, to: String, _ completion: @escaping ((_ text: String?, _ error: Error?) -> Void)) {
        
        if let existing = existing(text) {
            completion(existing, nil)
            return
        }
        guard var urlComponents = URLComponents(string: API.translate.url) else {
            completion(nil, nil)
            return
        }
        let pair = "\(from)|\(to)"
        
        var queryItems = [URLQueryItem]()
        queryItems.append(URLQueryItem(name: "q", value: text))
        queryItems.append(URLQueryItem(name: "langpair", value: pair))
        queryItems.append(URLQueryItem(name: "mt", value: "1"))
        if let ip = wifiiAddress {
            queryItems.append(URLQueryItem(name: "ip", value: ip))
        }
        urlComponents.queryItems = queryItems
    
        guard let url = urlComponents.url else {
            completion(nil, nil)
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
                
                completion(nil, nil)
                return
            }
            let trimmed = translated.exclude(in: .removingCharacters)
            self.save(text, trimmed)
            completion(trimmed, nil)
        }
        task.resume()
    }
    
    private func getWiFiAddress() -> String? {
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
    
    private func existing(_ text: String) -> String? {
        let request: NSFetchRequest<TranslatePair> = TranslatePair.fetchRequest()
        request.predicate = NSPredicate(format: "from ==[c] %@", text)
        request.fetchLimit = 1
        request.propertiesToFetch = ["to"]
        do {
            return try context.fetch(request).first?.to
        }catch {
            return nil
        }
    }
    
    private func save(_ from: String, _ to: String) {
        let x = TranslatePair(context: context)
        x.from = from
        x.to = to
        do {
            try context.save()
        }catch {
            print(error)
        }
    }
}
