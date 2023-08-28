struct Path: Codable {
  var roomID: Int
  var isLocked: Bool
}

struct Item: Codable {
  var name: String
  var description: String
}

struct Character: Codable {
  var name: String
  var dialogue: String
  var description: String
  var interactions: [Interaction]?
}

struct Feature: Codable {
  var description: String
  var keywords: [String]
  var interactions: [Interaction]?
}

struct Interaction: Codable {
  var withItem: String
  var action: String
  var message: String
  var spawnItem: Item?
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