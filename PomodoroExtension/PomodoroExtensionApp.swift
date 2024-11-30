//
//  PomodoroExtensionApp.swift
//  PomodoroExtension
//
//  Created by Marwa Bouabid on 11/30/24.
//

import Cocoa
import SwiftUI
import UserNotifications

@main
struct PomodoroExtensionApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
                if let error = error {
                    print("Notification permission request failed: \(error.localizedDescription)")
                }
            }
        }

        var body: some Scene {
            Settings {
                EmptyView()
            }
        }
    }

    class AppDelegate: NSObject, NSApplicationDelegate {
        var statusItem: NSStatusItem?
        var popover: NSPopover!
        var popoverWindow: NSWindow?

        func applicationDidFinishLaunching(_ notification: Notification) {
            // Setup the menu bar item
            statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            if let button = statusItem?.button {
                button.image = NSImage(systemSymbolName: "clock", accessibilityDescription: "Pomodoro Timer")
                button.action = #selector(togglePopover)
            }

            // Setup the popover
            popover = NSPopover()
            popover.contentSize = NSSize(width: 200, height: 150)
            popover.behavior = .transient
            popover.contentViewController = NSHostingController(rootView: PomodoroTimer())
        }

        @objc func togglePopover() {
            guard let button = statusItem?.button else { return }
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
