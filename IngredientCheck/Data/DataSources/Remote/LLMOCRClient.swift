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

        // Convert and compress image
        guard let imageData = prepareImage(image) else {
            throw OCRError.invalidImage
        }

        // Convert to base64
        let base64Image = imageData.base64EncodedString()

        // Create request payload
        let payload = try createRequestPayload(
            base64Image: base64Image,
            language: language
        )

        // Perform API request
        let response = try await performOCRRequest(payload: payload)

        // Parse response
        let ingredients = try parseIngredients(from: response)

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
            maxTokens: APIConfig.maxOCRTokens
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

        // Encode payload
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        guard let body = try? encoder.encode(payload) else {
            throw OCRError.parsingError("Failed to encode request")
        }

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

        // Perform request
        do {
            let response: OpenAIResponse = try await networkClient.perform(
                request,
                decoding: OpenAIResponse.self
            )
            return response
        } catch let error as NetworkError {
            switch error {
            case .httpError(let statusCode, _):
                if statusCode == 429 {
                    throw OCRError.rateLimitExceeded
                } else if statusCode == 401 {
                    throw OCRError.apiKeyMissing
                }
                throw OCRError.networkError(error)
            case .decodingError:
                throw OCRError.parsingError("Invalid API response format")
            default:
                throw OCRError.networkError(error)
            }
        } catch {
            throw OCRError.unknownError(error)
        }
    }

    /// Parse ingredients from API response
    private func parseIngredients(from response: OpenAIResponse) throws -> [String] {
        guard let choice = response.choices.first,
              let content = choice.message.content else {
            throw OCRError.noTextDetected
        }

        // Parse JSON from response
        guard let jsonData = content.data(using: .utf8) else {
            throw OCRError.parsingError("Invalid UTF-8 in response")
        }

        do {
            let result = try JSONDecoder().decode(IngredientsResponse.self, from: jsonData)
            return result.ingredients.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        } catch {
            // If JSON parsing fails, try to extract ingredients from text
            Logger.warning("Failed to parse JSON, attempting text extraction", category: .ocr)
            return try extractIngredientsFromText(content)
        }
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
    let maxTokens: Int
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

    struct Choice: Codable {
        let message: Message

        struct Message: Codable {
            let content: String?
        }
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
