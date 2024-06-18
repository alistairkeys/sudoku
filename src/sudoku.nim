import std/[options, os, streams, strutils, sugar, tables, times]
import sdl2_nim/sdl
import framework/[sdlapp, sdlgfx, sdlimg]
import framework/ui/[dialog, dimensioned, label, menu, uiobject, uistate]
import sharedtypes, dfs, sudokugen

const
  inProgressSaveFile = "data/puzzles/inprogress.txt"

  # Display-related constants
  # MARK: constants
  buttonColour = sdl.Color(r: 255, g: 255, b: 255)
  buttonActiveColour = sdl.Color(r: 255, g: 255, b: 225)

  squareSize = 60
  gridWidthAndHeight = 9 * squareSize
  gridLeft = (1280 - gridWidthAndHeight) div 2
  gridTop = (720 - gridWidthAndHeight) div 2
  gridRight = gridLeft + gridWidthAndHeight
  gridBottom = gridTop + gridWidthAndHeight
  # End of display-related constants

  newGameButtonIndex = 0
  resetButtonIndex = 1
  checkButtonIndex = 2

type
  GameState* = enum
    inProgress, victory, needsReset, selectDifficulty

  CheckFinishedResult* = enum
    PotentiallyValid, FullySolved, Incorrect

  InitGameAction = enum
    ResetToOriginalState, LoadInProgressGame, GenerateRandomPuzzle

  SudokuGame* = object
    squares: SudokuGrid
    assignedAtStart: set[0..80]
    digitCounts: CountTable[char]
    startTime: DateTime
    state*: GameState = inProgress
    difficulty: Difficulty
    gameChecked: Option[tuple[result: CheckFinishedResult, date: DateTime]]

  Gui = object
    victoryDialog: Dialog
    incorrectDialog: Dialog
    maybeOkDialog: Dialog
    labels: seq[Label]
    buttons: seq[Label] # No separate button UI element yet
    difficultyMenu: Menu
    backgroundImage: Image
    selectedSquare: tuple[x: int, y: int]

proc setDigitCountsInGui(gui: var Gui, game: SudokuGame) =
  for idx in '1' .. '9':
    let
      intIdx = parseInt $idx
      count = game.digitCounts.getOrDefault(idx, 0)
      col = sdl.Color(r: 0, g: 0, b: 0) # there's a bug with colours in the UI at the mo
        #[if count < 9:  sdl.Color(r: 0, g: 0, b: 0)
        elif count == 9: sdl.Color(r: 0, g: 255, b: 128)
        else: sdl.Color(r: 255, g: 0, b: 0) ]#
    gui.labels[intIdx].caption = $(intIdx) & " = " & $count
    gui.labels[intIdx].foregroundColour = col

proc firstTimeGuiInit(gui: var Gui, game: SudokuGame, renderer: sdl.Renderer) =
  gui.backgroundImage = newImage()
  discard gui.backgroundImage.load(renderer, "data/gfx/background.jpg")

  let difficulties = @[
    newLabel("Easy", 0, 0),
    newLabel("Medium", 0, 0),
    newLabel("Difficult", 0, 0)
  ]
  gui.difficultyMenu = newMenu(some "Select Difficulty", difficulties, (1280 - 300) div 2, 200)

  gui.labels.add newLabel("Counts", 20, gridTop)
  for x in 1 .. 9:
    gui.labels.add newLabel($x & " = 0", 20, gridTop + (x * 25))

  var top = gridTop
  gui.buttons.add newLabel("New Game", gridRight + 100, gridTop,
      backgroundColour = buttonColour, transparent = false)
  gui.buttons[newGameButtonIndex].marginX = 13
  gui.buttons[newGameButtonIndex].marginY = 6

  inc top, 50
  gui.buttons.add newLabel("Reset", gridRight + 100, top,
      backgroundColour = buttonColour, transparent = false)
  gui.buttons[resetButtonIndex].marginX = 25
  gui.buttons[resetButtonIndex].marginY = 6

  inc top, 50
  gui.buttons.add newLabel("Check", gridRight + 100, top,
      backgroundColour = buttonColour, transparent = false)
  gui.buttons[checkButtonIndex].marginX = 25
  gui.buttons[checkButtonIndex].marginY = 6

  gui.maybeOkDialog = newDialog(title = "No mistakes found", caption = [
        "No mistakes found!", "Your answers look good - keep going!"],
        x = (1280 - 350) div 2, y = (720 - 100) div 2, width = 350,
            height = 100, backgroundColour = sdl.Color(r: 225, g: 255, b: 185))

  gui.incorrectDialog = newDialog(title = "Mistakes found", caption = [
        "No solution found!", "Check for errors"],
        x = (1280 - 350) div 2, y = (720 - 100) div 2, width = 350,
            height = 100, backgroundColour = sdl.Color(r: 255, g: 225, b: 185))

  gui.victoryDialog = newDialog(title = "Congratulations", caption = [
        "You won. Well done!", "Time: "], x = (1280 - 200) div 2,
        y = (720 - 100) div 2, width = 200, height = 100)

  gui.setDigitCountsInGui(game)

proc drawGame(game: SudokuGame, gui: Gui, r: sdl.Renderer) =
  # MARK: DRAWGAME **
  const
    gridBackgroundColour = sdl.Color(r: 255, g: 255, b: 255)
    squareHighlightColour = sdl.Color(r: 255, g: 255, b: 225)
    squareNoHighlightColour = sdl.Color(r: 225, g: 225, b: 225)

  discard r.renderClear()
  discard gui.backgroundImage.render(r, 0, 0)

  if game.state == selectDifficulty:
    gui.difficultyMenu.draw r
    return

  for l in gui.labels:
    l.draw r

  for b in gui.buttons:
    b.draw r

  fillRect(r, Rect(x: gridLeft, y: gridTop, w: 9 * squareSize, h: 9 *
      squareSize), gridBackgroundColour)

  block highlightSquare:
    let highlightColour = if game.assignedAtStart.contains(gui.selectedSquare.y * 9 + gui.selectedSquare.x): squareNoHighlightColour else: squareHighlightColour

    fillRect(r, Rect(x: gridLeft + (gui.selectedSquare.x * squareSize), y: gridTop +
        (gui.selectedSquare.y * squareSize), w: squareSize, h: squareSize), highlightColour)

  block drawGrid:
    var top = gridTop
    var left = gridLeft
    for y in 0 .. 9:
      discard renderDrawLine(r, left, top, gridRight, top)
      inc top, squareSize

    top = gridTop
    for x in 0 .. 9:
      discard renderDrawLine(r, left, top, left, gridBottom)
      inc left, squareSize

    top = gridTop + 1
    left = gridLeft + 1
    for y in 0 .. 3:
      discard renderDrawLine(r, left, top, gridRight, top)
      inc top, (squareSize * 3)

    top = gridTop + 1
    left = gridLeft + 1
    for x in 0 .. 3:
      discard renderDrawLine(r, left, top, left, gridBottom)
      inc left, (squareSize * 3)

  block drawDigits:
    var top = gridTop + 17
    for y in 0 .. 8:
      var left = gridLeft + 24
      for x in 0 .. 8:
        if game.squares[y][x] != ' ':
          r.drawText(left, top, $game.squares[y][x], font = "bigFont")

        inc left, squareSize
      inc top, squareSize

  if game.state == victory:
    gui.victoryDialog.draw(r)
  elif game.gameChecked.isSome:
    let res = game.gameChecked.get.result
    if res == Incorrect:
      gui.incorrectDialog.draw(r)
    elif res == PotentiallyValid:
      gui.maybeOkDialog.draw(r)

proc gameComplete*(game: SudokuGame): CheckFinishedResult =
  let potentiallyValid = search(game.squares).isSome
  let allSquaresFilledIn = isSolution(newSudokuNode(game.squares))
  return
    if not potentiallyValid: echo "incorrect"; Incorrect
    elif allSquaresFilledIn: echo "fullysolved"; FullySolved
    else: echo "potentiallyvalid"; PotentiallyValid

proc calculateAssigned(game: var SudokuGame) =
  game.assignedAtStart.reset
  var idx = 0
  for y in 0 .. game.squares.high:
    for x in 0 .. game.squares[y].high:
      if game.squares[y][x] in Digits: game.assignedAtStart.incl idx
      inc idx

proc generateRandomPuzzle(game: var SudokuGame) =
  echo "Generating random puzzle"
  generatePuzzleOfDifficulty(game.squares, game.difficulty)
  echo "*** after generation: squares = ", game.squares
  game.calculateAssigned()

proc loadInProgressPuzzle(game: var SudokuGame): bool =
  result = false
  if fileExists(inProgressSaveFile):
    try:
      var s = newFileStream(inProgressSaveFile)
      defer: s.close()

      loadPuzzleFromStream(game.squares, s)

      if not s.atEnd:
        echo "Reading last line"
        let line = s.readLine
        echo "LINE: ", line
        if line.len > 2:
          game.assignedAtStart.reset
          for num in line[1..^2].split(", "):
            let pnum = parseInt(num)
            if pnum in 0..80:
              game.assignedAtStart.incl pnum
      else:
        echo "Calculating assigned"
        game.calculateAssigned()

      if game.gameComplete() != FullySolved:
        result = true
    except:
      echo "Warning: an error occurred loading the in progress game - ", $getCurrentExceptionMsg()
  else:
    echo "No in progress game to load"

proc countDigits(game: var SudokuGame) =
  game.digitCounts.clear
  for arr in game.squares:
    for ch in arr:
      if ch in Digits:
        game.digitCounts.inc ch

proc initGame*(game: var SudokuGame, action: InitGameAction) =
  echo "**** INIT GAME *** - ", action
  game.state = inProgress

  case action
    of ResetToOriginalState:
      block resetToOriginal:
        var idx = 0
        for arr in game.squares.mitems:
          for el in arr.mitems:
            if idx notin game.assignedAtStart: el = ' '
            inc idx
    of LoadInProgressGame:
      if not game.loadInProgressPuzzle():
        game.generateRandomPuzzle()
    of GenerateRandomPuzzle:
      game.generateRandomPuzzle()

  game.countDigits
  game.startTime = now()
  game.gameChecked.reset
  echo "Finished init game"

proc firstTimeGameInit(game: var SudokuGame, gui: var Gui, renderer: sdl.Renderer) =
  echo "*** FIRST TIME GAME INIT ***"
  initGame(game, LoadInProgressGame)
  firstTimeGuiInit(gui, game, renderer)
  echo "*** Finished first time init ***"

proc saveInProgressGame(game: SudokuGame) =
  if game.state != inProgress:
    echo "No in progress game to save"
    return

  var f = open(inProgressSaveFile, fmWrite)
  defer: close(f)

  var line = newString(11)
  for y in 0 .. game.squares.high:
    var idx = 0
    for x, ch in game.squares[y]:
      line[idx] = if ch in Digits: ch else: '.'
      if x in {2, 5}:
        inc idx
        line[idx] = ' '
      inc idx
    writeLine(f, line)
    if y in {2, 5}: writeLine(f, "")

  writeLine(f, game.assignedAtStart)

proc destroyGame*(game: SudokuGame) =
  if game.state == inProgress:
    echo "Saving in progress game"
    game.saveInProgressGame()
  else:
    echo "Removing in progress save file"
    if not tryRemoveFile(inProgressSaveFile):
      echo ".. failed to remove in progress save file :("

proc update*(game: var SudokuGame, gui: var Gui, ui: var UIState, r: sdl.Renderer) =
  if game.state == needsReset:
    game.initGame(ResetToOriginalState)
    setDigitCountsInGui(gui, game)

  if game.state == selectDifficulty:
    var selectedDifficulty = gui.difficultyMenu.handleInput(ui)
    if selectedDifficulty.len > 0:
      echo selectedDifficulty
      selectedDifficulty[0] = toLowerAscii(selectedDifficulty[0])
      game.difficulty = parseEnum[Difficulty](selectedDifficulty.replace(" ", ""))

      game.initGame(GenerateRandomPuzzle)
      setDigitCountsInGui(gui, game)

  elif game.state != victory:
    let oldSelectedSquare = gui.selectedSquare

    if ui.keys[getScanCodeFromKey K_LEFT].pressed:
      gui.selectedSquare.x = if gui.selectedSquare.x == 0: 8 else: gui.selectedSquare.x - 1
    elif ui.keys[getScanCodeFromKey K_RIGHT].pressed:
      gui.selectedSquare.x = if gui.selectedSquare.x == 8: 0 else: gui.selectedSquare.x + 1
    elif ui.keys[getScanCodeFromKey K_UP].pressed:
      gui.selectedSquare.y = if gui.selectedSquare.y == 0: 8 else: gui.selectedSquare.y - 1
    elif ui.keys[getScanCodeFromKey K_DOWN].pressed:
      gui.selectedSquare.y = if gui.selectedSquare.y == 8: 0 else: gui.selectedSquare.y + 1

    var pressedKey = false
    if not game.assignedAtStart.contains(gui.selectedSquare.y * 9 + gui.selectedSquare.x):
      for k in K_1.ord .. K_9.ord:
        if ui.keys[getScancodeFromKey(KeyCode(k))].pressed:
          game.squares[gui.selectedSquare.y][gui.selectedSquare.x] = char k
          pressedKey = true

      if ui.keys[getScancodeFromKey K_DELETE].pressed or ui.keys[
          getScancodeFromKey K_BACKSPACE].pressed:
        game.squares[gui.selectedSquare.y][gui.selectedSquare.x] = ' '
        pressedKey = true

      if pressedKey:
        game.countDigits
        setDigitCountsInGui(gui, game)

        let res = game.gameComplete()
        if res == FullySolved:
          game.gameChecked = some (res, now())
          block youWon:
            game.state = victory
            let theTime = min(999, (now() - game.startTime).inSeconds)
            let suffix = if theTime == 1: " second" else: " seconds"
            Label(gui.victoryDialog.kids[2]).caption = "Time: " & $theTime & suffix

    if game.gameChecked.isSome and game.state != victory:
      if ((now() - game.gameChecked.get.date).inSeconds > 3) or (gui.selectedSquare != oldSelectedSquare) or pressedKey:
        game.gameChecked.reset

proc checkButtonClicks(game: var SudokuGame, gui: Gui, x, y: int) =
  for idx, b in gui.buttons:
    if b.inBounds(x, y):
      case idx
        of newGameButtonIndex: game.state = selectDifficulty
        of resetButtonIndex:   game.state = needsReset
        of checkButtonIndex:   game.gameChecked = some (game.gameComplete(), now())
        else:
          echo "Unhandled button click - button index", idx

proc handleSingleClick*(game: var SudokuGame, gui: var Gui, x, y: int) =
  echo "Handling single click", " x: ", x, ", y: ", y
  game.gameChecked.reset
  game.checkButtonClicks(gui, x, y)

proc handleMouseMove*(gui: var Gui, x, y: int) =
  if x in gridLeft .. gridRight and y in gridTop .. gridBottom:
    gui.selectedSquare = (x: min(8, (x - gridLeft) div squareSize),
                          y: min(8, (y - gridTop)  div squareSize))
  else:
    for b in gui.buttons:
      b.backgroundColour = if b.inBounds(x, y): buttonActiveColour else: buttonColour

proc handleMouseEvent*(game: var SudokuGame, gui: var Gui, mouseEvent: MouseEvent, x, y: int) =
  case mouseEvent
    of singleClick: handleSingleClick(game, gui, x, y)
    of mouseMove: handleMouseMove(gui, x, y)
    else: discard

when isMainModule:
  proc mainLoop =
    var
      g: SudokuGame
      gui: Gui
      app = App(initProc       : (r: sdl.Renderer) => firstTimeGameInit(g, gui, r),
                renderProc     : (r: sdl.Renderer) => drawGame(g, gui, r),
                updateProc     : (ui: var UiState, r: sdl.Renderer) => g.update(gui, ui, r),
                destroyProc    : () => g.destroyGame(),
                mouseEventProc : (me: MouseEvent, x, y: int) => g.handleMouseEvent(gui, me, x, y))
    if app.init:
      app.mainLoop
    app.exit

  echo "Starting..."
  try:
    mainLoop()
  except:
    echo "ERROR! ", $getCurrentExceptionMsg()
  finally:
    echo "Finished!"
