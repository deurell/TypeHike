public struct RoomView {
  public let description: String
  public let characters: [String]?
  public let imageName: String?

  init(description: String, characters: [String]? = nil, imageName: String? = nil) {
    self.description = description
    self.characters = characters
    self.imageName = imageName
  }
}
