import Data.Vect
import Control.Monad.State

data Winner = PlayerX | PlayerO | Draw

data Piece = X | O

Show Piece where
  show X = "X"
  show O = "O"

Eq Piece where
  (==) X X = True
  (==) O O = True
  (==) _ _ = False

data Square = Empty | Filled Piece

Eq Square where
  (==) Empty Empty = True
  (==) (Filled p1) (Filled p2) = p1 == p2
  (==) _ _ = False

Show Square where
  show Empty = "_"
  show (Filled piece) = show piece

Board : Type
Board = Vect 3 (Vect 3 Square)

initBoard : Board
initBoard = [
  [Empty, Empty, Empty],
  [Empty, Empty, Empty],
  [Empty, Empty, Empty]
]

Position : Type
Position = (Fin 3, Fin 3)

data Input : Type where
  MkInput : Position -> Square -> Input

updateBoard : Input -> Board -> Board
updateBoard (MkInput (x, y) square) board = let
    row = index y board
    row' = replaceAt x square row
  in
    replaceAt y row' board

renderBoard : Board -> IO ()
renderBoard board = do
  traverse putStrLn (map show board)
  pure ()

playGame : Input -> StateT Board IO ()
playGame input = do
  modify (updateBoard input)
  board <- get
  lift $ renderBoard board

data LineType = Row | Column

Show LineType where
  show Row = "row"
  show Column = "column"

readRowOrColumn : LineType -> IO (Fin 3)
readRowOrColumn lineType = do
  putStrLn $ "Input a " ++ show lineType ++ " number (0-2). Non-integers will be interpreted as 0."
  input <- getLine
  let intInput: Integer = cast input
  let line : Maybe (Fin 3) = integerToFin intInput 3
  case line of
    Just line => pure line
    Nothing => do
      putStrLn "Not a valid number. Try again."
      readRowOrColumn lineType

readColumn : IO (Fin 3)
readColumn = readRowOrColumn Column
  
readRow : IO (Fin 3)
readRow = readRowOrColumn Row

getSquare : Fin 3 -> Fin 3 -> Board -> Square
getSquare col row board = index col (index row board)

getInput : Fin 3 -> Fin 3 -> Piece -> Board -> Maybe Input
getInput col row piece board = case (getSquare col row board) of
  Empty => Just $ MkInput (col, row) (Filled piece)
  other => Nothing

playerTurn : Piece -> StateT Board IO ()
playerTurn piece = do
  lift $ putStrLn $ "Player " ++ show piece ++ "'s turn"
  col <- lift $ readColumn
  row <- lift $ readRow
  board <- get
  case (getInput col row piece board) of
    Just input => playGame input
    Nothing => do
      lift $ putStrLn "Invalid position. Try again."
      playerTurn piece

checkLine : Square -> Square -> Square -> Maybe Winner
checkLine square0 square1 square2 = 
  case square0 of
    Filled X => case square1 of
      Filled X => case square2 of
        Filled X => Just PlayerX
        Filled O => Nothing
        Empty => Nothing
      Filled O => Nothing
      Empty => Nothing
    Filled O => case square1 of
      Filled O => case square2 of
        Filled O => Just PlayerO
        Filled X => Nothing
        Empty => Nothing
      Filled X => Nothing
      Empty => Nothing
    Empty => Nothing

checkRow : Fin 3 -> Board -> Maybe Winner
checkRow rowIdx board = let
    row = index rowIdx board
    square0 = index 0 row
    square1 = index 1 row
    square2 = index 2 row
  in
    checkLine square0 square1 square2 

checkColumn : Fin 3 -> Board -> Maybe Winner
checkColumn colIdx board = let
    row0 = index 0 board
    row1 = index 1 board
    row2 = index 2 board
    square0 = index colIdx row0
    square1 = index colIdx row1
    square2 = index colIdx row2
  in
    checkLine square0 square1 square2

checkDiagonalTLBR : Board -> Maybe Winner
checkDiagonalTLBR board = let
    row0 = index 0 board
    row1 = index 1 board
    row2 = index 2 board
    square0 = index 0 row0
    square1 = index 1 row1
    square2 = index 2 row2
  in
    checkLine square0 square1 square2

checkDiagonalTRBL : Board -> Maybe Winner
checkDiagonalTRBL board = let
    row0 = index 0 board
    row1 = index 1 board
    row2 = index 2 board
    square0 = index 2 row0
    square1 = index 1 row1
    square2 = index 0 row2
  in
    checkLine square0 square1 square2

checkDraw : Board -> Maybe Winner
checkDraw board = if (foldl (\acc, row => (hasAny row [Empty]) || acc) False board) 
                     then Nothing 
                     else Just Draw

-- exit early if we find the winner
getWinner : Maybe Winner -> Either Winner ()
getWinner maybeWinner = case maybeWinner of
  Just winner => Left winner
  Nothing => Right ()

calculateWinner : Board -> Maybe Winner
calculateWinner board = case (do
  getWinner $ checkColumn 0 board
  getWinner $ checkColumn 1 board
  getWinner $ checkColumn 2 board
  getWinner $ checkRow 0 board
  getWinner $ checkRow 1 board
  getWinner $ checkRow 2 board
  getWinner $ checkDiagonalTLBR board
  getWinner $ checkDiagonalTRBL board
  getWinner $ checkDraw board) of
    Left winner => Just winner
    Right () => Nothing

printWinner : Winner -> IO ()
printWinner PlayerX = putStrLn "X wins!"
printWinner PlayerO = putStrLn "O wins!"
printWinner Draw = putStrLn "It's a draw!"

gameLoop : StateT Board IO ()
gameLoop = do
  playerTurn X
  board <- get
  case calculateWinner board of
    Just winner => lift $ printWinner winner
    Nothing => do
      playerTurn O
      board <- get
      case calculateWinner board of
        Just winner => lift $ printWinner winner
        Nothing => gameLoop

main : IO Unit
main = do
  runStateT gameLoop initBoard 
  pure ()
  
