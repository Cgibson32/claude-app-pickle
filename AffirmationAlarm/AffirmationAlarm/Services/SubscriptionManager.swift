import StoreKit

@Observable
class SubscriptionManager {
    static let shared = SubscriptionManager()

    private(set) var isSubscribed = false
    private(set) var product: Product?
    private(set) var isLoading = true
    private(set) var purchaseError: String?

    private var transactionListener: Task<Void, Never>?

    private init() {
        transactionListener = listenForTransactions()
        Task {
            await loadProduct()
            await updateSubscriptionStatus()
            isLoading = false
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Product Loading

    func loadProduct() async {
        for attempt in 1...3 {
            do {
                let products = try await Product.products(for: [AppConstants.subscriptionProductID])
                product = products.first
                if product != nil { return }
            } catch {
                print("Failed to load products (attempt \(attempt)): \(error)")
            }
            if attempt < 3 {
                try? await Task.sleep(for: .seconds(2))
            }
        }
    }

    // MARK: - Purchase

    func purchase() async {
        guard let product else {
            purchaseError = "Product not available. Please try again."
            return
        }

        purchaseError = nil

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await updateSubscriptionStatus()
                }
            case .userCancelled:
                break
            case .pending:
                purchaseError = "Purchase is pending approval."
            @unknown default:
                break
            }
        } catch {
            purchaseError = "Purchase failed. Please try again."
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        purchaseError = nil
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
            if !isSubscribed {
                purchaseError = "No active subscription found."
            }
        } catch {
            purchaseError = "Could not restore purchases. Please try again."
        }
    }

    // MARK: - Status

    func updateSubscriptionStatus() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == AppConstants.subscriptionProductID {
                isSubscribed = true
                return
            }
        }
        isSubscribed = false
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self.updateSubscriptionStatus()
                }
            }
        }
    }

    // MARK: - Display Helpers

    var priceText: String {
        product?.displayPrice ?? "$2.99"
    }

    var hasTrialOffer: Bool {
        product?.subscription?.introductoryOffer != nil
    }
}
