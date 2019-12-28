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

struct JsAction: Decodable {
    let type: String
    let payload: String
}

struct ImportAction: Decodable {
    let action: JsAction
    let timestamp: Int64
    let type: String
}

struct DevToolsImport<A: Decodable, S: Decodable>: Decodable {

    let actionsById: [String: ImportAction]
    let computedStates: [[String: S]]
    let currentStateIndex: Int
    let nextActionId: Int
    let skippedActionIds: [Int]
    let stagedActionIds: [Int]
}
