//
//  Auth.swift
//  Vera
//
//  Created by Scott Gruby on 12/11/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import Foundation
import JSONHelper

open class VeraAuth : Deserializable, CustomStringConvertible {
    
    var authToken:String?
    var authSigToken:String?
    var serverAccount:String?
    var account:String?

    public required init(data: [String: AnyObject]) {
        _ = authToken <-- data["Identity"]
        _ = authSigToken <-- data["IdentitySignature"]
        _ = serverAccount <-- data["Server_Account"]
        _ = account <-- data["PK_Account"]
        if (account == nil) {
            var accountNumber: Int?
            _ = accountNumber <-- data["PK_Account"]
            if (accountNumber != nil) {
                account = "\(accountNumber!)"
            }
        }
    }
    
    open var description: String {
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
