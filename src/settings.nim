import std/json

type
  Settings* = object
    sound*: bool = true

const
  settingsFile = "data/settings.json"

proc initSettings*(): Settings =
  try:
    return settingsFile.readFile.parseJson.to(Settings)
  except:
    echo "Failed to load settings! " & getCurrentExceptionMsg()

proc save*(settings: Settings) =
  try:
    let s = %settings
    settingsFile.writeFile(pretty s)
  except:
    echo "Failed to save settings! " & getCurrentExceptionMsg()
