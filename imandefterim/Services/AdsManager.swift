import GoogleMobileAds
import SwiftUI

class AdsManager: NSObject, ObservableObject {
    static let shared = AdsManager()

    // MARK: - Ad Unit IDs (Test IDs)
    // Replace these with your actual Ad Unit IDs from AdMob dashboard
    // TODO: USER_ACTION required - Update with real IDs
    let bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"
    let interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"
    let rewardedAdUnitID = "ca-app-pub-3940256099942544/1712485313"

    @Published var isInterstitialReady = false
    @Published var isRewardedReady = false

    private var interstitial: InterstitialAd?
    private var rewardedAd: RewardedAd?

    override init() {
        super.init()
        start()
    }

    func start() {
        MobileAds.shared.start(completionHandler: nil)
        loadInterstitial()
        loadRewarded()
    }

    // MARK: - Banner Ad View
    func makeBannerView(width: CGFloat) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = bannerAdUnitID
        // In a real app, you would set the rootViewController here if possible,
        // or let the UIViewControllerRepresentable handle it.
        return banner
    }

    // MARK: - Interstitial Ads
    func loadInterstitial() {
        let request = Request()
        InterstitialAd.load(
            with: interstitialAdUnitID,
            request: request
        ) { [weak self] ad, error in
            if let error = error {
                print("Failed to load interstitial ad with error: \(error.localizedDescription)")
                return
            }
            self?.interstitial = ad
            self?.interstitial?.fullScreenContentDelegate = self
            self?.isInterstitialReady = true
        }
    }

    func showInterstitial(from rootViewController: UIViewController) {
        if let ad = interstitial {
            ad.present(from: rootViewController)
        } else {
            print("Ad wasn't ready")
            loadInterstitial()
        }
    }

    // MARK: - Rewarded Ads
    func loadRewarded() {
        let request = Request()
        RewardedAd.load(
            with: rewardedAdUnitID,
            request: request
        ) { [weak self] ad, error in
            if let error = error {
                print("Failed to load rewarded ad with error: \(error.localizedDescription)")
                return
            }
            self?.rewardedAd = ad
            self?.rewardedAd?.fullScreenContentDelegate = self
            self?.isRewardedReady = true
        }
    }

    func showRewarded(
        from rootViewController: UIViewController, userDidEarnRewardHandler: @escaping (Int) -> Void
    ) {
        if let ad = rewardedAd {
            ad.present(from: rootViewController) {
                let reward = ad.adReward
                userDidEarnRewardHandler(reward.amount.intValue)
            }
        } else {
            print("Ad wasn't ready")
            loadRewarded()
        }
    }
}

extension AdsManager: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        // Reload ads after they are dismissed
        if ad is InterstitialAd {
            isInterstitialReady = false
            loadInterstitial()
        } else if ad is RewardedAd {
            isRewardedReady = false
            loadRewarded()
        }
    }

    func ad(
        _ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error
    ) {
        print("Ad failed to present full screen content with error: \(error.localizedDescription)")
        if ad is InterstitialAd {
            isInterstitialReady = false
            loadInterstitial()
        } else if ad is RewardedAd {
            isRewardedReady = false
            loadRewarded()
        }
    }
}

// MARK: - SwiftUI Banner Wrapper
struct BannerAdView: UIViewControllerRepresentable {
    let adUnitID: String

    init(adUnitID: String = AdsManager.shared.bannerAdUnitID) {
        self.adUnitID = adUnitID
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let view = BannerView(adSize: AdSizeBanner)
        view.adUnitID = adUnitID
        let viewController = UIViewController()
        view.rootViewController = viewController
        viewController.view.addSubview(view)
        viewController.view.frame = CGRect(origin: .zero, size: AdSizeBanner.size)
        view.load(Request())
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
