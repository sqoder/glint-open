//
//  AppDelegate.swift
//  suqi
//
//  Created for suqi Terminal.
//

import AppKit

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    public func applicationDidFinishLaunching(_ notification: Notification) {
        _ = SuqiWindowManager.shared.createWindow()
    }

    public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag || SuqiWindowManager.shared.windowControllers.isEmpty {
            _ = SuqiWindowManager.shared.createWindow()
        } else if let first = SuqiWindowManager.shared.windowControllers.first {
            first.showWindow()
        }
        return true
    }

    public func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
