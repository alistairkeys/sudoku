import std/[os, strutils, unittest]
import sudokugen {.all.}
import sharedtypes

proc populateFromArr(grid: var SudokuGrid, stuff: openArray[string]) =
  assert stuff.high >= grid.high
  for y in 0 .. grid.high:
    assert stuff[y].high >= grid[y].high
    for x in 0 .. grid[y].high:
      grid[y][x] = stuff[y][x]

func testDir(): string =
  let stuff = splitPath currentSourcePath()
  return stuff[0].replace("\\", "/") & "/"

proc runAllTests() =
  suite "Sudoku gen - loadPuzzleFromFile":
    test "Loads valid puzzle":
      var sudokuGridFromFile, expectedGrid: SudokuGrid
      populateFromArr(expectedGrid, [
        "         ",
        " 7  46   ",
        "62   71  ",
        "  675 43 ",
        "7 2 19 8 ",
        "  5  2   ",
        " 8 165   ",
        "4 1   92 ",
        " 5  9 6  "
      ])
      loadPuzzleFromFile(sudokuGridFromFile, testDir() & "../src/data/puzzles/easy/001.txt")
      check sudokuGridFromFile == expectedGrid

  suite "Sudoko gen - transformPuzzle":
    test "Transpose digits":
      var
        transposeMeGrid: SudokuGrid
        expectedGrid: SudokuGrid
        transforms = PuzzleTransformations(
          transforms: { transposeDigits },
          transposed: ['2', '3', '4', '5', '6', '7', '8', '9', '1']
        )
      let
        original = [
          "111111111",
          "222222222",
          "333333333",
          "444444444",
          "555555555",
          "666666666",
          "777777777",
          "888888888",
          "999999999"
        ]
        expected = [
          "222222222",
          "333333333",
          "444444444",
          "555555555",
          "666666666",
          "777777777",
          "888888888",
          "999999999",
          "111111111"
        ]

      populateFromArr(transposeMeGrid, original)
      populateFromArr(expectedGrid, expected)
      transformPuzzle(transposeMeGrid, transforms)
      check transposeMeGrid == expectedGrid

    test "Transpose digits":
      var
        transposeMeGrid: SudokuGrid
        expectedGrid: SudokuGrid
        transforms = PuzzleTransformations(
          transforms: { flipHorizontally }
        )
      let
        original = [
          "123456789",
          "234567891",
          "345678912",
          "456789123",
          "567891234",
          "678912345",
          "789123456",
          "891234567",
          "912345678"
        ]
        expected = [
          "987654321",
          "198765432",
          "219876543",
          "321987654",
          "432198765",
          "543219876",
          "654321987",
          "765432198",
          "876543219"
        ]

      populateFromArr(transposeMeGrid, original)
      populateFromArr(expectedGrid, expected)
      transformPuzzle(transposeMeGrid, transforms)
      check transposeMeGrid == expectedGrid

    test "Flip vertically":
      var
        transposeMeGrid: SudokuGrid
        expectedGrid: SudokuGrid
        transforms = PuzzleTransformations(
          transforms: { flipVertically }
        )
      let
        original = [
          "123456789",
          "234567891",
          "345678912",
          "456789123",
          "567891234",
          "678912345",
          "789123456",
          "891234567",
          "912345678"
        ]
        expected = [
          "912345678",
          "891234567",
          "789123456",
          "678912345",
          "567891234",
          "456789123",
          "345678912",
          "234567891",
          "123456789"
        ]

      populateFromArr(transposeMeGrid, original)
      populateFromArr(expectedGrid, expected)
      transformPuzzle(transposeMeGrid, transforms)
      check transposeMeGrid == expectedGrid

    test "Rotate":
      var
        rotateMeGrid: SudokuGrid
        expectedGrid: SudokuGrid
        transforms = PuzzleTransformations(
          transforms: { rotate },
          rotateCount: 1
        )
      let
        original = [
          "111111111",
          "222222222",
          "333333333",
          "444444444",
          "555555555",
          "666666666",
          "777777777",
          "888888888",
          "999999999"
        ]
        expected = [
          "987654321",
          "987654321",
          "987654321",
          "987654321",
          "987654321",
          "987654321",
          "987654321",
          "987654321",
          "987654321"
        ]

      populateFromArr(rotateMeGrid, original)
      populateFromArr(expectedGrid, expected)
      transformPuzzle(rotateMeGrid, transforms)
      assert rotateMeGrid == expectedGrid

      let expected2 = [
        "999999999",
        "888888888",
        "777777777",
        "666666666",
        "555555555",
        "444444444",
        "333333333",
        "222222222",
        "111111111"
      ]
      populateFromArr(expectedGrid, expected2)
      populateFromArr(rotateMeGrid, original)
      transforms.rotateCount = 2
      transformPuzzle(rotateMeGrid, transforms)
      assert rotateMeGrid == expectedGrid

    test "Shuffle rows":
      discard

    test "Shuffle columns":
      discard

when isMainModule:
  runAllTests()