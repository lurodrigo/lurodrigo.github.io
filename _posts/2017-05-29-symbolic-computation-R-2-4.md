---
title:  "Writing a simple symbolic computation system using R (Part 2/4)"
date:   2017-05-29 22:30:00 -0300
categories: 
  - English 
  - R 
  - R_en
  - Archive
tags: 
  - R 
  - lazyeval 
  - purrr 
  - "Symbolic computation" 
  - "Functional programming" 
  - "Metaprogramming"
excerpt: "The second post of the series shows how addition, multiplication and 
composition of function can be defined."
---

This post is very old. Many things may be wrong due to things that happened since then, or because I did not have a good
understanding of what I was writing about.
{: .notice--warning}

*This post was originally written in [portuguese](https://lurodrigo.github.io/2017/05/computacao-simbolica-R-2-4/).*

Today, I'm going to show how we can extend the little language we built in the previous post, enabling us to define new functions from existing ones using sums, products, and compositions.

As a starting point, it might be useful to get the code as finished on the last post. It's available [here](https://github.com/lurodrigo/symbolic/blob/master/R/symbolic_01_en.R).

Defining sums and products
--------------------------

The `+` and `*` operators are *generic functions*. This means that we can specify how they should behave when applied to arguments having a class we defined. In our case, we can define methods for these operators when applied to arguments of the `symbolic` class. This allows us to manipulate our functions as naturally as we manipulate vectors.

Knowing this, we can define the first draft of our method for adding functions. Also, we can already implement a simplification: when one of the operands is null, we return the other operand. It's also easy to implement a convenience: when one of the operands is a numerical value, we convert it to a `symbolic` function. This way we can avoid unnecessary calls to `Const()`.

``` r
# I added the is_symbolic(x) check on is_{type}() function to avoid errors in
# the case the object isn't even symbolic
is_nullf = function(x) is_symbolic(x) && x%@%"type" == "null" # etc

`+.symbolic` = function(f, g) {
  # we check the size of the vector because there's no intuitive idea of how
  # they should be handled when they're not scalars
  if (is.numeric(f) && length(f) == 1) 
    return(Const(f) + g)
  if (is.numeric(g) && length(g) == 1)
    return(f + Const(g))
  
  if (is_nullf(f))
    return(g)
  if (is_nullf(g))
    return(f)
  
  symbolic(
    f = function(x) f(x) + g(x),
    repr = glue("{f} + {g}"),
    df = D(f) + D(g),
    type = "sum",
    params = list(f, g)
  )
}
```

``` r
Mono(1, 2) + Mono(1, 1)
#> x -> 1*x^2 + 1*x^1
D(Mono(1, 2) + Mono(1, 1))
#> x -> 2*x^1 + 1
Mono(1, 2) + Log + 4
#> x -> 1*x^2 + log(x) + 4
D(Mono(1, 2) + Log + 4)
#> x -> 2*x^1 + 1*x^-1
Mono(1, 2) + 0
#> x -> 1*x^2
3 + Mono(1, 1)
#> x -> 3 + 1*x^1
0 + Mono(1, 2)
#> x -> 1*x^2
```

Notice that we define the sum of functions and its derivative in a very natural manner. It's almost a mathematical definition :)

An interesting convenience we can add is a `Sum` function to sum an entire list of functions. With it, we might be able to operate them in chains built with the `%>%` operator. We don't even have to write much code to do it: using `reduce`, from the package `purrr`[1], suffices. You pass a list of arguments to this function and a function that takes two operands. It applies the operation to the first two elements of the list, stores the result, applies it and the third element to the function, stores the result, and so on, until the list is exhausted.

``` r
Sum = function(l) reduce(l, `+.symbolic`)
```

``` r
Sum(list(3, Mono(1, 2), Log, Exp))
#> x -> 3 + 1*x^2 + log(x) + exp(x)
```

Now we can easily define an important class of functions: polynomials. Polynomials are, in fact, mere sums of monomials, so it's not hard to define an auxiliary function to create them. We use two more functions from `purrr`. `as_vector` converts a list to a vector, and `map2` is a generalization of `lapply` for functions that take two parameters.

``` r
Poly = function(...) {
  coef = as_vector(list(...))
  degree = length(coef) - 1
  map2(coef, degree:0, function(a, n) Mono(a, n)) %>% Sum
}
```

``` r
Poly(1, -5, 6)
#> x -> 1*x^2 + -5*x^1 + 6
Poly(1, 3, 3, 1)
#> x -> 1*x^3 + 3*x^2 + 3*x^1 + 1
# the representations are clearly unsatisfatory, but this is something we're going
# to fix only in the last post of the series.
```

Defining products is analogous to defining sums. The main difference lies in the fact that there are two elementary simplifications we can apply: the cases where one of the operations is 0 or 1.

``` r
`*.symbolic` = function(f, g) {
  if (is.numeric(f) && length(f) == 1) 
    return(Const(f) * g)
  if (is.numeric(g) && length(g) == 1)
    return(f * Const(g))  
  
  if (is_nullf(f) || is_nullf(g)) 
    return(Null)
  
  if (is_const(f) && attr(f, "params")$c == 1)
    return(g)
  if (is_const(g) && attr(g, "params")$c == 1)
    return(f)
  
  symbolic(
    f = function(x) f(x) * g(x),
    repr = glue("({f})*({g})"), 
    df = D(f)*g + f*D(g), # the product rule
    type = "product",
    params = list(f, g)
  )
}

Prod = function(l) reduce(l, `*.symbolic`)
```

``` r
Mono() * Exp
#> x -> (1*x^1)*(exp(x))
D(Mono() * Exp)
#> x -> exp(x) + (1*x^1)*(exp(x))
Log * Mono()
#> x -> (log(x))*(1*x^1)
D(Log * Mono())
#> x -> (1*x^-1)*(1*x^1) + log(x)
```

Defining compositions
---------------------

Function composition is an operation that requires paying attention to many subtleties when implementing. We'll start from the most simple of them: representation. So far we were defining the expressions using "x" directly. It's wise to redefine them in terms of a placeholder, which might come to be "x" or an specific "f(x)" in the case of a function composition. To do this, we only need to redefine the `repr` attribute in terms of `{x}`: the `glue` function will take care of the details. Special attention must be paid in the case `repr` is parameterized. In this case, we should use <code>{% raw %}{{x}}{% endraw %}</code>, because `glue` is going to be evaluated two times, at two different moments: one with the usual parameters of `repr`, as soon as the function is defined, and another time, with the placeholder instead of `x`, when `as.character` is called.

The changes that must be applied are shown below:

``` r
# Mono's representation: line 68
# before: 
  repr = glue("{a}*x^{n}")
# after:
  repr = glue("{a}*{{x}}*^{n}")
  
# Log's representation: line 79
# before:
  repr = "log({x})"
# after:
  repr = "log({x})"
  
# Exp's representation: Line 89
# before:
  repr = "exp(x)"
# after:
  repr = "exp({x})"
  
# `+`'s representation: 
# before:
  repr = glue("{f} + {g}")
# after:
  repr = glue('{f%@%"repr"} + {g%@%"repr"}')

# `*`'s representation: 
# before:
  repr = glue("({f})*({g})")
# after:
  repr = glue('({f%@%"repr"})*({g%@%"repr"})')
  
  
# changes on as.character: line 19
# before:
  as.character.symbolic = function(f) f%@%"repr"
# after:
  as.character.symbolic = function(f) glue(f%@%"repr", x = "x")
```

Now representing function composition becomes trivial. If, for instance, `f%@%"repr"` is `1*{x}^2 + exp({x})`, the line `glue(f%@%"repr", x = "sin(x)")` will give the representation of the composition of itself with the sine function.

Second problem: there's no operator, defined as an R generic function, natural enough to use as a composition operator. There's no <code>°</code> operator. It seems defining a `Compose` function is the best we can do. Or not! It'd be great if we could compose functions by nesting them, such as `Log(Sin)`. Is it possible? Yes, it is!

To do that we need to make quite deep changes to `symbolic()` nonetheless. Currently, it simply preserves the function f, passed as parameter, as is. We can do better. We can construct a new function, g, from it, such that g(x) equals f(x) when the argument is numeric, but g(x) returns a function composition when x is, itself, a symbolic function. For instance, `Log(4)` is evaluated as a number, but `Log(Sin)` is interpreted as a function composition.

It's quite inconvenient but, to do that, we need the variable or auxiliary function (`Mono`, `Exp`, etc) that generates the functions. To store it, one more argument to `symbolic()` will be needed, which we'll call `this`. Naturally, we'll need to add a `this` parameter to the calls to `symbolic()` on the functions we've already defined.

The new code for `symbolic()` and the code for `Compose()` can be found below. Their operation is quite sophisticated, so I recommend that you spend a little time testing it and figuring out what's happening on the execution.

``` r
symbolic = function(f, repr, df, type, this, params = list(), inverse = NULL) {
  this = lazy(this) # stores the expression
  
  g = function(x) {
    if (is_symbolic(x)) {
      this = lazy_eval(this) # executes it
      # if it comes from a function thas does not take parameters (Sin ou Exp, for instance)
      if (is_symbolic(this))
        return(Compose(this, x)) # we can use it directly on the composition
      
      # if it has parameters, calls the function that generates it with the 
      # parameters
      s = do.call(this, params)
      return(Compose(s, x))
    }

    # if x is not symbolic, simply evaluates the function at that point
    f(x)
  }
  
  class(g) = c("symbolic", "function")
  attr(g, "repr") = repr # a string representation of the function
  attr(g, "df") = lazy(df) # its derivative
  attr(g, "inverse") = lazy(inverse) # its inverse. We're not gonna use it yet.
  attr(g, "type") = type # what kind of function this is
  attr(g, "params") = params # the parameters which define a function of this type
  g
}

has_inverse = function(f) !is.null(f%@%"inverse")
inverse = function(f) lazy_eval(f%@%"inverse")

Compose = function(f, g) {
  if (is_nullf(f) || is_const(f))
    return(f)
  
  # if g(x) = c, f(g(x)) = f(c)
  if (is_nullf(g))
    return(Const(f(0)))
  
  if (is_const(g))
    return(Const(f(attr(g, "params")$c)))
  
  symbolic(
    f = function(x) f(g(x)),
    # an extra pair of parentheses for precaution. Fow now it's better to use
    # potentially more parentheses than necessary
    repr = glue(f%@%"repr", x = glue("({g})")), 
    df = D(f)(g) * D(g), # chain rule
    type = "composition",
    this = Compose,
    params = list(f, g),
    inverse = if (has_inverse(f) && has_inverse(g)) 
        inverse(g)(inverse(f))
      else 
        NULL
  )
}
```

Remember to add the `this` parameter! For instance, the new definition of `Null` is:

``` r
Null = symbolic(
  f = function(x) 0,
  repr = "0",
  df = Null,
  type = "null",
  this = Null
)
```

Let's do some testing:

``` r
Mono(1, 2)
#> x -> 1*x^2
Mono(1, 2)(3)
#> [1] 9
Mono(1, 2)(Const(3))
#> x -> 9
Mono(1, 2)(Exp)
#> x -> 1*(exp(x))^2
D(Mono(1, 2)(Exp))
#> x -> (2*(exp(x))^1)*(exp(x))
Poly(1, 2, 3)
#> x -> 1*x^2 + 2*x^1 + 3
Poly(1, 2, 3)(0)
#> [1] 3
Poly(1, 2, 3)(Null)
#> x -> 3
Poly(1, 2, 3)(Log)
#> x -> 1*(log(x))^2 + 2*(log(x))^1 + 3
D(Poly(1, 2, 3)(Log))
#> x -> (2*(log(x))^1 + 2)*(1*x^-1)
D(Poly(1, 2, 3)(Log), 2)
#> x -> ((2)*(1*x^-1))*(1*x^-1) + (2*(log(x))^1 + 2)*(-1*x^-2)
```

Except for the extremely long representations, everything seems to be working just fine :)

New functions
-------------

Before attacking the representation and simplification problems, there are more things we can add to the system with ease. We can define, for instance, subtraction and division operators. We're going to represent -g as the composition of `x -> -x` (that is, `Mono(a = -1)`) with g, and f - g as f + (-g), where -g follows the previous definition. By analogy, we'll define f / g as f times the composition of `Mono(n = -1)` with g, that is, the reciprocal of g.

``` r
`-.symbolic` = function(f, g) {
  # unary minus
  if (missing(g)) {
    Mono(a = -1)(f)
  } else {
    f + (-g)
  }
}

`/.symbolic` = function(f, g) f * Mono(n = -1)(g)
```

``` r
Log - Exp
#> x -> log(x) + -1*(exp(x))^1
Log / Exp
#> x -> (log(x))*(1*(exp(x))^-1)
```

Now we can define trigonometric functions:

``` r
Sin = symbolic(
  f = sin,
  repr = "sin({x})",
  df = Cos,
  type = "sin",
  this = Sin
)

Cos = symbolic(
  f = cos,
  repr = "cos({x})",
  df = -Sin,
  type = "cos",
  this = Cos
)
```

``` r
Sin(0)
#> [1] 0
Cos(0)
#> [1] 1
D(Sin)
#> x -> cos(x)
D(Sin, 2)
#> x -> -1*(sin(x))^1
D(Sin, 3)
#> x -> (-1)*(cos(x))
D(Sin, 4)
#> x -> (-1)*(-1*(sin(x))^1)
```

Of course we can already define the tangent, secant and even inverse trigonometric functions, such as the arctangent. I'll let them as an exercise to the reader.

-   [Part 1/4: Building the system's structure](http://lurodrigo.com/2017/05/symbolic-computation-R-1-4/)
-   Part 3/4: Adding algebraic simplifications
-   Part 4/4: Producing smarter string representations

The code as found at the end of this post can be viewed [here](https://github.com/lurodrigo/symbolic/blob/master/R/symbolic_02_en.R).

[1] Base R also has a `Reduce` function doing the same task, but I find the functions from `purrr` more consistent and convenient.

