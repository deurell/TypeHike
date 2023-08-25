import Foundation

public class AdventureEngine {
  private var gameState: GameState
  private var commandParser: CommandParser

  public init() {
    func loadGameData() -> GameState {
      guard let mapPath = Bundle.module.path(forResource: "map", ofType: "json") else {
        fatalError("could not find map.json")
      }
      do {
        let data = try Data(contentsOf: URL(fileURLWithPath: mapPath))
        let gameData = try JSONDecoder().decode(GameData.self, from: data)
        let gameRooms = Dictionary(uniqueKeysWithValues: gameData.rooms.map { ($0.id, $0) })
        let currentRoomID = gameData.startingRoom
        return GameState(currentRoomID: currentRoomID, gameRooms: gameRooms, playerInventory: [])
      } catch {
        fatalError("Error loading game data: \(error)")
      }
    }

    self.gameState = loadGameData()
    self.commandParser = CommandParser(gameState: gameState)
  }

  public func processCommand(input: String) -> String {
    let (parsedCommand, arguments) = commandParser.parse(input: input)

    guard let command = parsedCommand else {
      return "I don't understand that command."
    }

    return command.execute(arguments: arguments, gameState: gameState)
  }

  public func startGame() -> String {
    return printCurrentRoomDescription()
  }

  private func printCurrentRoomDescription() -> String {
    return gameState.gameRooms[gameState.currentRoomID]?.description ?? ""
  }
}
