//
//  Feed.swift
//  Freetime
//
//  Created by Ryan Nystrom on 5/15/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit
import SnapKit
import IGListKit

protocol FeedDelegate: class {
    func loadFromNetwork(feed: Feed)
}

final class Feed {

    weak var delegate: FeedDelegate? = nil

    let adapter: IGListAdapter
    lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        view.alwaysBounceVertical = true
        view.backgroundColor = Styles.Colors.background
        view.refreshControl = UIRefreshControl()
        view.refreshControl?.addTarget(self, action: #selector(Feed.onRefresh(sender:)), for: .valueChanged)
        return view
    }()

    private var refreshBegin: TimeInterval = -1

    init(viewController: UIViewController, delegate: FeedDelegate) {
        self.adapter = IGListAdapter(updater: IGListAdapterUpdater(), viewController: viewController)
        self.delegate = delegate
    }

    // MARK: Public API

    func viewDidLoad() {
        guard let view = adapter.viewController?.view else { return }

        adapter.collectionView = collectionView

        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }

        collectionView.refreshControl?.beginRefreshing()
        refresh()
    }

    func update(fromNetwork: Bool) {
        let block = {
            self.adapter.performUpdates(animated: true) { _ in
                if fromNetwork {
                    self.collectionView.refreshControl?.endRefreshing()
                }
            }
        }

        // delay the refresh control dismissal so the UI isn't too spazzy on fast or non-existent connections
        let remaining = 0.5 - (CFAbsoluteTimeGetCurrent() - refreshBegin)
        if remaining > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + remaining, execute: block)
        } else {
            block()
        }
    }

    // MARK: Private API

    private func refresh() {
        refreshBegin = CFAbsoluteTimeGetCurrent()
        delegate?.loadFromNetwork(feed: self)
    }

    @objc private func onRefresh(sender: Any) {
        refresh()
    }

}