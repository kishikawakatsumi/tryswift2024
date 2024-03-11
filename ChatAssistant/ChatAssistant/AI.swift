import Foundation

func sendFakeRequest(command: String, completion: @escaping (String) -> Void) {
  DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
    let response = "This is a fake response for the command:\n=====\n\(command)"
    completion(response)
  }
}

func sendOpenAIRequest(command: String, completion: @escaping (String?) -> Void) {
  guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
    completion("Invalid URL")
    return
  }

  var request = URLRequest(url: url)
  request.httpMethod = "POST"
  request.addValue("application/json", forHTTPHeaderField: "Content-Type")
  #warning("Replace YOUR_API_KEY with your OpenAI API key")
  request.addValue("Bearer YOUR_API_KEY", forHTTPHeaderField: "Authorization")

  let json: [String: Any] = [
    "model": "gpt-4-0125-preview",
    "messages": [
      ["role": "system", "content": "You are a translator."],
      ["role": "user", "content": command]
    ]
  ]

  guard let jsonData = try? JSONSerialization.data(withJSONObject: json, options: []) else {
    completion("JSON Serialization failed")
    return
  }

  request.httpBody = jsonData

  let task = URLSession.shared.dataTask(with: request) { data, response, error in
    if let error = error {
      completion("Error: \(error)")
      return
    }

    let decoder = JSONDecoder()
    if let data = data {
      if let result = try? decoder.decode(ChatCompletion.self, from: data) {
        completion(result.choices[0].message.content)
      }
    } else {
      completion("No response data")
    }
  }

  task.resume()
}

struct ChatCompletion: Codable {
  let id: String
  let object: String
  let created: Int
  let model: String
  let choices: [Choice]
  let usage: Usage
}

struct Choice: Codable {
  let index: Int
  let message: Message
  let logprobs: LogProbs?
  let finishReason: String?

  enum CodingKeys: String, CodingKey {
    case index, message, logprobs
    case finishReason = "finish_reason"
  }
}

struct Message: Codable {
  let role: String
  let content: String
}

struct Usage: Codable {
  let promptTokens: Int
  let completionTokens: Int
  let totalTokens: Int

  enum CodingKeys: String, CodingKey {
    case promptTokens = "prompt_tokens"
    case completionTokens = "completion_tokens"
    case totalTokens = "total_tokens"
  }
}

struct LogProbs: Codable {}
