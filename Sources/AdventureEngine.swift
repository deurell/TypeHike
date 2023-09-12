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
    return LookCommand().execute(arguments: [], gameState: gameState)
  }

  public func getPlayerContext() -> PlayerContext {
    guard let room = gameState.gameRooms[gameState.currentRoomID] else {
      return PlayerContext(
        description: "You are in a featureless void.", characters: nil, imageName: nil)
    }

    let charactersInRoom = room.characters?.map { $0.name }
    let imageName = "\(room.id)"

    return PlayerContext(
      description: room.description,
      characters: charactersInRoom,
      imageName: imageName,
      inventory: gameState.playerInventory.map { $0.name },
      items: gameState.getCurrentRoom()?.items.map { $0.name } ?? [],
      features: gameState.getCurrentRoom()?.features?.compactMap { $0.keywords.first } ?? [],
      paths: gameState.getCurrentRoom()?.paths.map { $0.key } ?? [],
      isGameCompleted: gameState.isGameCompleted
    )
  }

    public func serializeCurrentState() -> String? {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(gameState)
            return String(data: data, encoding: .utf8)
        } catch {
            print("Failed to serialize current state: \(error)")
            return nil
        }
    }
    
    public func deserializeState(from jsonString: String) -> Bool {
        guard let data = jsonString.data(using: .utf8) else {
            print("Failed to convert string to data")
            return false
        }
        
        let decoder = JSONDecoder()
        do {
            gameState = try decoder.decode(GameState.self, from: data)
            return true
        } catch {
            print("Failed to deserialize state: \(error)")
            return false
        }
    }

}
