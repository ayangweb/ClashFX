//
//  SettingTabViewController.swift
//  ClashX Pro
//
//  Created by yicheng on 2022/11/20.
//  Copyright © 2022 west2online. All rights reserved.
//

import Cocoa

class SettingTabViewController: NSTabViewController, NibLoadable {
    override func viewDidLoad() {
        super.viewDidLoad()
        tabStyle = .toolbar
        if #unavailable(macOS 10.11) {
            tabStyle = .segmentedControlOnTop
            for item in tabViewItems {
                item.image = nil
            }
        }
        insertAppearanceTab()
        NSApp.activate(ignoringOtherApps: true)
    }

    private func insertAppearanceTab() {
        let vc = AppearanceSettingViewController()
        let item = NSTabViewItem(viewController: vc)
        item.label = NSLocalizedString("Appearance", comment: "")
        item.image = NSImage(systemSymbolName: "paintbrush", accessibilityDescription: nil)
            ?? NSImage(named: NSImage.colorPanelName)
        insertTabViewItem(item, at: 1)
    }
}
