//
//  HTTPManagerDataRequest+Extensions.swift
//  Automation
//
//  Created by Scott Gruby on 9/14/17.
//  Copyright © 2017 Gruby Solutions. All rights reserved.
//

import Foundation
import UIKit
import PMHTTP

public extension HTTPManagerDataRequest {
    /// Returns a new request that parses the data as an image.
    ///
    /// If the image container has multiple images, only the first one is returned.
    ///
    /// - Note: If the server responds with 204 No Content, the parse is skipped and
    ///   `HTTPManagerError.unexpectedNoContent` is returned as the parse result.
    /// - Parameter scale: The scale to use for the resulting image. Defaults to `1`.
    /// - Returns: An `HTTPManagerParseRequest`.
    public func parseAsDecodable<T: Decodable>(type: T.Type) -> HTTPManagerParseRequest<T> {
        let req = parse(using: { (response, data) -> T in
            if let response = response as? HTTPURLResponse, response.statusCode == 204 {
                throw HTTPManagerError.unexpectedNoContent(response: response)
            }

            return try JSONDecoder().decode(T.self, from: data)
        })
        req.expectedContentTypes = ["application/json"]
        return req
    }
}
