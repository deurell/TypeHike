public struct PlayerContext {
  public let description: String
  public let characters: [String]?
  public let imageName: String?
  public let inventory: [String]?
  public let items: [String]?
  public let features: [String]?
  public let paths: [String]?

  init(
    description: String, characters: [String]? = nil, imageName: String? = nil,
    inventory: [String]? = nil, items: [String]? = nil, features: [String]? = nil, paths: [String]? = nil
  ) {
    self.description = description
    self.characters = characters
    self.imageName = imageName
    self.inventory = inventory
    self.items = items
    self.features = features
    self.paths = paths
  }
}
