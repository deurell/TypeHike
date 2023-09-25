import Foundation  // Needed for arc4random_uniform()

protocol Command {
  func execute(arguments: [String], gameState: GameState) -> String
}

struct LookCommand: Command {
  func execute(arguments: [String], gameState: GameState) -> String {
    if let currentRoom = gameState.gameRooms[gameState.currentRoomID] {
      return gameState.lookAround(in: currentRoom)
    }
    return "Det verkar som att du är ingenstans, något måste vara fel."
  }
}

struct GoCommand: Command {
  func execute(arguments: [String], gameState: GameState) -> String {
    if arguments.count > 0 {
      return go(arguments[0], gameState)
    } else {
      return "Vart vill du gå?"
    }
  }

  func go(_ direction: String, _ gameState: GameState) -> String {
    if let path = gameState.gameRooms[gameState.currentRoomID]?.paths[
      direction.prefix(1).capitalized + direction.dropFirst()]
    {
      if !path.isLocked {
        gameState.currentRoomID = path.roomID
        if let currentRoom = gameState.gameRooms[gameState.currentRoomID] {
          let moveString = "You move \(direction)."
          return moveString + "\n" + gameState.lookAround(in: currentRoom)
        } else {
          return "Det finns inget rum åt det hållet."
        }
      } else {
        return "Vägen åt \(direction) är låst."
      }
    } else {
      return "Du kan inte gå åt det hållet."
    }
  }
}

struct UseCommand: Command {

  func execute(arguments: [String], gameState: GameState) -> String {
    let cleanedArguments = CommandUtilities.cleanArguments(arguments)
    guard !cleanedArguments.isEmpty else {
      return "Vad vill du använda?"
    }

    if let onIndex = cleanedArguments.firstIndex(of: "on"), onIndex + 1 < cleanedArguments.count {
      let itemName = cleanedArguments[..<onIndex].joined(separator: " ")
      let targetName = cleanedArguments[(onIndex + 1)...].joined(separator: " ")
      return useItem(named: itemName, on: targetName, with: gameState)
    } else {
      let objectName = cleanedArguments.joined(separator: " ")
      // Check if the object is a feature in the current room
      if let _ = gameState.gameRooms[gameState.currentRoomID]?.features?.first(where: {
        $0.keywords.contains(where: { keyword in keyword.caseInsensitiveEquals(objectName) })
      }) {
        return useFeature(named: objectName, with: gameState)
      } else {
        return useItem(named: objectName, on: "self", with: gameState)
      }
    }
  }

  func useItem(named itemName: String, on target: String, with gameState: GameState)
    -> String
  {
    if !gameState.hasItem(named: itemName) {
      return "Du har inte \(itemName) i din utrustning."
    }

    guard
      let item = gameState.playerInventory.first(where: { $0.name.caseInsensitiveEquals(itemName) })
    else {
      return "Unexpected error: Couldn't find the \(itemName) in your inventory."
    }

    let interactionResultMessage = handleInteraction(using: item, on: target, with: gameState)
    return interactionResultMessage
  }

  // Step 3: Add a useFeature function
  func useFeature(named featureName: String, with gameState: GameState) -> String {
    return handleInteraction(using: nil, on: featureName, with: gameState)
  }

  func handleInteraction(using item: Item?, on target: String, with gameState: GameState) -> String {
    if var item = item {
        
        // Check for interactions using an item on another item in inventory
        if gameState.hasItem(named: target) {
            if let targetItem = gameState.playerInventory.first(where: { $0.name.caseInsensitiveEquals(target) }),
               let interactionIndex = item.interactions?.firstIndex(where: { $0.withItem.caseInsensitiveEquals(targetItem.name) }) {
                
                if let interaction = item.interactions?[interactionIndex], interaction.hasExecuted != true || interaction.isRepeatable ?? false {
                    item.interactions?[interactionIndex].hasExecuted = true
                    return executeInteraction(interaction: interaction, with: gameState)
                }
                return "Du har redan gjort det."
            }
        }
        
        // Handle interactions involving an item and a character
        if let characterIndex = gameState.gameRooms[gameState.currentRoomID]?.characters?.firstIndex(
            where: { $0.name.caseInsensitiveEquals(target) }),
           let interactionIndex = gameState.gameRooms[gameState.currentRoomID]?.characters?[characterIndex]
            .interactions?.firstIndex(where: { $0.withItem.caseInsensitiveEquals(item.name) }) {
            
            if let interaction = gameState.gameRooms[gameState.currentRoomID]?.characters?[characterIndex]
                .interactions?[interactionIndex], interaction.hasExecuted != true || interaction.isRepeatable ?? false {
                gameState.gameRooms[gameState.currentRoomID]?.characters?[characterIndex].interactions?[interactionIndex]
                    .hasExecuted = true
                return executeInteraction(interaction: interaction, with: gameState)
            }
            return "Du har redan gjort det."
        }

        // Handle interactions involving an item and a feature
        if let featureIndex = gameState.gameRooms[gameState.currentRoomID]?.features?.firstIndex(
            where: { $0.keywords.contains(where: { keyword in keyword.caseInsensitiveEquals(target) }) }),
           let interactionIndex = gameState.gameRooms[gameState.currentRoomID]?.features?[featureIndex]
            .interactions?.firstIndex(where: { $0.withItem.caseInsensitiveEquals(item.name) }) {
            
            if let interaction = gameState.gameRooms[gameState.currentRoomID]?.features?[featureIndex]
                .interactions?[interactionIndex], interaction.hasExecuted != true || interaction.isRepeatable ?? false {
                gameState.gameRooms[gameState.currentRoomID]?.features?[featureIndex].interactions?[interactionIndex]
                    .hasExecuted = true
                return executeInteraction(interaction: interaction, with: gameState)
            }
            return "Du har redan gjort det."
        }

    } else {
        // Handle interactions involving only a feature (no item)
        if let featureIndex = gameState.gameRooms[gameState.currentRoomID]?.features?.firstIndex(
            where: { $0.keywords.contains(where: { keyword in keyword.caseInsensitiveEquals(target) }) }),
           let interactionIndex = gameState.gameRooms[gameState.currentRoomID]?.features?[featureIndex]
            .interactions?.firstIndex(where: {
                $0.withItem == "" || $0.withItem.caseInsensitiveEquals("none")
            }) {
            
            if let interaction = gameState.gameRooms[gameState.currentRoomID]?.features?[featureIndex]
                .interactions?[interactionIndex], interaction.hasExecuted != true {
                gameState.gameRooms[gameState.currentRoomID]?.features?[featureIndex].interactions?[interactionIndex]
                    .hasExecuted = true
                return executeInteraction(interaction: interaction, with: gameState)
            }
            return "Du har redan gjort det."
        }
    }

    return "Du gjorde ett försök men ingenting hände."
}


  func executeInteraction(interaction: Interaction, with gameState: GameState) -> String {
    switch interaction.action {
    case "reveal":
      if let item = interaction.spawnItem {
        // Add the revealed item to the player's inventory or to the room
        gameState.gameRooms[gameState.currentRoomID]?.items.append(item)
      }
    case "add_to_inventory":
      if let item = interaction.spawnItem {
        gameState.playerInventory.append(item)
      }
    case let str where str.lowercased().starts(with: "unlock_path_"):
      let pathName = String(str.dropFirst(12)).capitalized
      gameState.gameRooms[gameState.currentRoomID]?.paths[pathName]?.isLocked = false
   case let str where str.lowercased().starts(with: "move_"):
    if let roomID = Int(String(str.dropFirst(5))) {
        gameState.currentRoomID = roomID
            return "\(interaction.message)\n \(gameState.lookAround(in: gameState.getCurrentRoom()!))"
    }
    default:
      break
    }

    // Handle postInteraction if it exists
    if let postInteractions = interaction.postInteraction {
      for postAction in postInteractions {
        switch postAction.action {
        case "remove_item":
          if let index = gameState.playerInventory.firstIndex(where: {
            $0.name.caseInsensitiveEquals(postAction.item)
          }) {
            gameState.playerInventory.remove(at: index)
          }
        // Add more cases as you introduce more postInteraction actions
        case "game_complete":
          gameState.isGameCompleted = true
        default:
          break
        }
      }
    }

    // Return the original message after processing postInteraction
    return interaction.message
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
    let cleanedArguments = CommandUtilities.cleanArguments(arguments)
    if cleanedArguments.count > 0 {
      let itemName = cleanedArguments.joined(separator: " ")
      return getItem(named: itemName, with: gameState)
    } else {
      return "Vad är det du vill plocka upp?"
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
    return "Det finns ingen \(itemName) att plocka upp."
  }

}

struct TalkCommand: Command {
  func execute(arguments: [String], gameState: GameState) -> String {
    if arguments.count >= 2 && arguments[0] == "to" {
      let characterName = arguments.dropFirst().joined(separator: " ")
      return talkToCharacter(named: characterName, with: gameState)
    } else {
      return "Vem vill du prata med?"
    }
  }

  func talkToCharacter(named characterName: String, with gameState: GameState) -> String {
    if let character = gameState.gameRooms[gameState.currentRoomID]?.characters?.first(where: {
      $0.name.caseInsensitiveEquals(characterName)
    }) {
      let dialogues = character.dialogue
      let randomDialogue = dialogues?.randomElement() ?? "..."

      return "\(characterName.capitalized): \"\(randomDialogue)\""
    } else {
      return "\(characterName.capitalized) är inte här."
    }
  }
}

struct DropCommand: Command {
  func execute(arguments: [String], gameState: GameState) -> String {
    let cleanedArguments = CommandUtilities.cleanArguments(arguments)
    if cleanedArguments.count > 0 {
      let itemName = cleanedArguments.joined(separator: " ")
      return dropItem(named: itemName, with: gameState)
    } else {
      return "Vad vill du lägga ner?"
    }
  }

  func dropItem(named itemName: String, with gameState: GameState) -> String {
    if let index = gameState.playerInventory.firstIndex(where: {
      $0.name.caseInsensitiveEquals(itemName)
    }) {
      let item = gameState.playerInventory.remove(at: index)
      gameState.gameRooms[gameState.currentRoomID]?.items.append(item)
      return "Du släppte \(itemName)."
    } else {
      return "Du har ingen \(itemName) i din utrusting."
    }
  }
}

struct QuitCommand: Command {
  func execute(arguments: [String], gameState: GameState) -> String {
    return "Hej då, och tack för att du spelade!"
  }
}

struct HelpCommand: Command {
  func execute(arguments: [String], gameState: GameState) -> String {
    return "Available commands:\n" + "look [at <target>]\n" + "go <direction>\n"
      + "use <item> [on <target>]\n"
      + "inventory\n" + "get <item>\n" + "talk to <character>\n" + "drop <item>\n"
      + "examine <item>\n" + "quit\n"
      + "help"
  }
}

struct ExamineCommand: Command {
  func execute(arguments: [String], gameState: GameState) -> String {
    let cleanedArguments = CommandUtilities.cleanArguments(arguments)
    if cleanedArguments.isEmpty {
      return "Vad vill du undersöka?"
    }

    let itemName = cleanedArguments.joined(separator: " ")

    // 1. Check player's inventory
    if let item: Item = gameState.playerInventory.first(where: {
      $0.name.caseInsensitiveEquals(itemName)
    }) {
      return item.description
    }

    guard let room = gameState.getCurrentRoom() else {
      return "Error: You seem to be in an unknown location!"
    }

    // 2. Check items in the room
    if let item = room.items.first(where: { $0.name.caseInsensitiveEquals(itemName) }) {
      return item.description
    }

    // 3. Check features in the room using keywords
    if let feature = room.features?.first(where: {
      $0.keywords.contains(where: { $0.caseInsensitiveEquals(itemName) })
    }) {
      return feature.description
    }

    // 4. Check characters in the room
    if let character = room.characters?.first(where: { $0.name.caseInsensitiveEquals(itemName) }) {
      return character.description
    }

    // 5. Return not found message
    return "Du hittar ingen \(itemName) att undersöka."
  }
}
