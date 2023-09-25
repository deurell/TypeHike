struct Path: Codable {
  var roomID: Int
  var isLocked: Bool
}

struct Item: Codable {
  var name: String
  var neutrum: Bool?
  var description: String
  var interactions: [Interaction]?
  func canInteract(with item: String) -> Bool {
     return interactions?.contains(where: { $0.withItem.caseInsensitiveEquals(item) }) ?? false
  }
}

struct Character: Codable {
  var name: String
  var dialogue: [String]?
  var description: String
  var interactions: [Interaction]?
}

struct Feature: Codable {
  var description: String
  var keywords: [String]
  var interactions: [Interaction]?
}

struct PostAction: Codable {
    var action: String
    var item: String
}

struct Interaction: Codable {
    var withItem: String
    var action: String
    var message: String
    var spawnItem: Item?
    var hasExecuted: Bool? = false
    var postInteraction: [PostAction]?
    var isRepeatable: Bool? = false
}

struct Room: Codable {
  var id: Int
  var description: String
  var paths: [String: Path]
  var items: [Item]
  var characters: [Character]?
  var features: [Feature]?
}

struct GameData: Codable {
  var startingRoom: Int
  var rooms: [Room]
}
