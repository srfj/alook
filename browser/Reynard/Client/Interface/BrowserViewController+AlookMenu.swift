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
        let menu = AlookMenuViewController()
        menu.currentPageTitle = tabManager.selectedTab?.title ?? ""
        menu.onSelect = { [weak self] action in
            self?.handleAlookMenuAction(action)
        }
        present(menu, animated: true)
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
        default:
            break
        }
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
