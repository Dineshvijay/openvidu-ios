//
//  Helpers.swift
//  VideoChat
//
//  Created by Dinesh on 5/30/21.
//

import Foundation

extension Dictionary {
     func toJsonString() -> String? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: self,
                                                  options: JSONSerialization.WritingOptions())
            return String(data: jsonData, encoding: .utf8)
        } catch _ {
            print ("JSON Failure")
            return nil
        }
    }
}

extension Data {
    func toJSON() -> [String: Any]? {
        do {
            return try JSONSerialization.jsonObject(with: self, options : .allowFragments) as? [String: Any]
        } catch let error as NSError {
            print("Data toJSON error: \(error.localizedDescription)")
            return nil
        }
    }
}
