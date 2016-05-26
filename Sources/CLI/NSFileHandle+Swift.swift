//
//  NSFileHandle+Swift.swift
//  LedgerTools
//
//  Created by Bouke Haarsma on 26-05-16.
//
//

import Foundation

extension NSFileHandle {
    var isatty: Bool {
        return Darwin.isatty(fileDescriptor) != 0
    }
}