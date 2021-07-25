//
//  HttpClient.swift
//  WebRTCapp
//
//  Created by 5/30/21.
//

import Foundation

class HttpClient {
    
    static private func getRequest(_ urlString: String) -> URLRequest {
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.addValue("Basic T1BFTlZJRFVBUFA6TVlfU0VDUkVU", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        return request
    }
    static func getToken(forSession session: String, handler: @escaping (_ token: String) -> Void) {
        var request = getRequest("https://demos.openvidu.io/api/sessions")
        let json = "{\"customSessionId\": \"\(session)\"}"
        request.httpBody = json.data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data, error == nil else {
                print("error=\(String(describing: error))")
                handler("")
            return
         }
           if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode == 409 {
            getToken(forSessionId: session) { (token) in
                    handler(token)
                }
           } else {
            let sessionID = parseJSONString(data)
              getToken(forSessionId: sessionID) { (token) in
                    handler(token)
                }
            }
        }
        task.resume()
    }
    
    private static func getToken(forSessionId sessionId: String, handler: @escaping (_ token: String) -> Void ) {
        var request = getRequest("https://demos.openvidu.io/api/tokens")
        request.httpMethod = "POST"
        let json = "{\"session\": \"" + sessionId + "\"}"
        request.httpBody = json.data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data, error == nil else {
               print("error=\(String(describing: error))")
               handler("")
               return
           }             
           let responseString = String(data: data, encoding: .utf8)
           let jsonData = responseString?.data(using: .utf8)!
            do {
                  let jsonArray = try JSONSerialization.jsonObject(with: jsonData!, options : .allowFragments) as? Dictionary<String,Any>
                  if jsonArray?["token"] != nil, let token = jsonArray?["token"] as? String {
                     handler(token)
                    print("HttpClient success: sessionId- \(sessionId) and TokenId- \(token)")
                  }
              } catch let error as NSError {
                  print(error)
                  handler("")
              }
        }
        task.resume()
    }
    
    private static func parseJSONString(_ data: Data) -> String {
        let responseString = String(data: data, encoding: .utf8)!
        let jsonData = responseString.data(using: .utf8)!
        do {
          if let json = try JSONSerialization.jsonObject(with: jsonData, options : .allowFragments) as? [String: Any],
            let sessionId = json["id"] as? String {
              return sessionId
          } else {
               print("JSONSerialization: session id not found")
            return ""
          }
        } catch let error as NSError {
            print(error)
        }
        return ""
    }
}
