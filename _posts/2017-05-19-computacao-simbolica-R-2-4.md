---
title:  "Escrevendo um pequeno sistema de computação simbólica em R (Parte 2/4)"
date:   2017-05-19 21:38:00 -0300
categories: 
  - Português 
  - R 
  - R_pt
  - Arquivo
tags: 
  - R 
  - lazyeval 
  - purrr 
  - "Computação simbólica" 
  - "Programação funcional" 
  - "Metaprogramação"
excerpt: "O segundo post da série mostra como podemos definir as operações de adição, multiplicação e composição de funções."
---

Esse post é bem antigo. Muita coisa pode estar incorreta devido a novidades que aconteceram desde então, ou porque meu entendimento na época não era tão claro. 
{: .notice--warning}

*An english version of this post is available [here](http://lurodrigo.com/2017/05/symbolic-computation-R-2-4/).*

No post de hoje irei mostrar como estender a pequena linguagem desenvolvida no post anterior para que possamos definir novas funções a partir das existentes usando somas, produtos e composições.

Como ponto de partida, é útil pegar o código como foi finalizado no último post. Ele está disponível [aqui](https://github.com/lurodrigo/symbolic/blob/master/R/symbolic_01.R).

Definindo soma e produto
------------------------

Os operadores `+` e `*` são funções genéricas. Isso significa que podemos definir como eles devem funcionar quando os operandos são de uma classe que definimos. No nosso caso, podemos definir métodos para esses operadores quando aplicados em argumentos do tipo `symbolic`. Isso permite que manipulemos nossas funções com a mesma naturalidade com que manipulamos vetores.

Sabendo disso, podemos definir o primeiro rascunho do método para somar funções. Já é possível implementar, também, uma simplificação: quando um dos operandos for nulo, retornamos o outro operando. Também é fácil implementar uma conveniência: quando um operando for um valor numérico, podemos convertê-lo a uma função constante do nosso sistema. Desse modo, podemos evitar algumas chamadas desnecessárias a `Const()`.

``` r
# adicionei a comparação is_symbolic(x) nas funções is_{tipo}() para evitar
# erros no caso em que o objeto sequer é da classe symbolic
is_nullf = function(x) is_symbolic(x) && x%@%"type" == "null" # etc

`+.symbolic` = function(f, g) {
  # checamos o tamanho do vetor porque, no caso em que não é um escalar,
  # não há uma ideia intuitiva do que deve ser feito
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

Observe a naturalidade com que criamos a função soma e a sua derivada. É praticamente uma definição matemática :)

Uma conveniência interessante é criar um método `Sum` para quando quisermos somar uma lista de funções. Desse modo, podemos operá-las em cadeias construídas com o operador `%>%`. Nem precisamos escrever muito código para isso: basta usar a função `reduce`, do pacote `purrr`[1]. Nela, você passa uma lista de argumentos e uma função com dois operandos. Ela aplica a operação nos dois primeiros elementos da lista, guarda o resultado, aplica com o terceiro elemento, e assim sucessivamente.

``` r
Sum = function(l) reduce(l, `+.symbolic`)
```

``` r
Sum(list(3, Mono(1, 2), Log, Exp))
#> x -> 3 + 1*x^2 + log(x) + exp(x)
```

Agora podemos definir com facilidade uma classe de funções importante: polinômios. Polinômios são apenas somas de monômios, então não há grande dificuldade em criar uma função auxiliar para criá-los. Usamos mais duas funções auxiliares do pacote `purrr`. `as_vector` converte uma lista em um vetor, e `map2` é uma espécie de `lapply` para funções com dois parâmetros.

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
# as representações estão claramente insatisfatórias, mas isso é algo a ser
# resolvido no último post da série
```

Definir o produto é análogo a definir a soma. A diferença maior reside no fato de que há duas simplificações elementares que podem ser feitas: os casos onde um dos operandos é 0 ou 1.

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
    df = D(f)*g + f*D(g), # regra do produto
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

Definindo composições
---------------------

A composição de funções é a operação que a apresenta o maior número de sutilezas. Comecemos pela mais simples: representação. Até agora estávamos definindo as expressões de uma forma que envolvia diretamente "x". É interessante redefini-las em termos de um *placeholder*, que pode vir a ser "x" ou um "f(x)", no caso de uma composição de funções. Para isso, basta definirmos o atributo `repr` em termos de `{x}`: a função `glue` cuidará do resto. Atenção especial deve ser tomada no caso em que `repr` é parametrizado. Quando isto ocorre, deve-se usar <code>{% raw %}{{x}}{% endraw %}</code>, pois `glue` será avaliada duas vezes, em dois momentos diferentes: uma com os parâmetros usuais de `repr`, logo que a função é definida, e outra com o placeholder no lugar de `x`, quando o método `as.character` for executado.

Seguem as modificações que devem ser feitas:

``` r
# Representação de Mono: linha 68
# antes: 
  repr = glue("{a}*x^{n}")
# depois:
  repr = glue("{a}*{{x}}*^{n}")
  
# Representação de Log: linha 79
# antes:
  repr = "log({x})"
# depois:
  repr = "log({x})"
  
# Representação de Exp: Linha 89
# antes:
  repr = "exp(x)"
# depois:
  repr = "exp({x})"
  
# Representação de `+`: 
# antes:
  repr = glue("{f} + {g}")
# depois:
  repr = glue('{f%@%"repr"} + {g%@%"repr"}')

# Representação de `*`: 
# antes:
  repr = glue("({f})*({g})")
# depois:
  repr = glue('({f%@%"repr"})*({g%@%"repr"})')
  
  
# Mudança no as.character: linha 19
# antes:
  as.character.symbolic = function(f) f%@%"repr"
# depois:
  as.character.symbolic = function(f) glue(f%@%"repr", x = "x")
```

Agora a representação de composições de funções se torna trivial. Se `f%@%"repr"` é `1*{x}^2 + exp({x})`, por exemplo, a linha `glue(f%@%"repr", x = "sin(x)")` dará a representação desta função composta com a função seno.

Segundo problema: Não há nenhum operador definido como função genérica no R que seja intuitivo o suficiente para usarmos para a composição, não existe um operador <code>°</code>. Resta nos contentar com uma função chamada `Compose` ou algo do tipo. Ou não! Seria interessante que pudéssemos compor as funções usando uma notação como `Log(Sin)`. Isso é possível? Sim!

Precisaremos, no entanto, modificar a função `symbolic()`. Atualmente ela simplesmente preserva a função f passada como parâmetro. Podemos fazer melhor. Podemos criar uma função nova, g, a partir dela, de modo que g(x) é f(x) em todos os casos normais (isto é, quando o parâmetro é numérico), mas g(x) é uma composição de funções no caso em que x é, ela mesma, uma função simbólica. Por exemplo, `Log(4)` será avaliada como um número, mas `Log(Sin)` como uma composição de funções.

Um detalhe um tanto inconveniente é que, para fazer isso, precisaremos ter a variável ou função auxiliar (`Mono`, `Exp`, etc) que gera as funções. Será necessário, para guardá-la, mais um argumento em `symbolic()`, o qual chamaremos de `this`. Naturalmente, teremos que adicionar um parâmetro `this` na chamada a `symbolic()` das funções que definimos anteriormente.

O novo código para `symbolic()` e o código para a função `Compose()` se encontram abaixo. O funcionamento delas é um tanto sofisticado. Portanto, recomendo que passe um tempinho testando e tentando entender o que acontece durante a execução delas.

``` r
symbolic = function(f, repr, df, type, this, params = list(), inverse = NULL) {
  this = lazy(this) # guarda a expressão
  
  g = function(x) {
    if (is_symbolic(x)) {
      this = lazy_eval(this) # executa
      # se vem de uma função que não toma parâmetros (Sin ou Exp, por ex)
      if (is_symbolic(this))
        return(Compose(this, x)) # pode usá-la diretamente na composição
      
      # se ainda há parâmetros a serem chamados, chama a função criadora
      # com esses parâmetros
      s = do.call(this, params)
      return(Compose(s, x))
    }

    # se x não for symbolic, simplesmente calcula o valor numérico da função
    f(x)
  }
  
  class(g) = c("symbolic", "function")
  attr(g, "repr") = repr # uma representação da função, como string
  attr(g, "df") = lazy(df) # a derivada da função
  attr(g, "inverse") = lazy(inverse) # a inversa da função. não será usada ainda.
  attr(g, "type") = type # que tipo de função isso é
  attr(g, "params") = params # os parâmetros que definem uma função daquele tipo
  g
}

has_inverse = function(f) !is.null(f%@%"inverse")
inverse = function(f) lazy_eval(f%@%"inverse")

Compose = function(f, g) {
  if (is_nullf(f) || is_const(f))
    return(f)
  
  # se g(x) = c, f(g(x)) = f(c)
  if (is_nullf(g))
    return(Const(f(0)))
  
  if (is_const(g))
    return(Const(f(attr(g, "params")$c)))
  
  symbolic(
    f = function(x) f(g(x)),
    # um par de parênteses a mais por precaução. Por enquanto, é preferível
    # mais parênteses que menos
    repr = glue(f%@%"repr", x = glue("({g})")), 
    df = D(f)(g) * D(g), # regra da cadeia
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

Lembre-se de inserir o parâmetro `this`! Por exemplo, a nova definição de `Null` é:

``` r
Null = symbolic(
  f = function(x) 0,
  repr = "0",
  df = Null,
  type = "null",
  this = Null
)
```

Façamos agora alguns testes:

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

Exceto pelas representações extremamente prolixas, tudo parece estar em seu lugar! :)

Novas funções
-------------

Antes de atacar os problemas de representação e simplificação, há mais coisas que podemos adicionar sem muito trabalho. Podemos definir, por exemplo, operadores de subtração e divisão. Por motivos que ficarão mais claros mais tarde, representaremos -g como a composição de `x -> -x` (isto é, `Mono(a = -1)`) com g, e f - g como f + (-g), com -g seguindo a definição anterior. Analogamente, definimos f / g como a f multiplicado pela composição de `Mono(n = -1)` com g, isto é, a recíproca de g.

``` r
`-.symbolic` = function(f, g) {
  # caso do - unário
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

Agora podemos definir as funções trigonométricas:

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

Claro, já podemos definir as funções tangente, secante e até as trigonométricas inversas, como arco-tangente. Isto fica como exercício para o leitor (*risos*). Até o próximo post!

-   [Parte 1/4: Construindo a estrutura do sistema](http://lurodrigo.com/2017/05/computacao-simbolica-R-1-4/)
-   Parte 3/4: Ensinando as simplificações álgebricas
-   Parte 4/4: Tornando a representação das funções mais inteligente

O código como encontrado ao final deste post pode ser visto [aqui](https://github.com/lurodrigo/symbolic/blob/master/R/symbolic_02.R).

[1] Há uma função `Reduce` no base-R cumprindo o mesmo papel, mas acho as funções do pacote `purrr` mais consistentes e convenientes.
