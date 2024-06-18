import std/[algorithm, options, os, random, sequtils, setutils, streams, strformat, strutils]
import sharedtypes

type
  PuzzleTransformation* = enum
    transposeDigits
    flipHorizontally
    flipVertically
    rotate
    shuffleRows
    shuffleColumns

  PuzzleTransformationSet* = set[PuzzleTransformation]

  RowColumnShuffle* = enum
    abc = 0, acb, bac, bca, cab, cba

  PuzzleTransformations* = object
    transforms*: PuzzleTransformationSet
    transposed*: array['1'..'9', '1'..'9']
    rowShuffles*: array[3, RowColumnShuffle]
    columnShuffles*: array[3, RowColumnShuffle]
    rotateCount*: int # count of 90 degree rotations (1 = 90, 2 = 180, 3 = 270).

const
  allTransformations* = PuzzleTransformation.fullSet

proc loadPuzzleFromStream*(grid: var SudokuGrid, s: FileStream) =
  var row = 0
  while not s.atEnd:
    var l = s.readLine
    if l.len == 0: continue
    var col = 0
    echo "LINE: ", l
    for idx, ch in l:
      if ch == '.':
        grid[row][col] = ' '
        inc col
      elif ch in Digits:
        grid[row][col] = ch
        inc col
      if col > grid[row].high:
        break
    inc row
    if row > grid.high:
      break
  echo "Grid after loading from stream: ", grid

proc loadPuzzleFromFile*(grid: var SudokuGrid, path: string) =
  echo "Loading ", path
  var s = newFileStream(path)
  try:
    loadPuzzleFromStream(grid, s)
  finally:
    s.close()

proc rotate(grid: var SudokuGrid; howManyTimes: int = 1) =
  assert howManyTimes in 1 .. 3
  var output: SudokuGrid

  for _ in 0 ..< howManyTimes:
    for y in 0 .. output.high:
      for x in 0 .. output[y].high:
        output[y][x] = grid[output.high - x][y]

    grid = output

proc transformPuzzle(grid: var SudokuGrid, transforms: PuzzleTransformations) =
  echo "*** transform puzzle: ", transforms
  if transposeDigits in transforms.transforms:
    echo "Applying transform - transpose digits"

    for row in grid.mitems:
      for idx, ch in row.mpairs:
        if ch in {'1'..'9'}:
          row[idx] = transforms.transposed[ch]

  if rotate in transforms.transforms:
    echo "Applying transform - rotate grid ", transforms.rotateCount, " time(s)"
    rotate(grid, transforms.rotateCount)

  if flipHorizontally in transforms.transforms:
    echo "Applying transform - flip horizontally"
    for y in 0 .. grid.high:
      reverse(grid[y])

  if flipVertically in transforms.transforms:
    echo "Applying transform - flip vertically"
    for y in 0 ..< grid.high div 2:
      for x in 0 .. grid[y].high:
        swap(grid[y][x], grid[grid.high - y][x])

  if shuffleRows in transforms.transforms:
    echo "Applying transform - shuffle rows"
    #abc = 0, acb, bac, bca, cab, cba
    # todo: complete this
    case transforms.rowShuffles[0]
      of abc: discard # no swap
      of acb: discard # swap grid[1] with grid[2]
      of bac: discard # swap grid[0] with grid[1]
      of bca: discard # swap grid[0] with grid[1], grid[1] with grid[2]
      of cab: discard # swap grid[0] with grid[2], grid[1] with grid[2]
      of cba: discard # swap grid[0] with grid[2]

  if shuffleColumns in transforms.transforms:
    echo "Applying transform - shuffle columns"
    discard # TODO: change the columns


proc generatePuzzleOfDifficulty*(grid: var SudokuGrid, difficulty: Difficulty = easy) =
  let
    puzzles = walkFiles(fmt"data/puzzles/{difficulty}/*.txt").toSeq
    which = rand(puzzles.high)
  loadPuzzleFromFile(grid, puzzles[which])

  var transforms: PuzzleTransformations
  var transposedDigits: array['1'..'9', '1'..'9']
  for ch in '1'..'9': transposedDigits[ch] = ch
  shuffle transposedDigits

  transforms.transposed = transposedDigits
  transforms.transforms.incl transposeDigits


  if rand(1) == 1:
    transforms.transforms.incl flipHorizontally
  if rand(1) == 1:
    transforms.transforms.incl flipVertically

  transforms.rotateCount = rand(4)
  if transforms.rotateCount > 0:
    transforms.transforms.incl rotate

  if rand(1) == 1:
    transforms.transforms.incl shuffleRows
  if rand(1) == 1:
    transforms.transforms.incl shuffleColumns

  transformPuzzle(grid, transforms)
  echo("grid after transform: ", grid)