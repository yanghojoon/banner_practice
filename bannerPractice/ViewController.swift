//
//  ViewController.swift
//  bannerPractice
//
//  Created by 양호준 on 2022/07/25.
//

import SnapKit
import Then
import UIKit

class ViewController: UIViewController {
    private let bannerCollectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: UICollectionViewLayout()
    )

    private let bannerPageControl = UIPageControl().then {
        $0.pageIndicatorTintColor = .green
        $0.currentPageIndicatorTintColor = .systemGray
        $0.isUserInteractionEnabled = false
//        $0.backgroundColor = .green

//        $0.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
    }

    private var imgSource = [UIImage(named: "tom1"), UIImage(named: "tom2"), UIImage(named: "tom3")]
    private var timer: Timer?
    private var isFirstLoadingBanner: Bool = true
    private var isDragging: Bool = false
    private var lastContentOffset: CGPoint = CGPoint(x: 0.0, y: 0.0)
    private let slideBannerDataMultipleValue = 100

    override func viewDidLoad() {
        super.viewDidLoad()

        render()
        configureCollectionView()
        configurePageControl()
    }

    private func render() {
        view.addSubview(bannerCollectionView)
        view.addSubview(bannerPageControl)

        bannerCollectionView.snp.makeConstraints {
            $0.top.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        bannerPageControl.snp.makeConstraints {
            $0.height.equalTo(3)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(bannerCollectionView.snp.bottom).inset(10)
        }
    }

    private func configureCollectionView() {
        bannerCollectionView.showsVerticalScrollIndicator = false
        bannerCollectionView.showsHorizontalScrollIndicator = false
        bannerCollectionView.isScrollEnabled = false

        bannerCollectionView.dataSource = self
        bannerCollectionView.delegate = self
        bannerCollectionView.register(
            BannerCell.self,
            forCellWithReuseIdentifier: String(describing: BannerCell.self)
        )
        bannerCollectionView.collectionViewLayout = createCollectionViewLayout()
        setScreenChangeTimer()
    }

    private func createCollectionViewLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { _, _ -> NSCollectionLayoutSection in
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(1.0)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(1.0)
            )
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: groupSize,
                subitem: item,
                count: 1
            )
            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = .groupPaging

            section.visibleItemsInvalidationHandler = { [weak self] (visibleItems, offset, environment) in
                let screenWidth = UIScreen.main.bounds.width
                guard let visibleIndexPath = visibleItems.last?.indexPath, let self = self else { return }
                let imgSourceIndex = visibleIndexPath.row % self.imgSource.count
                self.bannerPageControl.currentPage = imgSourceIndex

                if offset.x.truncatingRemainder(dividingBy: screenWidth) != .zero {
                    self.timer?.invalidate() // 자동 스크롤이든 직접 스크롤을 했든 그 동안은 Timer를 멈췄다가
                } else {
                    self.setScreenChangeTimer() // 스크롤이 완료되면 다시 타이머 동작
                }
            }

            return section
        }

        return layout
    }

    private func setScreenChangeTimer() {
        bannerCollectionView.performBatchUpdates(nil) { [weak self] result in // 왜 performBatchUpdates 내부에서 하는걸까?
            if result {
                self?.timer?.invalidate()
                self?.timer = Timer.scheduledTimer(
                    withTimeInterval: 2.0,
                    repeats: true
                ) { [weak self] _ in
                    guard
                        let self = self,
                        let visibleCell = self.bannerCollectionView.visibleCells.first,
                        var indexPath = self.bannerCollectionView.indexPath(for: visibleCell) // 현재 보이고 있는 셀의 indexPath
                    else {
                        return
                    }

                    let nextRow = indexPath.row + 1 // 다음 indexPath를 구함.
                    let multipleDataVaule = self.imgSource.count * self.slideBannerDataMultipleValue

                    indexPath.row = nextRow % multipleDataVaule // 이렇게 해서 100 * 3 번째 row가 자나면 다시 처음으로 돌아오게 됨
                    self.bannerCollectionView.scrollToItem(
                        at: indexPath, // 다음 indexPath로 스크롤하게 됨
                        at: .centeredHorizontally,
                        animated: true
                    )
                }
            }
        }
    }

    private func configurePageControl() {
        bannerPageControl.numberOfPages = imgSource.count
    }
}

extension ViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imgSource.count * slideBannerDataMultipleValue
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let bannerCell = collectionView.dequeueReusableCell(
            withReuseIdentifier: String(describing: BannerCell.self),
            for: indexPath
        ) as? BannerCell else {
            return UICollectionViewCell()
        }
        let index = indexPath.row % imgSource.count
        bannerCell.configure(from: imgSource[index] ?? UIImage())

        return bannerCell
    }
}
