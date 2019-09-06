//
//  OSLogHandle.swift
//  ScenePlayer
//
//  Created by Chiharu Nameki on 2019/09/06.
//  Copyright © 2019 Chiharu Nameki. All rights reserved.
//

import Foundation
import os.signpost

struct OSLogHandle {
    static let behavior = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "Behavior")
    static let userAction = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "UserAction")
    
    // "Points Of Interest" Instrument retrieve logs that handle's category is .pointsOfInterest
    //static let pointsOfInterest = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: .pointsOfInterest)
}
