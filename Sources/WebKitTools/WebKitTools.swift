import ArgumentParser
import Foundation
import WebKit

@main
struct WebKitTools: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "webkit-tools",
    abstract: "A Swift command-line tool for testing webkit content blocker rules",
    version: "1.0.0",
    subcommands: [TestJSON.self]
  )
}

struct TestJSON: AsyncParsableCommand {
  enum ParseError: Error {
    case invalidFileFormat
    case fileDoesNotExist
  }
  
  static let configuration = CommandConfiguration(
    abstract: "Test an encoded iOS content blocking (JSON) format file "
  )
  
  @Argument<URL>(
    help: "The location of the file that you want to parse. This file should be in encoded iOS content blocking (JSON) format",
    transform: { argument throws -> URL in
    return URL(fileURLWithPath: argument)
  })
  var inputFile: URL
  
  mutating func run() async throws {
    guard FileManager.default.fileExists(atPath: inputFile.path) else {
      throw ParseError.fileDoesNotExist
    }
    
    let data = try Data(contentsOf: inputFile)
    
    guard let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
      throw ParseError.invalidFileFormat
    }
    
    print("File contains \(jsonArray.count) rules")
    let ruleStore = try await makeRuleStore(ruleStoreName: "test-rules")
    
    do {
      _ = try await ruleStore.compile(contentRuleLists: jsonArray, forIdentifier: "test-rules")
      print("passed")
    } catch {
      print("failed")
    }
  }
  
  @MainActor private func makeRuleStore(ruleStoreName: String) throws -> WKContentRuleListStore {
    let folderURL = FileManager.default.temporaryDirectory
      .appending(path: "rule-stores")
      .appending(path: "ruleStoreName")
    
    try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
    return WKContentRuleListStore(url: folderURL)!
  }
}
