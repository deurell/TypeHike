class CommandParser {
  private var gameState: GameState

  init(gameState: GameState) {
    self.gameState = gameState
  }

  private var commands: [String: Command] = [
    "titta": LookCommand(),
    "gå": GoCommand(),
    "använd": UseCommand(),
    "ryggsäck": InventoryCommand(),
    "ta": GetCommand(),
    "tala": TalkCommand(),
    "släpp": DropCommand(),
    "sluta": QuitCommand(),
    "hjälp": HelpCommand(),
    "undersök": ExamineCommand(),
  ]

  private var commandAliases: [String: String] = [
    "ta upp": "ta",
    "u": "ryggsäck",
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
    "ge": "använd",
  ]

  private func resolveAlias(_ command: String) -> String {
    let transformedCommand = handleGiveCommand(command: command)
    let lowercasedCommand = transformedCommand.lowercased()

    if let actualCommand = commandAliases[lowercasedCommand] {
      return actualCommand
    }
    for (alias, actualCommand) in commandAliases {
      if lowercasedCommand == alias || lowercasedCommand.starts(with: "\(alias) ") {
        return actualCommand + transformedCommand.dropFirst(alias.count)
      }
    }
    return transformedCommand
  }

  private func handleGiveCommand(command: String) -> String {
    if command.lowercased().starts(with: "ge ") && command.contains(" till ") {
      return command.replacingOccurrences(of: " till ", with: " på ")
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
