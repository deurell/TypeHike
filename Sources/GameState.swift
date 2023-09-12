class GameState: Codable {
  var currentRoomID: Int
  var gameRooms: [Int: Room]
  var playerInventory: [Item]
  var isGameCompleted: Bool = false

  // Initializer for your class
  init(currentRoomID: Int, gameRooms: [Int: Room], playerInventory: [Item]) {
    self.currentRoomID = currentRoomID
    self.gameRooms = gameRooms
    self.playerInventory = playerInventory
  }

  func getCurrentRoom() -> Room? {
    return gameRooms[currentRoomID]
  }

  func lookAround(in room: Room) -> String {
    var output: [String] = []
    output.append(room.description)
    room.features?.forEach { feature in
      output.append(feature.description)
    }
    room.characters?.forEach { character in
      output.append("\(character.name) is here.")
    }
    room.items.forEach { item in
      output.append("There's a \(item.name) here.")
    }
    output.append("You can go \(room.paths.keys.joined(separator: ", ")).")
    return output.joined(separator: "\n")
  }

  func hasItem(named itemName: String) -> Bool {
    return playerInventory.contains { $0.name.caseInsensitiveEquals(itemName) }
  }
}
