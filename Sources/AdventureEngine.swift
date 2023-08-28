import Foundation

public class AdventureEngine {
  private var gameState: GameState
  private var commandParser: CommandParser

  public init(mapPath: String? = nil) {
    func loadGameData(mapPath: String) -> GameState {
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

    let actualMapPath = mapPath ?? Bundle.module.path(forResource: "map", ofType: "json")
    guard let path = actualMapPath else {
      fatalError("Could not find map.json")
    }

    self.gameState = loadGameData(mapPath: path)
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

  public func getCurrentRoomView() -> RoomView {
    guard let room = gameState.gameRooms[gameState.currentRoomID] else {
      return RoomView(
        description: "You are in a featureless void.", characters: nil, imageName: nil)
    }

    let charactersInRoom = room.characters?.map { $0.name }
    let imageName = "\(room.id)"

    return RoomView(
      description: room.description, characters: charactersInRoom, imageName: imageName)
  }
}
