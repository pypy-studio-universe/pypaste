import Foundation

public struct WebLinkPreview: Equatable, Sendable {
    public let url: URL
    public let displayHost: String
    public let pathSummary: String
    public let displayURL: String

    public init?(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard
            let components = URLComponents(string: trimmed),
            let scheme = components.scheme?.lowercased(),
            scheme == "http" || scheme == "https",
            let host = components.host,
            !host.isEmpty,
            let url = components.url
        else {
            return nil
        }

        self.url = url
        let normalizedHost = host.lowercased()
        displayHost =
            normalizedHost.hasPrefix("www.")
            ? String(normalizedHost.dropFirst(4))
            : normalizedHost
        displayURL = trimmed

        let path = components.percentEncodedPath.removingPercentEncoding ?? components.path
        let querySuffix = components.query.map { "?\($0)" } ?? ""
        pathSummary = path.isEmpty || path == "/" ? "Homepage" : "\(path)\(querySuffix)"
    }
}
