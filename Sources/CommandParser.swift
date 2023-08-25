class CommandParser {
  private var gameState: GameState

  init(gameState: GameState) {
    self.gameState = gameState
  }

  private var commands: [String: Command] = [
    "look": LookCommand(),
    "go": GoCommand(),
    "use": UseCommand(),
    "inventory": InventoryCommand(),
    "get": GetCommand(),
    "talk": TalkCommand(),
    "drop": DropCommand(),
    "quit": QuitCommand(),
    "help": HelpCommand(),
  ]

  private var commandAliases: [String: String] = [
    "pick up": "get",
    "inv": "inventory",
    "i": "inventory",
    "move": "go",
    "north": "go north",
    "south": "go south",
    "east": "go east",
    "west": "go west",
    "up": "go up",
    "down": "go down",
    "n": "go north",
    "s": "go south",
    "e": "go east",
    "w": "go west",
  ]

  private func resolveAlias(_ command: String) -> String {
    if let actualCommand = commandAliases[command] {
      return actualCommand
    }

    for (alias, actualCommand) in commandAliases {
      if command == alias || command.starts(with: "\(alias) ") {
        return actualCommand + command.dropFirst(alias.count)
      }
    }

    return command
  }

  func parse(input: String) -> (Command?, [String]) {
    let command = resolveAlias(input).lowercased()
    let commandParts = command.split(separator: " ")

    guard !commandParts.isEmpty else {
      return (nil, [])
    }

    let action = String(commandParts[0])
    let arguments = Array(commandParts.dropFirst()).map { String($0) }
    return (commands[action], arguments)
  }
}
