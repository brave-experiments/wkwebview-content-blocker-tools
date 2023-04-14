// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import WebKit

public typealias FailingRule = (rule: [String: Any], error: Error)

public extension WKContentRuleListStore {
  func testBisect(contentRules: [[String: Any]]) async -> (failedRules: [FailingRule], maxiumSizePassed: Int) {
    var results: [FailingRule] = []
    var maxiumSizePassed = contentRules.count
    
    if contentRules.isEmpty {
      return (results, maxiumSizePassed)
    } else if contentRules.count == 1, let contentRule = contentRules.first  {
      do {
        try await compile(contentRuleLists: contentRules, forIdentifier: "test-bisect")
      } catch {
        results.append((contentRule, error))
      }
    } else {
      let splitIndex = Int(contentRules.count / 2)
      let first = Array(contentRules[0..<splitIndex])
      let second = Array(contentRules[splitIndex..<contentRules.count])
      
      // Test the left side
      do {
        try await compile(contentRuleLists: first, forIdentifier: "test-bisect-left")
        maxiumSizePassed = first.count
      } catch {
        let additionalResults = await testBisect(contentRules: first)
        maxiumSizePassed = min(maxiumSizePassed, additionalResults.maxiumSizePassed)
        results.append(contentsOf: additionalResults.failedRules)
      }
      
      // Test the right side
      do {
        try await compile(contentRuleLists: second, forIdentifier: "test-bisect-right")
        maxiumSizePassed = max(maxiumSizePassed, second.count)
        return (results, maxiumSizePassed)
      } catch {
        let additionalResults = await testBisect(contentRules: second)
        maxiumSizePassed = min(maxiumSizePassed, additionalResults.maxiumSizePassed)
        results.append(contentsOf: additionalResults.failedRules)
      }
    }
    
    return (results, maxiumSizePassed)
  }
  
  enum RuleListCompileError: Error {
    case failedToEncodeToString
    case emptyRuleList
  }
  
  func encode(contentRuleList: [[String: Any]]) throws -> String {
    let data = try JSONSerialization.data(withJSONObject: contentRuleList)
    
    guard let encodedContentRuleList = String(data: data, encoding: .utf8) else {
      throw RuleListCompileError.emptyRuleList
    }
    
    return encodedContentRuleList
  }
  
  @discardableResult
  @MainActor func compile(contentRuleLists: [[String: Any]], forIdentifier: String) async throws -> WKContentRuleList {
    let encodedContentRuleList = try encode(contentRuleList: contentRuleLists)
    
    if let ruleList = try await compileContentRuleList(
      forIdentifier: "test-identifier",
      encodedContentRuleList: encodedContentRuleList
    ) {
      return ruleList
    } else {
      throw RuleListCompileError.emptyRuleList
    }
  }
}
