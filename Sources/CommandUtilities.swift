struct CommandUtilities {
  static func cleanArguments(_ arguments: [String]) -> [String] {
    return arguments.filter {
      !$0.caseInsensitiveEquals("the")
    }
  }

  static func enEtt(_ item: Item) -> String {
    if item.neutrum ?? false {
      return "ett"
    } else {
      return "en"
    }
  }
}
