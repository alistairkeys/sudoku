## A simple build script to create the app and its dependencies.  You
## can compile and run it with:
##
## nim c -r build.nim
##
## I was originally going to do it as a Nimble task but eh, whatever.

import std/[os, osproc, sequtils, strformat, strutils]

const appName = "sudoku"

proc main() =
  try:
    echo "-> Removing the bin dir (if it exists)"
    removeDir("./bin")
  except:
    echo "WARNING: Couldn't remove the bin directory"

  echo "-> Creating the bin directories"
  createDir("./bin/data")

  echo "-> Building the application"
  var opts = fmt"./src/{appName}.nim.cfg".lines
        .toSeq
        .filterIt(it.len > 0 and not it.startsWith("#"))
        .join(" ")
  echo "OPTS: ", opts
  discard execCmd(fmt"nimble build {opts} -y --silent")
  moveFile(fmt"./{appName}.exe", fmt"./bin/{appName}.exe")

  echo "-> Copying data files"
  copyDir("./src/data", "./bin/data")

when isMainModule:
  echo "Building the release"
  try:
    main()
  finally:
    echo "Done - check the bin directory"
