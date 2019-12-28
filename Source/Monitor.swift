//
//  Monitor.swift
//  DevToolsSwift
//
//  Created by Radaev Mikhail on 23/12/2019.
//  Copyright © 2019 msfrms. All rights reserved.
//

import Foundation
import ScClient

public class Monitor {

    private enum ControlTypes: String {
        case jumpToState = "JUMP_TO_STATE"
        case jumpToAction = "JUMP_TO_ACTION"
        case unknown
    }

    private enum Types: String {
        case action = "ACTION"
        case start = "START"
        case `init` = "INIT"
        case `import` = "IMPORT"
        case dispatch = "DISPATCH"
    }

    public struct Import<A: Decodable, S: Decodable>: Decodable {
        public let actions: [A]
        public let states: [S]
    }

    public enum Dispatch<A: Decodable, S: Decodable> {
        case action(A)
        case jumpToAction(A)
        case jumpToState(S)
        case `import`(Import<A, S>)
        case none
    }

    private let client: ScClient
    private let id: String

    public var onConnected: () -> () = {}
    public var onDisconnected: () -> () = {}

    public init(url: String, clientId: String = "redux-devtools-swift-client", ssl: Bool = false) {
        client = ScClient(url: url)
        client.disableSSLVerification(value: !ssl)
        id = clientId
    }

    public func connect() {
        guard !client.isConnected() else { return }

        client.setBasicListener(
            onConnect: { [unowned self] client in
                self.onConnected()
                client.subscribe(channelName: "sc-\(self.id)")
                client.subscribe(channelName: "respond")
            },
            onConnectError: { [unowned self] client, error in
                self.onDisconnected()
                print("monitor connect error: \(String(describing: error))")
            },
            onDisconnect: { [unowned self] client, error in
                self.onDisconnected()
                print("monitor disconnect error: \(String(describing: error))")
            })

        client.on(eventName: "respond") { [unowned self] channel, message in
            guard channel == "respond" else { return }
            guard let action = message as? [String: Any] else { return }
            guard let type = action["type"] as? String else { return }
            guard type == Types.start.rawValue else { return }

            let initAction =  [
                "type": Types.`init`.rawValue,
                "id": self.id
            ]
            self.client.emit(eventName: "log", data: initAction as AnyObject)
        }

        client.connect()
    }

    public func send<A: Encodable, S: Encodable>(action: DevToolsAction<A, S>) {
        guard client.isConnected() else { return }
        let payload = action.toDictionary + ("id", id)
        client.emit(eventName: "log", data: payload as AnyObject)
    }

    private func dispatch<A: Decodable, S: Decodable>(message: [String: Any]) -> Dispatch<A, S> {
        guard let action = message["action"] as? [String: Any] else { return .none }

        let state = message["state"] as? String ?? ""
        let type = action["type"] as? String ?? ""

        switch ControlTypes(rawValue: type) {
        case .jumpToState?:
            guard let json = state.data(using: .utf8) else { return .none }
            guard let stateObject = try? JSONDecoder().decode(S.self, from: json) else { return .none }
            return .jumpToState(stateObject)

        case .jumpToAction?:
            guard let json = state.data(using: .utf8) else { return .none }
            guard let stateObject = try? JSONDecoder().decode(A.self, from: json) else { return .none }
            return .jumpToAction(stateObject)

        default:
            return .none
        }
    }

    public func observe<A: Decodable, S: Decodable>(callback: @escaping (Dispatch<A, S>) -> Void) {
        client.on(eventName: "sc-\(self.id)") { channel, message in
            guard let msg = message as? [String: Any] else { return }
            guard let type = msg["type"] as? String else { return }

            switch Types(rawValue: type) {
            case .action?:
                guard let payload = msg["action"] as? String else { return }
                guard let json = payload.data(using: .utf8) else { return }
                guard let action = try? JSONDecoder().decode(A.self, from: json) else { return }
                callback(.action(action))

            case .dispatch?:
                callback(self.dispatch(message: msg))

            case .import?:
                guard let state = msg["state"] as? String else { return }
                guard let json = state.data(using: .utf8) else { return }
                guard let devToolsImport = try? JSONDecoder().decode(DevToolsImport<A, S>.self, from: json) else {
                    return
                }
                var actions: [A] = []
                for (index, _) in devToolsImport.computedStates.enumerated() {
                    let actionJson = devToolsImport.actionsById["\(index)"]?.action.payload ?? ""
                    let actionData = actionJson.data(using: .utf8) ?? Data()
                    if let action = try? JSONDecoder().decode(A.self, from: actionData) {
                        actions.append(action)
                    }
                }
                callback(.import(Import<A, S>(
                    actions: actions,
                    states: devToolsImport.computedStates)))

            default:
                break
            }
        }
    }
}
