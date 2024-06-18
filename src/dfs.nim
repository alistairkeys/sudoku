#[
  Depth-first search of a Sudoku puzzle based on Python code in the following
  Medium article:

  https://medium.com/nerd-for-tech/solve-sudoku-using-depth-first-search-algorithm-dfs-in-python-2be3caa08ccd

  I need to compare it with Peter Norvig's implementation some day to see if
  his is a refinement or the same idea:

  https://norvig.com/sudopy.shtml
  https://norvig.com/sudoku.html
]#

import std/[options, tables]
import sharedtypes

proc newSudokuNode*(squares: SudokuGrid): SudokuNode =
  SudokuNode(puzzle: squares, rows: 9, cols: 9)

proc hasNode(others: seq[SudokuNode], self: SudokuNode): bool =
  for other in others:
    if equalMem(self.puzzle[0][0].addr, other.puzzle[0][0].addr,
        sizeof SudokuGrid):
      return true
  return false

proc checkRow(self: SudokuNode, row: byte, value: char): bool =
  for col in 0'u8 ..< self.cols:
    if value == self.puzzle[row][col]:
      return false
  return true

proc checkCol(self: SudokuNode, col: byte, value: char): bool =
  for row in 0'u8 ..< self.rows:
    if value == self.puzzle[row][col]:
      return false
  return true

proc checkSquare(self: SudokuNode, row, col: byte, value: char): bool =
  let squareRowStart = (row div 3) * 3
  let squareColStart = (col div 3) * 3

  for row in squareRowStart ..< squareRowStart + 3:
    for col in squareColStart ..< squareColStart + 3:
      if self.puzzle[row][col] == value:
        return false
  return true

proc findFirstEmptySlot(self: SudokuNode): Option[tuple[row: byte, col: byte]] =
  for row in 0'u8 ..< self.rows:
    for col in 0'u8 ..< self.cols:
      if self.puzzle[row][col] == ' ':
        return some (row, col)

proc extendNode(self: SudokuNode): seq[SudokuNode] =
  let rowColOpt = findFirstEmptySlot(self)
  if rowColOpt.isSome:
    let rowCol = rowColOpt.get
    for num in '1' .. '9':
      if self.checkRow(rowCol.row, num) and self.checkCol(rowCol.col, num) and
          self.checkSquare(rowCol.row, rowCol.col, num):
        var newPuzzle = deepCopy(self.puzzle)
        newPuzzle[rowCol.row][rowCol.col] = num
        result.add newSudokuNode(newPuzzle)

proc isSolution*(self: SudokuNode): bool =
  var counts: CountTable[char]
  for row in 0'u8 ..< self.rows:
    for col in 0'u8 ..< self.cols:
      counts.inc self.puzzle[row][col]

  for ch in '0'..'9':
    if not counts.hasKey(ch) or counts[ch] != 9:
      return false
  return true

proc search*(squares: SudokuGrid): Option[tuple[solution: SudokuGrid, steps: int]] =
  var
    frontier: seq[SudokuNode]
    visitedVertex: seq[SudokuNode]
    numberOfSteps: int

  frontier.add newSudokuNode(squares)

  while true:
    inc numberOfSteps

    if frontier.len == 0:
      echo "No Solution Found"
      break

    let selectedNode = frontier.pop()
    visitedVertex.add selectedNode

    # Check if the selectedNode is the solution
    if selectedNode.isSolution:
      echo "Found solution in ", numberOfSteps, " steps"
      echo selectedNode.puzzle.repr
      return some (deepCopy selectedNode.puzzle, numberOfSteps)

    for newNode in selectedNode.extendNode():
      # Add the extended nodes in the frontier
      if not visitedVertex.hasNode(newNode) and not frontier.hasNode(newNode):
        frontier.add newNode
