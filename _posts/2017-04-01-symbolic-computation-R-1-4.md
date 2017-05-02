---
title:  "Writing a simple symbolic computation system in R (Part 1/4)"
date:   2017-05-02 21:00:00 -0300
categories:
  - English
  - R
  - R_en
tags:
  - R
  - lazyeval
  - purrr
  - "Symbolic computation"
  - "Functional programming"
  - "Metaprogramming"
---

This week I found myself thinking on how packages like `dplyr` use a lot of
metaprogramming (that is, computation over the language itself) and functional tools to create
functions having a lot of expressive power. I asked myself: can I possible use these tools for algebraic manipulation? In particular, could I use them to build a system able to do symbolic differentiation?

I thought about the differentiation problem in particular because it's clear that
finding derivatives of elementary functions consists of mere formal (though tedious)
manipulation. Symbolic integration, in contrast, is more an art than an algorithm.

I found out, after playing with the idea and a few days of tinkering, that doing
it is not only possible, but it also can be done with relative ease. It's an exercise
that illustrates pretty well how R's functional and metaprogramming capabilities
translate to concise and expressive code.

I wanted this system, (or *domain-specific language*, to be fancy) to satisfy four requisites:

1. It must describe concisely all elementary functions from calculus, that is, anything
that's built with polynomials, exponentials, logarithms and trigonometric functions.
2. It must be able to manipulate them both symbolically and numerically.
3. It can compute their derivatives symbolically.
4. Its symbolic expressions must be simple, whenever possible.

Let it be clear that I'm not a symbolic computation expert, so a system for
real-world usage would probably need to implement a lot of optimations to the algorithms
I use.
Let's get started, then. First, I'm going to need three packages: `purrr`, `lazyeval`, and `glue`,
so install them if you do not have them installed yet. I'll explain the
functions as I use them.

The first tough detail is that I want functions to be *callable*, that is,
that they can be evaluated directly using the traditional syntax:
the function name, followed by a pair of parentheses enclosing its argument. At
the same time, I need them to store additional data, such as an string representation,
its derivative or its inverse. To do it, I'm gonna need to use R *attributes*.

In R, every object can store data through attributes, setting them using `attr()`. To access them,
you can use `attr()` itself or the operator `%@%` provided by `purrr`. This, I only need to
take an ordinary mathematical function and add the data needed throught attributes.

For convenience, I will also define `print` and `as.character` methods for the `symbolic` class so
working with these functions become more pleasurable. Finally, I'm going to create
a function for computing the n-th derivative of a function symbolically.

``` r
library(purrr)
library(glue)
library(lazyeval)

symbolic = function(f, repr, df, type, params = list(), inverse = NULL) {
  class(f) = c("symbolic", "function")
  attr(f, "repr") = repr # a string representation of the function
  attr(f, "df") = lazy(df) # its derivative
  attr(f, "inverse") = lazy(inverse) # its inverse. We're not gonna use it yet.
  attr(f, "type") = type # what kind of function this is
  attr(f, "params") = params # the parameters which define a function of this type
  f
}

# auxiliary functions
is_symbolic = function(x) inherits(x, "symbolic")

as.character.symbolic = function(f) f%@%"repr"

print.symbolic = function(f) cat(glue("x -> {f}"))

# The differential operator. Takes the n-th derivative of a function recursively
D = function(f, n = 1) {
  if (n == 0) # does nothing
    f
  else if (n == 1) # for the first derivative, it only evaluates the df attribute
    lazy_eval(f%@%"df")
  else # the n-th derivative is the derivative of the (n-1)-th derivative
    D(lazy_eval(f%@%"df"), n - 1)
}
```

A very important tool for us, used extensively through this project, is [*lazy evaluation*][1].
Its usefulness will become clear when I define the first funcion with this system: the null function.
We know that the derivative of the null function is the null function itself. I will define it
in a seemingly circular way. Instinctively, it should result in some kind of error, but it doesn't happen.
Look:

``` r
Null = symbolic(
  f = function(x) 0,
  repr = "0",
  df = Null,
  type = "null"
)

is_nullf = function(x) x%@%"type" == "null"
```

``` r
Null
#> x -> 0
Null(5)
#> [1] 0
D(Null) # the null function itself
#> x -> 0
```

I'm defining `Null` as the result of `symbolic()` applied to a list of parameters,
one of them being `Null` itself, and still it works fine? How does it work?

The `lazy()` function, used inside `symbolic()`, is the key. It captures the
*expression* that defines a derivative, but does not evaluate it. In fact, I
do not need to compute the derivative of a function the moment I define it,
I just need to know *how* to compute it when I need. That's precisely what
the `lazy(df)` line is doing. It's storing the expression defining the derivative,
and only when I call `D()` I use `lazy_eval()` to obtain it.

Try running the previous code removing the references to `lazy()`. You're going to get this error message:

    Error in symbolic(f = function(x) 0, repr = "0", df = Null, type = "null") :
      object 'Null' not found

This happens because `Null` hasn't been defined the moment `symbolic()` is called. Lazy evaluation avoids this.
It tells that the moment I want to compute the derivative of `Null`, I only need to return
`Null` itself. But then `Null` will already be defined! Problem solved :)

Using the same idea, we can define a few more classes of functions:

``` r
Const = function(c) {
  if (c == 0)
    return(Null)

  symbolic(
    f = function(x) c,
    repr = as.character(c),
    df = Null,
    type = "const",
    params = list(c = c)
  )  
}

is_const = function(x) x%@%"type" == "const"

# Monomials
Mono = function(a = 1, n = 1) {
  if (a == 0)
    return(Null)

  if (n == 0)
    return(Const(a))

  symbolic(
    f = function(x) a*x^n,
    repr = glue("{a}*x^{n}"),
    df = Mono(n*a, n-1),
    type = "mono",
    params = list(a = a, n = n),
    inverse = Mono(1/a^(1/n), 1/n)
  )
}

is_mono = function(x) x%@%"type" == "mono"

Log = symbolic(
  f = log,
  repr = "log(x)",
  df = Mono(1, -1),
  type = "log",
  inverse = Exp
)

is_log = function(x) x%@%"type" == "log"

Exp = symbolic(
  f = exp,
  repr = "exp(x)",
  df = Exp,
  type = "exp",
  inverse = Log
)

is_exp = function(x) x%@%"type" == "exp"
```

Strictly speaking, the formula for the inverse of a monomimal I gave below only works for positive numbers.
Tackling this kind of problem requires a sophistication I don't want to engage in this
series of posts.

Now, let's test the functions to see if everything is working fine.

``` r
f = Const(3)
f(5)
#> [1] 3
D(f)
#> x -> 0
D(f, 2)
#> x -> 0

f = Mono(0.5, 2)
f(3)
#> [1] 4.5
D(f)
#> x -> 1*x^1
D(f, 2)
#> x -> 1

f = Log
f(exp(1))
#> [1] 1
D(f)
#> x -> 1*x^-1
D(f, 2)
#> x -> -1*x^-2

f = Exp
f(1)
#> [1] 2.718282
D(f)
#> x -> exp(x)
D(f, 2)
#> x -> exp(x)
```

It is!

Ok, in this post we could define some elementary functions and compute their derivatives, but
we can't have much fun with them yet. Calculus becomes interesting when we are able to
define define new functions through sums, products and **compositions** (highlights).
In the next post of this series I'm going to explain how we can add these features. See you!

-   Part 2/4: Defining sums, products, and compositions
-   Part 3/4: Adding algebraic simplifications
-   Part 4/4: Producing smarter string representations

[1]:https://en.wikipedia.org/wiki/Lazy_evaluation
