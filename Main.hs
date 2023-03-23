module Main (main) where
import Normalize (normalize_data)
import System.Random hiding (split)
import Data.List as L
import Data.Vector as V



----- # RANDOM VALUE GENERATING # -----


next_random :: Int -> Int -> Int
next_random limit seed =
    fst (randomR (0, limit) (mkStdGen seed))


unique_randoms :: Int -> Int -> Int -> [Int]
unique_randoms iterations limit seed =
    L.take iterations . nub $ randomRs (0, limit) (mkStdGen seed)



----- # TRAINING # -----


sigmoid :: Float -> Float
sigmoid x = 1.0 / (1 + exp (-x))


sigmoid_derivative :: Float -> Float
sigmoid_derivative x =
    sigmoid x * (1.0 - sigmoid x)


neuron :: (Float -> Float) -> Vector Float -> Vector Float -> Float
neuron activation_function inputs weight =
    activation_function (V.foldl (+) 0.0 (V.zipWith (*) inputs weight))


delta :: Float -> Float -> Float -> Float
delta error old_weight input_value =
    old_weight + (sigmoid_derivative error) * (error) * input_value


update_weight :: Vector (Vector Float)
    -> Vector Float
    -> (Float -> Float)
    -> Int
    -> Vector Float
    -> Vector Float
update_weight training_set expected_results act_function pos weight =
    let
        estimation = neuron act_function (training_set ! pos) weight
        error = (expected_results ! pos) - estimation
    in
        V.zipWith (delta error) weight (training_set ! pos)


train_function :: Vector (Vector Float)
    -> Vector Float
    -> (Float -> Float)
    -> Int
    -> [(Vector Float -> Vector Float)]
train_function training_set expected_results act_function seed =
    let
        rng_list = iterate (next_random (V.length training_set)) seed
        update_list = update_weight training_set expected_results act_function
    in
        L.map update_list rng_list


train :: Vector (Vector Float)
    -> Vector (Vector Float)
    -> (Float -> Float)
    -> Int
    -> [Vector Float]
train data_set training_set act_function seed =
    let
        training_vector = fmap (flip update (V.singleton (0,1.0))) training_set
        results = fmap (V.head) data_set
        train_functions =
            train_function training_vector results act_function random

        dimension = V.length (V.tail (V.head data_set))
        random = next_random (L.length training_set) seed
        next_vector = next_random (V.length training_vector)
        int_weights = iterateN (dimension + 1) next_vector random
        weights = fmap ((/1000).fromIntegral) int_weights

    in
        L.scanl' (\x f -> f x) weights train_functions



----- # VALIDATION # -----


get_error :: Vector (Vector Float) -> Vector Float -> Int -> Float
get_error training_set weight position =
    let
        values = V.zipWith (*) weight (V.tail (training_set ! position))
        approximation = V.foldl (+) 0.0 values / fromIntegral (V.length values)
        real = V.head (training_set ! position)
    in
        abs (real - approximation)


evaluate_weight :: Vector (Vector Float)
    -> Int
    -> Int
    -> Vector Float
    -> Float
evaluate_weight training_set seed iterations weight =
    let
        size = (V.length training_set - 1)
        indexes = fromList (unique_randoms iterations size seed)
        error_vector = V.map (get_error training_set weight) indexes
    in
        V.foldl (+) 0.0 (error_vector) / fromIntegral (V.length error_vector)


optimize :: [(Float, Vector Float)]
    -> (Float, Vector Float)
    -> Float
    -> Int
    -> Int
    -> Int
    -> (Int, Vector Float)
optimize error_weights optimal accuracy count fails max_fails =
    case error_weights of
    [] -> (count, snd optimal)
    (head : tail) ->
        if fst head < accuracy || fails >= max_fails
        then (count, snd optimal)
        else
            let
                minimum = min head optimal
                next = count + 1
                new_fails =
                    if (fst head) > (fst optimal)
                    then fails + 1
                    else 0
            in
                optimize tail minimum accuracy next new_fails max_fails


select_optimal :: [(Float, Vector Float)] -> Float -> Int -> (Int, Vector Float)
select_optimal error_weights accuracy fails =
    let
        count = 0
        best = 0
        (mock_error, mock_weights) = (1/0, V.singleton 0)
        worst_optimal = (mock_error, mock_weights)
    in
        optimize error_weights worst_optimal accuracy count best fails


validate :: Vector (Vector Float)
    -> [Vector Float]
    -> Int
    -> Int
    -> Float
    -> Int
    -> Int
    -> (Int, Vector Float)
validate validation_set weights epochs iterations accuracy seed fails =
    let
        random_number = next_random (V.length validation_set - 1) seed
        evaluate = evaluate_weight validation_set random_number iterations
        weight_error = L.map evaluate weights
        error_weights = L.take epochs (L.zip weight_error weights)
    in
        if iterations < 1
        then (epochs, (weights !! (epochs - 1)))
        else select_optimal error_weights accuracy fails



----- # SPLITTING DATASET # -----


select_indexes :: Vector (Vector Float) -> Int -> Float -> [Int]
select_indexes vector random percent =
    let instances = floor (fromIntegral (V.length vector) * percent) in
        unique_randoms instances ((V.length vector) - 1) random


delete_split :: Vector (Vector Float) -> [Int] -> Vector (Vector Float)
delete_split vector old_indexes =
    let
        count = L.take (V.length vector) (L.iterate (+1) 0)
        indexes = fromList (count \\ old_indexes)
    in
        V.map (vector !) indexes


split_data :: Vector (Vector Float)
    -> Int
    -> Float
    -> (Vector (Vector Float), Vector (Vector Float))
split_data vector seed percent =
    let
        indexes = select_indexes vector seed percent
        split_vector = V.map (vector !) (fromList indexes)
        remaining_vector = delete_split vector indexes
    in
        (split_vector, remaining_vector)


split :: Vector (Vector Float)
    -> Int
    -> (Float, Float)
    -> (Vector (Vector Float), Vector (Vector Float), (Vector (Vector Float)))
split vector seed percents =
    let
        (training, aux_vector) = split_data vector seed (fst percents)
        (validation, test) = split_data aux_vector seed (snd percents)
    in
        (training, validation, test)



----- # MAIN # -----


main :: IO [Float]
main = do

    -- store normalized data from data.txt
    all_data <- Normalize.normalize_data
    let data_set = fromList (fmap fromList all_data)

    -- generate random number
    rng_seed <- newStdGen
    let (random_seed, seed) = randomR (0, V.length data_set) (rng_seed)

    -- divide data into the three necessary sets
    let percentages = (0.9, 0.5)
    let (training_set, validation_set, test_set) = split
            data_set random_seed percentages

    -- training phase
    let act_function = sigmoid
    let trained_weights = train
            data_set training_set act_function random_seed

    -- validation phase
    let accuracy = 0.001
    let epochs = 100000
    let checks = 10
    let consecutive_fails = 25
    let optimal_weight =
            validate
                validation_set
                trained_weights
                epochs
                checks
                accuracy
                random_seed
                consecutive_fails
 
    -- test function
    let tests = 10
    let test_rng = next_random (V.length test_set - 1) random_seed
    let final_error = evaluate_weight
            test_set test_rng tests (snd optimal_weight)

    -- print & return value
    print (fst optimal_weight, snd optimal_weight, final_error)
    return (toList (snd optimal_weight))
