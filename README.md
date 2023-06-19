# ann
net implementation using haskell that aims to be a generalized perceptron for any given dataset
this projects' objective is for me to test some functional programming concepts & learn more about haskell & ai
for the time being this project has only implemented a mono-neuronal network

## technologies
this repo only uses haskell, trying to rely on external modules as little as possible
- ghc version 9.4.4
- Data.Vector
- Data.List
- System.Random

## execution
compiling the Main.hs file `ghc Main.hs` & running it `./Main` should suffice
at the moment all performance options (epochs, error, validation...) are hard-coded on this file for my confort
(i may add them as inputs later)

## code structure
the code is divided in two different files:
- `Normalize.hs`: auxiliar functionality that parses & normalizes the dataset written into `data.tx`
- `Main.hs`: main functionality (training, validation & testing) that calculates an optimal weight approximation for the given data

### data
data is written on the data.txt file such that:

```math
\begin{matrix}
\begin{array}{c|cccc}
a_0&a_1&a_2&\ldots&a_n \\b_0&b_1&b_2&\ldots&b_n\\c_0&c_1&c_2&\ldots&c_n\\\vdots&\vdots&\vdots&\ddots&\vdots\\m_0&m_1&m_2&\ldots&m_n
\end{array}
\end{matrix}
```

- the number of rows $m$ is the number of instances available for the problem
- the number of columns $n$ signifies the dimensionality of the problem
    - the first column $n=0$ represents the expected result for the corresponding data

on the file *per se*, each number must be separated with a tab `\t` & newlines `\n` for each row

#### formating

the actual data read will be a `[[Float]]`, such that, for the previous example:
```data = [[a0,a1,a2,...an],[b0,b1,b2,...bn],[c0,c1,c2,...cn],...[m0,m1,m2,...mn]]```

- the size of the primary list is the number of instances
- the size of any of the sub-lists (-1) is the dimensionality of the problem
    - there is easy access to the expected result as `head` of each sub-list

#### normalization
this data is normalized automatically by trasposing the `[[Float]]` and dividing each value of each list by the maximum value on that list `map (/ (foldl max))`
this normalization is not perfect: it does not take into account boolean/categorizing values (which should be made into different properties) but for this project, it'll do

### main
#### datatypes
since the data read will not be modified, but accessed really frequently, instead of using a list of lists, a vector of vector is used, since access is done in `O(1)`
since i did not want to modify read/normalization code, the data is converted as soon as read on `Main.hs` itself
#### training
training has been implemented as a `scanl` that takes the initial weight and other parameters and keeps training each weight
because of haskell's lazy evaluation, code will compute only as many training iterations as needed
#### validation
in order to know when to stop training, the validation phase comes into being
training checks any given weight against the validation set, checking the average error, how many iterations since last impovement, current epoch...
once any of this conditions is met, it returns the current weights as the optimal
#### test
test is the simplest phase, it just checks the optimal weight against the test set, to check weight abstraction properties

## complexity
this code is expected to be iterated quite a lot, thus it is important to manage its complexity correctly

without much analysis, execution seems pretty expensive, especially the validation phase

### empyrical complexity
for a more in-depth analysis, execution time is measured & complexity extracted from it:
|     | 1     | 10    | 1e2   | 1e3   | 1e4   | 1e5   | 1e6   | 1e7  | 1e8 |
|-----|-------|-------|-------|-------|-------|-------|-------|------|-----|
| 1   | 0.5   | 0.5   | 0.5   | 0.5   | 0.6   | 1.1   | 6.6   | 64   | inf |
| 10  | 0.5   | 0.5   | 0.5   | 0.5   | 0.7   | 1.7   | 14.0  | 157  | inf |
| 50  | 0.5   | 0.5   | 0.5   | 0.6   | 1.0   | 5.3   | 53.0  | 493  | inf |
| 100 | 0.5   | 0.5   | 0.5   | 0.7   | 1.7   | 11.0  | 116.0 | 1098 | inf |
| 150 | 0.5   | 0.5   | 0.5   | 0.8   | 2.7   | 22.0  | 201.0 | inf  | inf |
| 200 | 0.5   | 0.5   | 0.6   | 0.9   | 4.5   | 40.0  | 371.0 | inf  | inf |
| 250 | inf   | inf   | inf   | inf   | inf   | inf   | inf   | inf  | inf |

- O(n) [200] = `0.5−5.00000050000*10^(−8)x`
- O(n) [150] = `0.5−5.00000050000...*10^(−8)x`
- O(n) [100] = `0.00010975x+0.49989`
- O(n) [50] = `0.00004975x+0.49995`
- O(n) [10] = `0.00001565x+0.499984`

max_epoch complexity = `O(n)`

- O(m) [1e6] = `f(x)=7.0392020335679*10^(-9) x^(5)-3.1879880245883*10^(-6) x^(4)+0.000534124 x^(3)-0.0357789 x^(2)+1.8933 x-1.25805`
- O(m) [1e5] = `g(x)=3.524125517703*10^(-10) x^(5)+1.618356645607*10^(-7) x^(4)-0.0000213841 x^(3)+0.00132515 x^(2)+0.0542878 x+1.04441`
- O(m) [1e4] = `h(x)=8.68417798999*10^(-9) x^(3)-0.0000974269 x^(2)+0.109752 x+0.990345`
- O(m) [1,1e3] = constant

with this data, it is clear that the current complexity of the code is polynomial, being `m` (validation_iterations) the value that increases the complexity the most (as expected)

### complexity management
to mitigate the high complexity, the code checks several data to stop execution if no more training is necesary, being the most relevant, the number of contiguous training iterations without improvement


### current dataset example

the current [data](https://archive.ics.uci.edu/ml/datasets/Wine+Quality) has the following input variables:
- fixed acidity
- volatile acidity
- citric acid
- residual sugar
- chlorides
- free sulfur dioxide
- total sulfur dioxide
- density
- pH
- suphates

the objective is for the ann to be able to predict the quality (represented as an integer [1,10])

this problem incites solving with a more complex ann, but empyrical test show a test error of [1e-2,1], being the lower bound quite acceptable
for a more complex problem: [artificial neural network](https://github.com/yref-boop/ann)
