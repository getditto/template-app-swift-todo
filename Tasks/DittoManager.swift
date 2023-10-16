//
//  DittoManager.swift
//  Tasks
//
//  Created by Rae McKelvey on 11/23/22.
//

import Foundation
import DittoSwift


class DittoManager {
    
    var ditto: Ditto
    
    static var shared = DittoManager()
    
    init() {
        self.ditto = Ditto(
            identity: .onlinePlayground(
                appID: "YOUR_APP_ID",
                token: "YOUR_TOKEN"
            )
        )
    }
    
    
}
