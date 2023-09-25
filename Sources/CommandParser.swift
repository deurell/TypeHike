class CommandParser {
  private var gameState: GameState

  init(gameState: GameState) {
    self.gameState = gameState
  }

  private var commands: [String: Command] = [
    "titta": LookCommand(),
    "gå": GoCommand(),
    "använd": UseCommand(),
    "utrusting": InventoryCommand(),
    "ta": GetCommand(),
    "prata": TalkCommand(),
    "släpp": DropCommand(),
    "sluta": QuitCommand(),
    "hjälp": HelpCommand(),
    "undersök": ExamineCommand(),
  ]

  private var commandAliases: [String: String] = [
    "ta upp": "ta",
    "u": "utrustning",
    "nord": "gå nord",
    "söder": "gå söder",
    "öster": "gå öster",
    "väster": "gå väster",
    "upp": "gå upp",
    "ner": "gå ner",
    "n": "gå nord",
    "s": "gå söder",
    "ö": "gå öster",
    "v": "gå väster",
    "look at": "examine",
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
