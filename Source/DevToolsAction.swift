//
//  Action.swift
//  DevToolsSwift
//
//  Created by Radaev Mikhail on 23/12/2019.
//  Copyright © 2019 msfrms. All rights reserved.
//

import Foundation

//https://github.com/zalmoxisus/mobx-remotedev/blob/master/src/monitorActions.js
internal enum MonitorTypes: String, Codable {
    case action = "ACTION"
    case dispatch = "DISPATCH"
    case `import` = "IMPORT"
    case `init` = "INIT"
    case start = "START"
    case stop = "STOP"
    case undefined = "undefined"
}

public struct DevToolsAction<A: Encodable, S: Encodable> {
    public let title: String
    public let action: A
    public let state: S

    public init(title: String, action: A, state: S) {
        self.title = title
        self.action = action
        self.state = state
    }
}

extension DevToolsAction {

    internal var toDictionary: [String: Any] {
        let encoder = JSONEncoder()
        let state = (try? encoder.encode(self.state)).flatMap { String(data: $0, encoding: .utf8) }
        let action = (try? encoder.encode(self.action)).flatMap { String(data: $0, encoding: .utf8) }
        return [
            "type": MonitorTypes.action.rawValue,
            "action": [
                "type": title,
                "payload": action ?? MonitorTypes.undefined.rawValue
            ],
            "payload": state ?? MonitorTypes.undefined.rawValue,
        ]
    }
}

public struct DevToolsImport<A: Decodable, S: Decodable>: Decodable {

    public let actionsById: [String: A]
    public let computedStates: [S]
    public let currentStateIndex: Int
    public let nextActionId: Int
    public let skippedActionIds: [Int]
    public let stagedActionIds: [Int]
}
