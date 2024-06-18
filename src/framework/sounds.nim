import sdl2_nim/sdl
import sdl2_nim/sdl_mixer as mix


# TODO: music: https://github.com/Vladar4/sdl2_nim/blob/master/examples/ex401_mixer.nim
var
  sound: mix.Chunk
  soundFilename: string
  soundChan = -1
  enabled = true

proc initSound*() =
  if mix.openAudio(mix.DefaultFrequency, # 22050
    mix.DefaultFormat, # AudioS16LSB
    mix.DefaultChannels, # 2
    1024 # chunksize in bytes
  ) != 0:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't open mixer with the given audio format: %s",
                    mix.getError())

  if mix.init(mix.InitMP3) == 0:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't initialize mixer flags: %s",
                    mix.getError())

proc play*(filename: string) =
  if enabled:
    # TODO: might need a way to differentiate between loading-and-playing
    # as one operation versus two separate actions.
    if soundFilename != filename:
      sound = mix.loadWAV filename
      soundFilename = filename
    soundChan = mix.playChannel(-1, sound, 0)

proc closeSound*() =
  while mix.init(0) != 0:
    mix.quit()

  let mixNumOpened = mix.querySpec(nil, nil, nil)
  for i in 0 ..< mixNumOpened:
    mix.closeAudio()
  mix.freeChunk(sound)

proc setEnabled*(value: bool) =
  enabled = value
