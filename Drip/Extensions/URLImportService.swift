import UIKit

struct ImportedItem {
    var imageData: Data?
    var name: String = ""
    var brand: String = ""
    var price: Double = 0
}

enum URLImportService {
    static func fetch(urlString: String) async -> ImportedItem {
        var result = ImportedItem()
        guard let url = URL(string: urlString.trimmingCharacters(in: .whitespaces)) else { return result }

        do {
            var req = URLRequest(url: url, timeoutInterval: 12)
            req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148",
                         forHTTPHeaderField: "User-Agent")
            let (data, _) = try await URLSession.shared.data(for: req)
            let html = String(data: data, encoding: .utf8) ?? ""

            let imageURLString = meta("og:image", html) ?? meta("twitter:image", html) ?? firstProductImage(html)
            result.name  = cleanTitle(meta("og:title", html) ?? meta("twitter:title", html) ?? "")
            result.brand = meta("og:site_name", html) ?? ""
            if let ps = meta("product:price:amount", html) ?? meta("og:price:amount", html) {
                result.price = Double(ps) ?? 0
            }

            if let imgStr = imageURLString, let imgURL = URL(string: imgStr) {
                let (imgData, _) = try await URLSession.shared.data(from: imgURL)
                if let ui = UIImage(data: imgData) {
                    result.imageData = ui.jpegData(compressionQuality: 0.8)
                }
            }
        } catch { }
        return result
    }

    // MARK: – Parsers

    private static func meta(_ property: String, _ html: String) -> String? {
        let patterns = [
            "property=\"\(property)\"[^>]*content=\"([^\"]+)\"",
            "content=\"([^\"]+)\"[^>]*property=\"\(property)\"",
            "name=\"\(property)\"[^>]*content=\"([^\"]+)\"",
            "content=\"([^\"]+)\"[^>]*name=\"\(property)\""
        ]
        for p in patterns {
            if let m = firstCapture(p, in: html) { return m }
        }
        return nil
    }

    private static func firstProductImage(_ html: String) -> String? {
        let patterns = [
            "\"(https://[^\"]+(?:product|item|clothes|fashion)[^\"]+\\.(?:jpg|jpeg|png|webp)[^\"]*)\""
        ]
        for p in patterns {
            if let m = firstCapture(p, in: html) { return m }
        }
        return nil
    }

    private static func firstCapture(_ pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges > 1,
              let range = Range(match.range(at: 1), in: text) else { return nil }
        return String(text[range])
    }

    private static func cleanTitle(_ raw: String) -> String {
        var s = raw
        let suffixes = [" | ZARA", " | H&M", " | ASOS", " - ASOS", " | Pull&Bear", " | Bershka",
                        " | Mango", " | Nike", " | Adidas", " | Zalando", " | About You"]
        for suf in suffixes { s = s.replacingOccurrences(of: suf, with: "") }
        return s.trimmingCharacters(in: .whitespaces)
    }
}
