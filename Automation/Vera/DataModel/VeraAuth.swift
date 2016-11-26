//
//  Auth.swift
//  Vera
//
//  Created by Scott Gruby on 12/11/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import Foundation
import PMJSON

class VeraAuth: CustomStringConvertible {

    var authToken: String?
    var authSigToken: String?
    var serverAccount: String?
    var account: String?

    init(json: JSON) {
        authToken = json["Identity"]?.string
        authSigToken = json["IdentitySignature"]?.string
        serverAccount = json["Server_Account"]?.string
        account = json["PK_Account"]?.string

        if account == nil {
            if let accountNumber = json["PK_Account"]?.int {
                account = "\(accountNumber)"
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
