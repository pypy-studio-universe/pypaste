import Foundation
import PyPasteDomain

public actor UserDefaultsDuplicatePolicyProvider: DuplicatePolicyProviding {
    private let suiteName: String?

    public init(suiteName: String? = nil) {
        self.suiteName = suiteName
    }

    public func duplicatePolicy() async -> DuplicatePolicy {
        let defaults: UserDefaults

        if let suiteName, let suiteDefaults = UserDefaults(suiteName: suiteName) {
            defaults = suiteDefaults
        } else {
            defaults = .standard
        }

        guard let rawValue = defaults.string(forKey: DuplicatePolicy.defaultsKey) else {
            return .moveExistingToTop
        }

        return DuplicatePolicy(rawValue: rawValue) ?? .moveExistingToTop
    }
}
