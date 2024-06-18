import sdl2_nim/sdl
import sdl2_nim/sdl_image as img

template logInfo*(s) = sdl.logInfo(sdl.LogCategoryApplication, s.cstring)
template logWarn*(s) = sdl.logWarn(sdl.LogCategoryVideo, s & ": %s",
    sdl.getError())
template logCritical*(s) = sdl.logCritical(sdl.LogCategoryError, s & ": %s",
    sdl.getError())
template logCriticalImg*(s) = sdl.logCritical(sdl.LogCategoryError, s & ": %s",
    img.getError())
template logCritical*(s, err) = sdl.logCritical(sdl.LogCategoryError, s &
    ": %s", err)
