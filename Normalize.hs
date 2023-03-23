module Normalize (normalize_data) where
import Data.List


---- READ ----

-- remove last line \n
clean_last :: String -> String
clean_last (string) = case string of
    ("")   -> error "empty file"
    (a:"") -> ""
    (a:b)  -> [a] ++ clean_last b


-- tokenize string 
tokenize :: Char -> String -> [String]
tokenize c xs = case break (==c) xs of 
    (ls, "") -> [ls]
    (ls, x:rs) -> ls : tokenize c rs


-- token list to float list
format :: [[String]] -> [[Float]]
format string_list = map (map (read :: String -> Float)) string_list


read_data :: String -> [[Float]]
read_data contents =
    let 
        clean_string = (clean_last(contents))
        tokens = map (tokenize '\t') (tokenize '\n' clean_string)
    in
    format tokens


--- NORMALIZE ---

-- normalize one single list
normalize_aux :: [Float] -> [Float]
normalize_aux input_list =
    let max_value = foldl max 0 input_list in
    fmap (/ max_value) input_list


-- main
normalize_data :: IO([[Float]])
normalize_data = do

    -- read data
    contents <- readFile "data.txt"
    let formatted_contents = read_data contents

    -- auxiliar data
    let instances = length formatted_contents
    let dimension = length (tail (head formatted_contents))

    -- normalize
    let transposed_contents = transpose formatted_contents
    let normalized_data = map (normalize_aux) transposed_contents
    let normalized_original = transpose normalized_data

    return normalized_original

