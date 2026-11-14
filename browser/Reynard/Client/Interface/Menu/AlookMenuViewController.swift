//
//  AlookMenuViewController.swift
//  Reynard
//
//  Alook-style bottom menu: two pages of 4x2 items.
//

import UIKit

enum AlookMenuAction: Int, CaseIterable {
    case bookmarksAndHistory
    case desktopSite
    case downloads
    case nightMode
    case addBookmark
    case refresh
    case share
    case adblock
    case pip
    case fullscreen
    case noImage
    case translate
    case images
    case markAd
    case toolbox
    case settings

    var page: Int {
        return rawValue < 8 ? 0 : 1
    }

    var title: String {
        switch self {
        case .bookmarksAndHistory: return "书签/历史"
        case .desktopSite: return "电脑版"
        case .downloads: return "下载管理"
        case .nightMode: return "夜间模式"
        case .addBookmark: return "添加书签"
        case .refresh: return "刷新"
        case .share: return "分享"
        case .adblock: return "广告过滤"
        case .pip: return "视频悬窗"
        case .fullscreen: return "全屏模式"
        case .noImage: return "无图模式"
        case .translate: return "翻译"
        case .images: return "网页图片"
        case .markAd: return "标记广告"
        case .toolbox: return "工具箱"
        case .settings: return "设置"
        }
    }

    var symbolName: String {
        switch self {
        case .bookmarksAndHistory: return "book"
        case .desktopSite: return "desktopcomputer"
        case .downloads: return "arrow.down.circle"
        case .nightMode: return "moon"
        case .addBookmark: return "bookmark"
        case .refresh: return "arrow.clockwise"
        case .share: return "square.and.arrow.up"
        case .adblock: return "shield.lefthalf.filled"
        case .pip: return "pip"
        case .fullscreen: return "arrow.up.left.and.arrow.down.right"
        case .noImage: return "photo.slash"
        case .translate: return "character.book.closed"
        case .images: return "photo.on.rectangle"
        case .markAd: return "exclamationmark.bubble"
        case .toolbox: return "wrench.and.screwdriver"
        case .settings: return "gearshape"
        }
    }

    /// Items that already have a working implementation behind them.
    var isImplemented: Bool {
        switch self {
        case .bookmarksAndHistory, .downloads, .addBookmark, .refresh, .share, .settings:
            return true
        default:
            return false
        }
    }

    var isToggle: Bool {
        switch self {
        case .nightMode, .adblock, .pip, .fullscreen, .noImage:
            return true
        default:
            return false
        }
    }
}

final class AlookMenuViewController: UIViewController {
    private enum UX {
        static let cardCornerRadius: CGFloat = 20
        static let headerHeight: CGFloat = 52
        static let itemHeight: CGFloat = 92
        static let rowSpacing: CGFloat = 4
        static let columnSpacing: CGFloat = 8
        static let horizontalInset: CGFloat = 16
        static let pagesHeight: CGFloat = 208
        static let cardHeight: CGFloat = 52 + 208 + 44
        static let dismissButtonHeight: CGFloat = 44
        static let iconPointSize: CGFloat = 24
        static let titleFontSize: CGFloat = 11
        static let backdropAlpha: CGFloat = 0.35
    }

    var onSelect: ((AlookMenuAction) -> Void)?
    var toggleStates: [AlookMenuAction: Bool] = [:]
    var currentPageTitle: String = ""

    private let backdropView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.black.withAlphaComponent(UX.backdropAlpha)
        view.alpha = 0
        return view
    }()

    private let cardView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = UX.cardCornerRadius
        view.layer.cornerCurve = .continuous
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textAlignment = .center
        label.text = currentPageTitle
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private lazy var moreButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        button.tintColor = .label
        return button
    }()

    private let pagesScrollView: UIScrollView = {
        let view = UIScrollView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isPagingEnabled = true
        view.showsHorizontalScrollIndicator = false
        view.bounces = false
        return view
    }()

    private lazy var pageControl: UIPageControl = {
        let control = UIPageControl()
        control.translatesAutoresizingMaskIntoConstraints = false
        control.numberOfPages = 2
        control.currentPageIndicatorTintColor = .label
        control.pageIndicatorTintColor = UIColor.label.withAlphaComponent(0.2)
        control.addTarget(self, action: #selector(pageControlChanged), for: .valueChanged)
        return control
    }()

    private lazy var dismissButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        button.tintColor = .secondaryLabel
        button.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        return button
    }()

    private var cardBottomConstraint: NSLayoutConstraint?

    init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        configureSubviews()
        buildPages()
        pagesScrollView.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if cardBottomConstraint?.constant != 0 {
            cardBottomConstraint?.constant = 0
            UIView.animate(withDuration: 0.28, delay: 0, options: [.curveEaseOut]) {
                self.backdropView.alpha = 1
                self.view.layoutIfNeeded()
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cardBottomConstraint?.constant = UX.cardHeight + 60
    }

    // MARK: - Setup

    private func configureSubviews() {
        view.addSubview(backdropView)
        view.addSubview(cardView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(moreButton)
        cardView.addSubview(pagesScrollView)
        cardView.addSubview(pageControl)
        cardView.addSubview(dismissButton)

        let tap = UITapGestureRecognizer(target: self, action: #selector(backdropTapped))
        backdropView.addGestureRecognizer(tap)
        moreButton.addTarget(self, action: #selector(moreTapped), for: .touchUpInside)

        let bottom = cardView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        cardBottomConstraint = bottom

        NSLayoutConstraint.activate([
            backdropView.topAnchor.constraint(equalTo: view.topAnchor),
            backdropView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdropView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backdropView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottom,
            cardView.heightAnchor.constraint(equalToConstant: UX.cardHeight + 34),

            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 56),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -56),

            moreButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            moreButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            moreButton.widthAnchor.constraint(equalToConstant: 32),
            moreButton.heightAnchor.constraint(equalToConstant: 32),

            pagesScrollView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: UX.headerHeight),
            pagesScrollView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: UX.horizontalInset),
            pagesScrollView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -UX.horizontalInset),
            pagesScrollView.heightAnchor.constraint(equalToConstant: UX.pagesHeight),

            pageControl.topAnchor.constraint(equalTo: pagesScrollView.bottomAnchor),
            pageControl.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            pageControl.heightAnchor.constraint(equalToConstant: 20),

            dismissButton.topAnchor.constraint(equalTo: pageControl.bottomAnchor),
            dismissButton.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            dismissButton.widthAnchor.constraint(equalToConstant: 48),
            dismissButton.heightAnchor.constraint(equalToConstant: UX.dismissButtonHeight),
        ])
    }

    private func buildPages() {
        var pageViews: [UIView] = []

        for _ in 0..<2 {
            let page = UIView()
            page.translatesAutoresizingMaskIntoConstraints = false
            pagesScrollView.addSubview(page)
            pageViews.append(page)
        }

        let contentGuide = pagesScrollView.contentLayoutGuide
        let frameGuide = pagesScrollView.frameLayoutGuide

        NSLayoutConstraint.activate([
            pageViews[0].leadingAnchor.constraint(equalTo: contentGuide.leadingAnchor),
            pageViews[0].topAnchor.constraint(equalTo: contentGuide.topAnchor),
            pageViews[0].bottomAnchor.constraint(equalTo: contentGuide.bottomAnchor),
            pageViews[0].widthAnchor.constraint(equalTo: frameGuide.widthAnchor),
            pageViews[0].heightAnchor.constraint(equalTo: frameGuide.heightAnchor),

            pageViews[1].leadingAnchor.constraint(equalTo: pageViews[0].trailingAnchor),
            pageViews[1].topAnchor.constraint(equalTo: contentGuide.topAnchor),
            pageViews[1].bottomAnchor.constraint(equalTo: contentGuide.bottomAnchor),
            pageViews[1].widthAnchor.constraint(equalTo: frameGuide.widthAnchor),
            pageViews[1].heightAnchor.constraint(equalTo: frameGuide.heightAnchor),
            pageViews[1].trailingAnchor.constraint(equalTo: contentGuide.trailingAnchor),
        ])

        for (index, action) in AlookMenuAction.allCases.enumerated() {
            let item = AlookMenuItemView(action: action)
            item.translatesAutoresizingMaskIntoConstraints = false
            item.isOn = toggleStates[action] ?? false
            item.onTap = { [weak self] in
                self?.handleSelection(action)
            }
            item.tag = index
            let page = pageViews[action.page]
            page.addSubview(item)

            let column = index % 4
            let row = (index % 8) / 4
            let itemWidth = (UIScreen.main.bounds.width - UX.horizontalInset * 2 - UX.columnSpacing * 3) / 4

            NSLayoutConstraint.activate([
                item.leadingAnchor.constraint(
                    equalTo: page.leadingAnchor,
                    constant: CGFloat(column) * (itemWidth + UX.columnSpacing)
                ),
                item.topAnchor.constraint(
                    equalTo: page.topAnchor,
                    constant: CGFloat(row) * (UX.itemHeight + UX.rowSpacing) + 4
                ),
                item.widthAnchor.constraint(equalToConstant: itemWidth),
                item.heightAnchor.constraint(equalToConstant: UX.itemHeight),
            ])
        }
    }

    // MARK: - Actions

    private func handleSelection(_ action: AlookMenuAction) {
        guard action.isImplemented else {
            UISelectionFeedbackGenerator().selectionChanged()
            return
        }
        dismiss(animated: true) { [weak self] in
            self?.onSelect?(action)
        }
    }

    @objc private func backdropTapped() {
        dismiss(animated: true)
    }

    @objc private func dismissTapped() {
        dismiss(animated: true)
    }

    @objc private func moreTapped() {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "刷新", style: .default) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        if let popover = sheet.popoverPresentationController {
            popover.sourceView = moreButton
            popover.sourceRect = moreButton.bounds
        }
        present(sheet, animated: true)
    }

    @objc private func pageControlChanged() {
        let offset = CGPoint(x: CGFloat(pageControl.currentPage) * pagesScrollView.bounds.width, y: 0)
        pagesScrollView.setContentOffset(offset, animated: true)
    }
}

extension AlookMenuViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === pagesScrollView, scrollView.bounds.width > 0 else {
            return
        }
        let page = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
        if pageControl.currentPage != page {
            pageControl.currentPage = max(0, min(1, page))
        }
    }
}

final class AlookMenuItemView: UIView {
    private let iconView: UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentMode = .scaleAspectFit
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 11, weight: .regular)
        label.textAlignment = .center
        label.numberOfLines = 2
        label.textColor = .label
        return label
    }()

    private let stateDot: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBlue
        view.layer.cornerRadius = 3
        view.isHidden = true
        return view
    }()

    var onTap: (() -> Void)?

    var isOn: Bool = false {
        didSet {
            stateDot.isHidden = !isOn
        }
    }

    init(action: AlookMenuAction) {
        super.init(frame: .zero)
        configure(with: action)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure(with action: AlookMenuAction) {
        iconView.image = UIImage(
            systemName: action.symbolName,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 24, weight: .light)
        )
        iconView.tintColor = action.isImplemented ? .label : .tertiaryLabel
        titleLabel.text = action.title
        titleLabel.textColor = action.isImplemented ? .label : .tertiaryLabel

        addSubview(iconView)
        addSubview(titleLabel)
        addSubview(stateDot)

        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconView.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            iconView.widthAnchor.constraint(equalToConstant: 30),
            iconView.heightAnchor.constraint(equalToConstant: 30),

            stateDot.trailingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 2),
            stateDot.topAnchor.constraint(equalTo: iconView.topAnchor, constant: -1),
            stateDot.widthAnchor.constraint(equalToConstant: 6),
            stateDot.heightAnchor.constraint(equalToConstant: 6),

            titleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2),
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        addGestureRecognizer(tap)
    }

    @objc private func tapped() {
        onTap?()
    }
}
