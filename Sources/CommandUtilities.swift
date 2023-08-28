struct CommandUtilities {
  static func cleanArguments(_ arguments: [String]) -> [String] {
    return arguments.filter {
      !$0.caseInsensitiveEquals("the")
    }
  }
}
