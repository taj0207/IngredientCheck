//
//  LLMOCRClient.swift
//  IngredientCheck
//
//  Created on 2025-11-02
//

import Foundation
import UIKit

/// Client for LLM-based OCR (OpenAI GPT-5-mini or GPT-5)
class LLMOCRClient {

    // MARK: - Properties

    private let networkClient: NetworkClient
    private let apiKey: String
    private let model: String

    // MARK: - Initialization

    init(
        networkClient: NetworkClient = NetworkClient(),
        apiKey: String = APIConfig.openAIAPIKey,
        model: String = APIConfig.gpt5MiniModel
    ) {
        self.networkClient = networkClient
        self.apiKey = apiKey
        self.model = model
    }

    // MARK: - Public Methods

    /// Extract ingredients from image using LLM vision
    /// - Parameters:
    ///   - image: Product label image
    ///   - language: Preferred language hint
    /// - Returns: Array of ingredient names
    /// - Throws: OCRError if extraction fails
    func extractIngredients(
        from image: UIImage,
        language: String? = nil
    ) async throws -> [String] {
        let result = try await extractIngredientsDetailed(from: image, language: language)
        return result.ingredients
    }

    /// Extract ingredients with detailed metadata
    /// - Parameters:
    ///   - image: Product label image
    ///   - language: Preferred language hint
    /// - Returns: Detailed OCR result
    /// - Throws: OCRError if extraction fails
    func extractIngredientsDetailed(
        from image: UIImage,
        language: String? = nil
    ) async throws -> OCRResult {
        let startTime = Date()
        print("🚀 Starting OCR extraction...")

        // Convert and compress image
        print("📸 Preparing image...")
        guard let imageData = prepareImage(image) else {
            throw OCRError.invalidImage
        }
        print("✅ Image prepared: \(imageData.count) bytes")

        // Convert to base64
        print("🔄 Converting to base64...")
        let base64Image = imageData.base64EncodedString()
        print("✅ Base64 ready: \(base64Image.count) characters")

        // Create request payload
        print("📦 Creating request payload...")
        let payload = try createRequestPayload(
            base64Image: base64Image,
            language: language
        )
        print("✅ Payload created")

        // Perform API request
        print("🌐 Sending API request...")
        let response = try await performOCRRequest(payload: payload)
        print("✅ API response received")

        // Parse response
        print("🔍 Parsing response...")
        let ingredients = try parseIngredients(from: response)
        print("✅ Parsed \(ingredients.count) ingredients")

        let processingTime = Date().timeIntervalSince(startTime)

        Logger.logOCRExtraction(
            ingredientCount: ingredients.count,
            duration: processingTime,
            provider: FeatureFlags.primaryOCRProvider
        )

        return OCRResult(
            ingredients: ingredients,
            productName: nil, // TODO: Extract from response
            brand: nil, // TODO: Extract from response
            confidence: 0.9, // TODO: Parse from response
            processingTime: processingTime,
            provider: model
        )
    }

    // MARK: - Private Methods

    /// Prepare image for OCR (resize and compress)
    private func prepareImage(_ image: UIImage) -> Data? {
        // Resize if too large
        let resized = image.resized(
            to: CGSize(
                width: Constants.maxImageDimension,
                height: Constants.maxImageDimension
            )
        )

        // Compress to JPEG
        return resized.jpegData(compressionQuality: Constants.imageCompressionQuality)
    }

    /// Create OpenAI API request payload
    private func createRequestPayload(
        base64Image: String,
        language: String?
    ) throws -> OpenAIRequest {
        let prompt = createPrompt(language: language)

        return OpenAIRequest(
            model: model,
            messages: [
                OpenAIMessage(
                    role: "user",
                    content: [
                        .text(prompt),
                        .image(base64Image)
                    ]
                )
            ],
            maxCompletionTokens: APIConfig.maxOCRTokens
        )
    }

    /// Create OCR extraction prompt
    private func createPrompt(language: String?) -> String {
        let languageHint = language != nil ? "The text is primarily in \(language!)." : ""

        return """
        You are analyzing a product label to extract the ingredient list.

        Instructions:
        1. Find the "Ingredients" section on the label
        2. Extract ALL ingredient names in the exact order they appear
        3. Keep the original names (preserve language and formatting)
        4. Include parenthetical names if present (e.g., "Water (Aqua)")
        5. Ignore percentages and other non-ingredient text
        6. If multiple languages are present, include both (e.g., "苯氧乙醇 (Phenoxyethanol)")

        \(languageHint)

        Return ONLY a JSON object in this exact format:
        {
          "ingredients": ["ingredient1", "ingredient2", "ingredient3"]
        }

        Do not include any other text or explanation.
        """
    }

    /// Perform the OCR API request
    private func performOCRRequest(payload: OpenAIRequest) async throws -> OpenAIResponse {
        guard let url = URL(string: "\(APIConfig.openAIBaseURL)/chat/completions") else {
            throw OCRError.apiKeyMissing
        }

        print("🔍 OCR Request - Model: \(payload.model), URL: \(url.absoluteString)")
        print("🔑 API Key prefix: \(String(apiKey.prefix(10)))...")
        Logger.info("🔍 OCR Request - Model: \(payload.model), URL: \(url.absoluteString)", category: .network)
        Logger.info("🔑 API Key prefix: \(String(apiKey.prefix(10)))...", category: .network)

        // Encode payload
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        guard let body = try? encoder.encode(payload) else {
            throw OCRError.parsingError("Failed to encode request")
        }

        print("📦 Request body size: \(body.count) bytes")
        Logger.info("📦 Request body size: \(body.count) bytes", category: .network)

        // Create request
        var request = networkClient.createRequest(
            url: url,
            method: .post,
            headers: [
                "Authorization": "Bearer \(apiKey)"
            ],
            body: body
        )
        request.timeoutInterval = APIConfig.ocrTimeout
        print("⏱️ Request timeout set to: \(APIConfig.ocrTimeout) seconds")

        // Perform request
        do {
            print("📡 Performing network request...")

            // Get raw response to log it
            let (data, httpResponse) = try await URLSession.shared.data(for: request)

            guard let http = httpResponse as? HTTPURLResponse else {
                throw OCRError.networkError(NetworkError.connectionError(NSError(domain: "HTTP", code: -1)))
            }

            print("📥 HTTP Status: \(http.statusCode)")

            // Log raw JSON for debugging
            if let rawJSON = String(data: data, encoding: .utf8) {
                print("📥 Raw API Response JSON: \(rawJSON.prefix(500))...") // First 500 chars
                Logger.debug("Raw API Response: \(rawJSON)", category: .network)
            }

            // Check for error response
            guard (200...299).contains(http.statusCode) else {
                if let errorString = String(data: data, encoding: .utf8) {
                    print("❌ API Error Response: \(errorString)")
                }
                throw OCRError.networkError(NetworkError.httpError(statusCode: http.statusCode, data: data))
            }

            // Decode response
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let response = try decoder.decode(OpenAIResponse.self, from: data)

            print("✅ Network request completed successfully")
            return response
        } catch let error as NetworkError {
            print("❌ OCR Network Error: \(error)")
            Logger.error("OCR Network Error", error: error, category: .network)
            switch error {
            case .httpError(let statusCode, let data):
                // Log the actual error response
                print("❌ HTTP Error \(statusCode)")
                if let data = data, let errorMessage = String(data: data, encoding: .utf8) {
                    print("❌ OpenAI API Error Response: \(errorMessage)")
                    Logger.error("OpenAI API Error Response: \(errorMessage)", category: .network)
                }
                if statusCode == 429 {
                    throw OCRError.rateLimitExceeded
                } else if statusCode == 401 {
                    throw OCRError.apiKeyMissing
                } else if statusCode == 404 {
                    throw OCRError.parsingError("Model not found. Check if 'gpt-5-mini' is available in your OpenAI account.")
                }
                throw OCRError.networkError(error)
            case .decodingError(let decodingError):
                print("❌ JSON Decoding Error: \(decodingError)")
                Logger.error("JSON Decoding Error: \(decodingError)", category: .network)
                throw OCRError.parsingError("Invalid API response format")
            case .connectionError(let connectionError):
                print("❌ Connection Error: \(connectionError)")
                Logger.error("Connection Error: \(connectionError)", category: .network)
                throw OCRError.networkError(error)
            default:
                print("❌ Unknown Network Error: \(error)")
                Logger.error("Unknown Network Error: \(error)", category: .network)
                throw OCRError.networkError(error)
            }
        } catch {
            print("❌ OCR Unknown Error: \(error)")
            Logger.error("OCR Unknown Error: \(error)", category: .network)
            throw OCRError.unknownError(error)
        }
    }

    /// Parse ingredients from API response
    private func parseIngredients(from response: OpenAIResponse) throws -> [String] {
        // Log response metadata
        print("📊 API Response - Model: \(response.model ?? "unknown"), Choices: \(response.choices.count)")
        if let usage = response.usage {
            print("📊 Token Usage - Prompt: \(usage.promptTokens ?? 0), Completion: \(usage.completionTokens ?? 0), Total: \(usage.totalTokens ?? 0)")
        }

        guard let choice = response.choices.first else {
            print("❌ No choices in response!")
            throw OCRError.noTextDetected
        }

        print("📊 Choice - Finish Reason: \(choice.finishReason ?? "none")")
        print("📊 Message - Role: \(choice.message.role ?? "none")")

        // Check for refusal
        if let refusal = choice.message.refusal {
            print("❌ Model refused request: \(refusal)")
            throw OCRError.parsingError("Model refused: \(refusal)")
        }

        guard let content = choice.message.content else {
            print("❌ No content in message! Full message: role=\(choice.message.role ?? "nil"), content=nil, refusal=\(choice.message.refusal ?? "nil")")
            throw OCRError.noTextDetected
        }

        // Log the raw response for debugging
        print("📄 Raw LLM Response: \(content)")
        Logger.debug("Raw LLM Response: \(content)", category: .ocr)

        // Extract JSON from response (handle markdown code blocks and extra text)
        let jsonString = extractJSON(from: content)
        print("📝 Extracted JSON: \(jsonString)")

        guard let jsonData = jsonString.data(using: .utf8) else {
            throw OCRError.parsingError("Invalid UTF-8 in response")
        }

        do {
            let result = try JSONDecoder().decode(IngredientsResponse.self, from: jsonData)
            let filteredIngredients = result.ingredients.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            print("✅ Successfully parsed \(filteredIngredients.count) ingredients from JSON")
            return filteredIngredients
        } catch {
            // If JSON parsing fails, try to extract ingredients from text
            print("⚠️ Failed to parse JSON: \(error)")
            Logger.warning("Failed to parse JSON (\(error)), attempting text extraction", category: .ocr)
            return try extractIngredientsFromText(content)
        }
    }

    /// Extract JSON string from LLM response (handles markdown code blocks and extra text)
    private func extractJSON(from content: String) -> String {
        var cleaned = content.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove markdown code blocks: ```json ... ``` or ``` ... ```
        if cleaned.hasPrefix("```") {
            // Remove opening ```json or ```
            if let firstNewline = cleaned.firstIndex(of: "\n") {
                cleaned = String(cleaned[cleaned.index(after: firstNewline)...])
            }

            // Remove closing ```
            if let lastBackticks = cleaned.range(of: "```", options: .backwards) {
                cleaned = String(cleaned[..<lastBackticks.lowerBound])
            }

            cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Try to find JSON object boundaries if there's extra text
        if !cleaned.hasPrefix("{") {
            if let jsonStart = cleaned.firstIndex(of: "{") {
                cleaned = String(cleaned[jsonStart...])
            }
        }

        if !cleaned.hasSuffix("}") {
            if let jsonEnd = cleaned.lastIndex(of: "}") {
                cleaned = String(cleaned[...jsonEnd])
            }
        }

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Fallback: Extract ingredients from plain text
    private func extractIngredientsFromText(_ text: String) throws -> [String] {
        // Look for array-like patterns
        let pattern = "\\[([^\\]]+)\\]"
        if let range = text.range(of: pattern, options: .regularExpression) {
            let arrayString = String(text[range])
            let ingredients = arrayString
                .replacingOccurrences(of: "[", with: "")
                .replacingOccurrences(of: "]", with: "")
                .replacingOccurrences(of: "\"", with: "")
                .components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            return ingredients
        }

        throw OCRError.parsingError("Could not extract ingredients from text")
    }
}

// MARK: - Request/Response Models

private struct OpenAIRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
    let maxCompletionTokens: Int
}

private struct OpenAIMessage: Codable {
    let role: String
    let content: [MessageContent]

    enum MessageContent: Codable {
        case text(String)
        case image(String)

        enum CodingKeys: String, CodingKey {
            case type
            case text
            case imageUrl = "image_url"
        }

        enum ImageKeys: String, CodingKey {
            case url
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .text(let text):
                try container.encode("text", forKey: .type)
                try container.encode(text, forKey: .text)
            case .image(let base64):
                try container.encode("image_url", forKey: .type)
                var imageContainer = container.nestedContainer(keyedBy: ImageKeys.self, forKey: .imageUrl)
                try imageContainer.encode("data:image/jpeg;base64,\(base64)", forKey: .url)
            }
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)
            switch type {
            case "text":
                let text = try container.decode(String.self, forKey: .text)
                self = .text(text)
            case "image_url":
                let imageContainer = try container.nestedContainer(keyedBy: ImageKeys.self, forKey: .imageUrl)
                let url = try imageContainer.decode(String.self, forKey: .url)
                self = .image(url)
            default:
                throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown content type")
            }
        }
    }
}

private struct OpenAIResponse: Codable {
    let choices: [Choice]
    let model: String?
    let usage: Usage?

    struct Choice: Codable {
        let message: Message
        let finishReason: String?

        struct Message: Codable {
            let role: String?
            let content: String?
            let refusal: String?  // GPT-5 might refuse certain requests
        }
    }

    struct Usage: Codable {
        let promptTokens: Int?
        let completionTokens: Int?
        let totalTokens: Int?
    }
}

private struct IngredientsResponse: Codable {
    let ingredients: [String]
}

// MARK: - UIImage Extension

extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        let widthRatio = size.width / self.size.width
        let heightRatio = size.height / self.size.height
        let ratio = min(widthRatio, heightRatio, 1.0)

        let newSize = CGSize(
            width: self.size.width * ratio,
            height: self.size.height * ratio
        )

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }

        self.draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}
