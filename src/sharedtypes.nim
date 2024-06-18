type
  SudokuGrid* = array[9, array[9, char]]

  SudokuNode* = ref object
    puzzle*: SudokuGrid
    rows*: byte
    cols*: byte

  Difficulty* = enum
    easy, medium, difficult
