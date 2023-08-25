extension String {
  func caseInsensitiveEquals(_ other: String) -> Bool {
    return self.lowercased() == other.lowercased()
  }
}
