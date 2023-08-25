protocol Command {
  func execute(arguments: [String], gameState: GameState) -> String
}

struct LookCommand: Command {
  func execute(arguments: [String], gameState: GameState) -> String {
    if let currentRoom = gameState.gameRooms[gameState.currentRoomID] {
      return gameState.lookAround(in: currentRoom)
    }
    return "You seem to be nowhere, something must be wrong."
  }
}

struct GoCommand: Command {
  func execute(arguments: [String], gameState: GameState) -> String {
    if arguments.count > 0 {
      return go(arguments[0], gameState)
    } else {
      return "Where would you like to go?"
    }
  }

  func go(_ direction: String, _ gameState: GameState) -> String {
    if let path = gameState.gameRooms[gameState.currentRoomID]?.paths[direction] {
      if !path.isLocked {
        gameState.currentRoomID = path.roomID
        if let currentRoom = gameState.gameRooms[gameState.currentRoomID] {
          let moveString = "You move \(direction)."
          return moveString + "\n" + gameState.lookAround(in: currentRoom)
        } else {
          return "There's no room in that direction."
        }
      } else {
        return "The path to the \(direction) is locked."
      }
    } else {
      return "You can't go in that direction."
    }
  }
}

struct UseCommand: Command {

  func execute(arguments: [String], gameState: GameState) -> String {
    guard !arguments.isEmpty else {
      return "What would you like to use?"
    }

    // Determine if the "on" keyword is present in the arguments
    if let onIndex = arguments.firstIndex(of: "on"), onIndex + 1 < arguments.count {
      // Create the item name from all words before "on"
      let itemName = arguments[..<onIndex].joined(separator: " ")
      let targetName = arguments[(onIndex + 1)...].joined(separator: " ")
      return useItem(named: itemName, on: targetName, with: gameState)
    } else {
      let itemName = arguments.joined(separator: " ")
      return useItem(named: itemName, with: gameState)
    }
  }

  func useItem(named itemName: String, on target: String = "self", with gameState: GameState)
    -> String
  {
    if !gameState.hasItem(named: itemName) {
      return "You don't have a \(itemName) in your inventory."
    }

    guard
      let item = gameState.playerInventory.first(where: { $0.name.caseInsensitiveEquals(itemName) })
    else {
      return "Unexpected error: Couldn't find the \(itemName) in your inventory."
    }

    let interactionResultMessage = handleInteraction(using: item, on: target, with: gameState)
    return interactionResultMessage
  }

  func handleInteraction(using item: Item, on target: String, with gameState: GameState)
    -> String
  {
    // First, check if the target matches a character in the room
    if let character = gameState.gameRooms[gameState.currentRoomID]?.characters?.first(where: {
      $0.name.caseInsensitiveEquals(target)
    }),
      let interaction = character.interactions?.first(where: { $0.withItem == item.name })
    {
      return executeInteraction(interaction: interaction, with: gameState)
    }

    // If not, check if the target matches a feature in the room
    if let feature = gameState.gameRooms[gameState.currentRoomID]?.features?.first(where: {
      $0.keywords.contains(target)
    }
    ),
      let interaction = feature.interactions?.first(where: { $0.withItem == item.name })
    {
      return executeInteraction(interaction: interaction, with: gameState)
    }

    return "Your action had no effect."
  }

  func executeInteraction(interaction: Interaction, with gameState: GameState) -> String {
    switch interaction.action {
    case "reveal":
      if let item = interaction.spawnItem {
        // Add the revealed item to the player's inventory or to the room
        gameState.gameRooms[gameState.currentRoomID]?.items.append(item)
        return interaction.message
      }
    case "add_to_inventory":
      if let item = interaction.spawnItem {
        gameState.playerInventory.append(item)
        return interaction.message
      }
    case let str where str.starts(with: "unlock_path_"):
      let pathName = interaction.action.replacingOccurrences(of: "unlock_path_", with: "")
      gameState.gameRooms[gameState.currentRoomID]?.paths[pathName]?.isLocked = false
      return interaction.message
    default:
      return interaction.message
    }
    return "Nothing happened."
  }

}

struct InventoryCommand: Command {
  func execute(arguments: [String], gameState: GameState) -> String {
    return showInventory(gameState)
  }

  func showInventory(_ gameState: GameState) -> String {
    if gameState.playerInventory.isEmpty {
      return "Your inventory is empty."
    } else {
      var message: [String] = []
      message.append("You have:")
      gameState.playerInventory.forEach { message.append("- \($0.name): \($0.description)") }
      return message.joined(separator: "\n")
    }
  }
}

struct GetCommand: Command {
  func execute(arguments: [String], gameState: GameState) -> String {
    if arguments.count > 0 {
      let itemName = arguments.joined(separator: " ")
      return getItem(named: itemName, with: gameState)
    } else {
      return "What would you like to get?"
    }
  }

  func getItem(named itemName: String, with gameState: GameState) -> String {
    if let index = gameState.gameRooms[gameState.currentRoomID]?.items.firstIndex(where: {
      $0.name.caseInsensitiveEquals(itemName)
    }) {
      if let item = gameState.gameRooms[gameState.currentRoomID]?.items.remove(at: index) {
        gameState.playerInventory.append(item)
        return "You picked up the \(itemName)."
      }
    }
    return "There's no \(itemName) here to pick up."
  }

}

struct TalkCommand: Command {
  func execute(arguments: [String], gameState: GameState) -> String {
    if arguments.count >= 2 && arguments[0] == "to" {
      let characterName = arguments.dropFirst().joined(separator: " ")
      return talkToCharacter(named: characterName, with: gameState)
    } else {
      return "Who would you like to talk to?"
    }
  }

  func talkToCharacter(named characterName: String, with gameState: GameState) -> String {
    if let character = gameState.gameRooms[gameState.currentRoomID]?.characters?.first(where: {
      $0.name.caseInsensitiveEquals(characterName)
    }) {
      return "\(characterName.capitalized): \"\(character.dialogue)\""
    } else {
      return "\(characterName.capitalized) is not here."
    }
  }
}

struct DropCommand: Command {
  func execute(arguments: [String], gameState: GameState) -> String {
    if arguments.count > 0 {
      let itemName = arguments.joined(separator: " ")
      return dropItem(named: itemName, with: gameState)
    } else {
      return "What would you like to drop?"
    }
  }

  func dropItem(named itemName: String, with gameState: GameState) -> String {
    if let index = gameState.playerInventory.firstIndex(where: {
      $0.name.caseInsensitiveEquals(itemName)
    }) {
      let item = gameState.playerInventory.remove(at: index)
      gameState.gameRooms[gameState.currentRoomID]?.items.append(item)
      return "You dropped the \(itemName)."
    } else {
      return "You don't have a \(itemName) in your inventory."
    }
  }
}

struct QuitCommand: Command {
  func execute(arguments: [String], gameState: GameState) -> String {
    return "So long, and thanks for playing!"
  }
}

struct HelpCommand: Command {
  func execute(arguments: [String], gameState: GameState) -> String {
    return "Available commands:\n" +
      "look\n" +
      "go <direction>\n" +
      "use <item> [on <target>]\n" +
      "inventory\n" +
      "get <item>\n" +
      "talk to <character>\n" +
      "drop <item>\n" +
      "quit\n" +
      "help"
  }
} 
