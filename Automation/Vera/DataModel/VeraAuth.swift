//
//  Auth.swift
//  Vera
//
//  Created by Scott Gruby on 12/11/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import Foundation

class VeraAuth: CustomStringConvertible, Decodable {

    var authToken: String?
    var authSigToken: String?
    var serverAccount: String?
    var account: String?

    private enum CodingKeys: String, CodingKey {
        case authToken = "Identity"
        case authSigToken = "IdentitySignature"
        case serverAccount = "Server_Account"
        case account = "PK_Account"
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.authToken = try? container.decode(String.self, forKey: .authToken)
        self.authSigToken = try? container.decode(String.self, forKey: .authSigToken)
        self.serverAccount = try? container.decode(String.self, forKey: .serverAccount)
        self.account = try? container.decode(String.self, forKey: .account)
        if self.account == nil {
            if let accountNumber = try? container.decode(Int.self, forKey: .account) {
                self.account = "\(accountNumber)"
            }
        }
    }

    var description: String {
        var desc: String = "AuthToken: "
        if authToken != nil {
            desc += authToken!
        }

        desc += "\nAuthSigToken: \n"

        if authSigToken != nil {
            desc += authSigToken!
        }

        desc += "\nServerAccount: \n"
        if serverAccount != nil {
            desc += serverAccount!
        }

        desc += "\nAccount: \n"
        if account != nil {
            desc += account!
        }

        return desc
    }
}
