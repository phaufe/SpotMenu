//
//  AppDelegate.swift
//  SpotMenu
//
//  Created by Miklós Kristyán on 02/09/16.
//  Copyright © 2016 KM. All rights reserved.
//

import Cocoa
import Spotify

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {


    let controller: NSWindowController = NSStoryboard(name: "Preferences", bundle: nil).instantiateInitialController() as! NSWindowController
    
    var eventMonitor: EventMonitor?

    let statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
    let popover = NSPopover()
    var timer: Timer?
    
    var initialWidth:CGFloat = 0
    
    let url = URL(string: "https://github.com/kmikiy/SpotMenu")
    let menu = StatusMenu().menu
    
    var hiddenView: NSView = NSView(frame: NSRect(x: 0, y: 0, width: 1, height: 1))
    
    let spotMenuIcon = NSImage(named: "StatusBarButtonImage")
    

    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        UserPreferences.readPrefs()
        
        if let button = statusItem.button {
            if UserPreferences.showSpotMenuIcon {
                button.image = spotMenuIcon
            }
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.action = #selector(AppDelegate.togglePopover(_:))
            button.addSubview(hiddenView)
            updateTitle()
            initialWidth = statusItem.button!.bounds.width
            updateHidden()
        }
        
        popover.contentViewController = ViewController(nibName: "ViewController", bundle: nil)
        //popover.appearance = NSAppearance(named: NSAppearanceNameAqua)
        
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [unowned self] event in
            if self.popover.isShown {
                self.closePopover(event)
            }
        }
        eventMonitor?.start()
        
        timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(AppDelegate.postUpdateNotification), userInfo: nil, repeats: true)
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.updateTitleAndPopover), name: NSNotification.Name(rawValue: InternalNotification.key), object: nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        eventMonitor?.stop()
        NotificationCenter.default.removeObserver(self)
        timer!.invalidate()
    }

    
    func postUpdateNotification(){
        NotificationCenter.default.post(name: Notification.Name(rawValue: InternalNotification.key), object: self)
    }
    
    func updateTitle(){
        statusItem.title = StatusItemBuilder()
            .showTitle(v: UserPreferences.showTitle)
            .showArtist(v: UserPreferences.showArtist)
            .showPlayingIcon(v: UserPreferences.showPlayingIcon)
            .getString()
        
        if let button = statusItem.button {
            if UserPreferences.showSpotMenuIcon {
                button.image = spotMenuIcon
            } else {
                button.image = nil
            }
        }
        
        if (statusItem.title?.characters.count == 0 && statusItem.button != nil ){ //Show the icon regardless of setting if char count == 0
            if let button = statusItem.button {
                button.image = spotMenuIcon
            }
        }

    }
    
    func updateHidden(){
        if UserPreferences.fixPopoverToTheRight {
            hiddenView.frame = NSRect(x: statusItem.button!.bounds.width-1, y: statusItem.button!.bounds.height-1, width: 1, height: 1)
        } else {
            hiddenView.frame = NSRect(x: statusItem.button!.bounds.width-initialWidth/2, y: statusItem.button!.bounds.height-1, width: 1, height: 1)
        }
        statusItem.button!.updateLayer()
    }
    
    func updateTitleAndPopover() {
        updateTitle()
        updateHidden()
    }
    
    

    // MARK: - Popover
    func openPrefs(_ sender: NSMenuItem) {
        controller.showWindow(self)
    }
    
    func openSite(_ sender: NSMenuItem) {
        if let url = url, NSWorkspace.shared().open(url) {
            print("default browser was successfully opened")
        }
    }
    
    func quit(_ sender: NSMenuItem) {
       NSApp.terminate(self)
    }

    func showPopover(_ sender: AnyObject?) {
        initialWidth = statusItem.button!.bounds.width
        updateHidden()
        popover.show(relativeTo: hiddenView.bounds, of: hiddenView, preferredEdge: NSRectEdge.minY)
        eventMonitor?.start()
    }
    
    func closePopover(_ sender: AnyObject?) {
        popover.performClose(sender)
        eventMonitor?.stop()
    }
    
    func togglePopover(_ sender: AnyObject?) {
        let event = NSApp.currentEvent!
        
        if event.type == NSEventType.rightMouseUp {
            if popover.isShown{
                closePopover(sender)
            }
                
            statusItem.menu = menu
            statusItem.popUpMenu(menu)
            
            // This is critical, otherwise clicks won't be processed again
            statusItem.menu = nil
            
        } else {
            statusItem.menu = nil
            if popover.isShown {
                closePopover(sender)
            } else {
                popover.contentViewController = ViewController(nibName: "PopOver", bundle: nil)
                Spotify.startSpotify(hidden: true)
                showPopover(sender)
            }
        }
    }
}

