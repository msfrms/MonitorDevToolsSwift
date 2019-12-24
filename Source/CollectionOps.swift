//
//  CollectionOps.swift
//  ReduxDevToolsSwift
//
//  Created by Radaev Mikhail on 23/12/2019.
//  Copyright © 2019 msfrms. All rights reserved.
//

import Foundation

internal func + <K, V> (left: [K: V], right: (K, V)) -> [K: V] {
    var dictionary = left
    dictionary[right.0] = right.1
    return dictionary
}
