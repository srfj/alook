//
//  BrowserViewController+AlookMenu.swift
//  Reynard
//
//  Alook 风格菜单的呈现与动作分发。
//

import UIKit
import GeckoView

extension BrowserViewController {
    func presentAlookMenu() {
        let menu = alookMenuController
        guard presentedViewController !== menu else {
            return
        }

        menu.loadViewIfNeeded()

        let title = tabManager.selectedTab?.title ?? ""
        var toggleStates: [AlookMenuAction: Bool] = [:]
        toggleStates[.desktopSite] = isCurrentSiteDesktopMode()

        menu.updateState(title: title, toggleStates: toggleStates)
        menu.onSelect = { [weak self] action in
            self?.handleAlookMenuAction(action)
        }
        present(menu, animated: true)
    }

    private func currentHost() -> String? {
        guard let urlString = tabManager.selectedTab?.url,
              let host = URL(string: urlString)?.host else {
            return nil
        }
        return host
    }

    private func isCurrentSiteDesktopMode() -> Bool {
        guard let host = currentHost(),
              let mode = SiteSettingsStore.shared.settings(for: host)?.websiteMode else {
            return false
        }
        return mode == .desktop
    }

    private func handleAlookMenuAction(_ action: AlookMenuAction) {
        switch action {
        case .bookmarksAndHistory:
            presentLibrary(initialSection: .bookmarks)
        case .downloads:
            presentLibrary(initialSection: .downloads)
        case .settings:
            presentLibrary(initialSection: .settings)
        case .addBookmark:
            presentBookmarkEditor(addToFavorites: false)
        case .refresh:
            guard let session = tabManager.selectedTab?.session, session.isOpen() else {
                return
            }
            session.reload()
        case .share:
            shareCurrentPageFromMenu()
        case .desktopSite:
            toggleDesktopSite()
        case .fullscreen:
            guard let session = tabManager.selectedTab?.session else {
                return
            }
            applyFullscreenState(true, for: session)
        default:
            break
        }
    }

    private func toggleDesktopSite() {
        guard let host = currentHost(),
              let session = tabManager.selectedTab?.session else {
            return
        }
        let isDesktop = SiteSettingsStore.shared.settings(for: host)?.websiteMode == .desktop
        let newMode: SiteWebsiteMode = isDesktop ? .mobile : .desktop
        _ = SiteSettingsStore.shared.setWebsiteMode(newMode, for: host)
        session.reload()
    }

    private func shareCurrentPageFromMenu() {
        guard let tab = tabManager.selectedTab,
              let url = tabManager.shareableURL(for: tab) else {
            return
        }
        let sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.maxY - 1, width: 1, height: 1)
        presentShareSheet(
            items: [url],
            sourceView: view,
            sourceRect: sourceRect,
            applicationActivities: []
        )
    }
}
