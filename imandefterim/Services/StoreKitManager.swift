import Foundation
import StoreKit

// MARK: - Product Identifiers
enum StoreKitProductID: String, CaseIterable {
    // Basic (Starter) Plans
    case basicWeekly = "com.ayetio.imandefterim.basic.weekly"
    case basicMonthly = "com.ayetio.imandefterim.basic.monthly"
    case basicYearly = "com.ayetio.imandefterim.basic.yearly"

    // Pro Plans
    case proWeekly = "com.ayetio.imandefterim.pro.weekly"
    case proMonthly = "com.ayetio.imandefterim.pro.monthly"
    case proYearly = "com.ayetio.imandefterim.pro.yearly"

    var subscriptionPlan: SubscriptionPlan {
        switch self {
        case .basicWeekly, .basicMonthly, .basicYearly:
            return .starter
        case .proWeekly, .proMonthly, .proYearly:
            return .pro
        }
    }

    var billingPeriod: BillingPeriod {
        switch self {
        case .basicWeekly, .proWeekly:
            return .weekly
        case .basicMonthly, .proMonthly:
            return .monthly
        case .basicYearly, .proYearly:
            return .yearly
        }
    }
}

// MARK: - StoreKit Manager
@MainActor
final class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedSubscriptions: [Product] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private var updateListenerTask: Task<Void, Error>?

    // MARK: - Init
    private init() {
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()

        // Load products on init
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Load Products
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let productIds = StoreKitProductID.allCases.map { $0.rawValue }
            products = try await Product.products(for: productIds)
            print("✅ StoreKit: Loaded \(products.count) products")
        } catch {
            print("❌ StoreKit: Failed to load products: \(error)")
            errorMessage = "Ürünler yüklenemedi: \(error.localizedDescription)"
        }
    }

    // MARK: - Purchase
    func purchase(_ product: Product) async throws -> Bool {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                // Verify the transaction
                let transaction = try checkVerified(verification)

                // Update entitlements
                await updateEntitlements(for: transaction)

                // Finish the transaction
                await transaction.finish()

                print("✅ StoreKit: Purchase successful for \(product.id)")
                return true

            case .userCancelled:
                print("ℹ️ StoreKit: User cancelled purchase")
                return false

            case .pending:
                print("⏳ StoreKit: Purchase pending (Ask to Buy)")
                return false

            @unknown default:
                return false
            }
        } catch {
            print("❌ StoreKit: Purchase failed: \(error)")
            errorMessage = "Satın alma başarısız: \(error.localizedDescription)"
            throw error
        }
    }

    // MARK: - Restore Purchases
    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
            print("✅ StoreKit: Purchases restored")
        } catch {
            print("❌ StoreKit: Restore failed: \(error)")
            errorMessage = "Geri yükleme başarısız: \(error.localizedDescription)"
        }
    }

    // MARK: - Update Purchased Products
    func updatePurchasedProducts() async {
        var purchased: [Product] = []

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                if let product = products.first(where: { $0.id == transaction.productID }) {
                    purchased.append(product)
                    await updateEntitlements(for: transaction)
                }
            } catch {
                print("❌ StoreKit: Failed to verify transaction: \(error)")
            }
        }

        purchasedSubscriptions = purchased

        // If no active subscriptions, set to free
        if purchased.isEmpty {
            EntitlementManager.shared.updatePlan(.free)
        }
    }

    // MARK: - Transaction Listener
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)

                    await self.updateEntitlements(for: transaction)
                    await transaction.finish()

                    await MainActor.run {
                        Task {
                            await self.updatePurchasedProducts()
                        }
                    }
                } catch {
                    print("❌ StoreKit: Transaction verification failed: \(error)")
                }
            }
        }
    }

    // MARK: - Verify Transaction
    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Update Entitlements
    private func updateEntitlements(for transaction: Transaction) async {
        guard let productId = StoreKitProductID(rawValue: transaction.productID) else {
            return
        }

        // Check if subscription is still valid
        if transaction.revocationDate == nil && !transaction.isUpgraded {
            let plan = productId.subscriptionPlan
            EntitlementManager.shared.updatePlan(plan)
            print("✅ StoreKit: Entitlement updated to \(plan.displayName)")
        } else {
            // Subscription revoked or upgraded
            EntitlementManager.shared.updatePlan(.free)
        }
    }

    // MARK: - Get Product for Plan
    func product(for plan: SubscriptionPlan, period: BillingPeriod) -> Product? {
        let productId: StoreKitProductID
        switch (plan, period) {
        case (.starter, .weekly): productId = .basicWeekly
        case (.starter, .monthly): productId = .basicMonthly
        case (.starter, .yearly): productId = .basicYearly
        case (.pro, .weekly): productId = .proWeekly
        case (.pro, .monthly): productId = .proMonthly
        case (.pro, .yearly): productId = .proYearly
        default: return nil
        }

        return products.first { $0.id == productId.rawValue }
    }

    // MARK: - Check Active Subscription
    var hasActiveSubscription: Bool {
        !purchasedSubscriptions.isEmpty
    }

    var activeSubscriptionPlan: SubscriptionPlan? {
        guard let productId = purchasedSubscriptions.first?.id,
            let storeKitId = StoreKitProductID(rawValue: productId)
        else {
            return nil
        }
        return storeKitId.subscriptionPlan
    }
}
