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
        case dispatch = "DISPATCH"
    }

    public enum Dispatch {
        case action(String)
        case jumpToAction(String)
        case jumpToState(String)
        case `import`(String)
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

    public func send<A: Encodable, S: Encodable>(action: Action<A, S>) {
        guard client.isConnected() else { return }
        let payload = action.toDictionary + ("id", id)
        client.emit(eventName: "log", data: payload as AnyObject)
    }

    private func dispatch(message: [String: Any]) -> Dispatch {
        guard let action = message["action"] as? [String: Any] else { return .none }

        let state = message["state"] as? String ?? ""
        let type = action["type"] as? String ?? ""

        switch ControlTypes(rawValue: type) {
        case .jumpToState?:
            return .jumpToState(state)

        case .jumpToAction?:
            return .jumpToAction(state)

        default:
            return .none
        }
    }

    public func observe(callback: @escaping (Dispatch, Monitor) -> Void) {
        client.on(eventName: "sc-\(self.id)") { channel, message in
            guard let msg = message as? [String: Any] else { return }
            guard let type = msg["type"] as? String else { return }

            switch Types(rawValue: type) {
            case .action?:
                let payload = msg["action"] as? String ?? ""
                callback(.action(payload), self)

            case .dispatch?:
                callback(self.dispatch(message: msg), self)

            default:
                break
            }
        }
    }
}
