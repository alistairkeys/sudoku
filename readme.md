# Sudoku
## What is this?
This is Sudoku, the puzzle game where you place the digits 1 to 9 in a 9x9 grid.
Each row, column and 3x3 subgrid must contain only one of each 1-9 digit.

## Dragons be here
I will tidy this project up at some point - it's not pretty in its
current form.

This project still needs a little TLC at the moment but it's not far off being
useful. Two particularly nasty ways to break it: it saves an 'in progress'
file but there's some infinite loop if you close the app and reopen it that I need
to debug. Also, using the 'Check' button behaves strangely. I'll debug these
soon (and possibly move it to libraries I trust more, like Boxy or Raylib,
since I always seem to have 'window not responding'-style issues with SDL2 for
some reason).

## How do I build it?
This game is written in [Nim](https://nim-lang.org).  Download Nim as per the
instructions on that site (you'll end with both Nim and a GCC compiler like
MinGW).

A file exists at the top-level called 'build.nim' that compiles everything
into a 'bin' folder.

You'll need to grab the SDL2 DLLs separately. I think the following
are necessary (at least):

* SDL2.dll
* SDL2_ttf.dll
* SDL2_mixer.dll
* libmpg123-0.dll

... but I've never sat down and exhaustively checked because I'll
probably throw away SDL2 and switch to Boxy or similar at some
point.

## How do I play it?
A new game starts with a partially-filled grid.  Move using the cursor keys or
the mouse and press a number from 1 to 9 to populate a square.  Pressing the
Delete or backspace keys will clear the square (if it's not pre-populated at
the puzzle start).

# Any other notes
Background image:
https://pixabay.com/photos/sudoku-logic-game-game-puzzle-pen-5844655/

# Todo / Rainy day work:
* Move to Boxy? Lots of possible SDL-related naffness as always
* Finish transforms (shuffling rows/columns)
* Hook up sounds (or remove them?)
* Improve keyboard navigation (might be improved via Boxy?)
* Possibly update build.nim to fetch SDL2 DLLs?