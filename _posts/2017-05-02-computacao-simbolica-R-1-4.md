---
title:  "Escrevendo um pequeno sistema de computação simbólica em R (Parte 1/4)"
date:   2017-05-01 21:38:00 -0300
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
excerpt: "Iniciando uma série de posts que ensina a desenvolver uma domain-specific language de computação simbólica em R"
---

Esse post é bem antigo. Muita coisa pode estar incorreta devido a novidades que aconteceram desde então, ou porque meu entendimento na época não era tão claro. 
{: .notice--warning}

*An english version of this post is available [here](https://lurodrigo.github.io/2017/05/symbolic-computation-R-1-4/).*

Essa semana me peguei pensando em como pacotes como o `dplyr` utilizam muito recursos de metaprogramação (isto é, computação sobre a própria linguagem) para criar funções com grande poder expressivo. Me perguntei: será que é possível usar isso para manipulação algébrica? Em particular, seria possível criar uma função que, dada a descrição simbólica de uma função, computasse sua derivada?

Pensei no problema da derivada, em particular, porque é evidente que encontrar as derivadas de funções elementares é uma mera manipulação formal (embora tediosa), ao contrário da busca por antiderivadas, que está muito mais para *arte* que para algoritmo.

Descobri, depois de alguns dias brincando com a ideia, que isso não só é possível como é possível com relativa facilidade. É um exercício que ilustra bem como as ferramentas funcionais e de metaprogramação do R se traduzem em mais concisão e expressividade.

Quero que esta linguagem satisfaça quatro requisitos:

1.  Possa descrever concisamente todas as funções elementares do cálculo, isto é, aquelas obtidas a partir de polinômios, trigonométricas, exponenciais e logaritmos.
2.  Que as funções expressas possam ser manipuladas simbólica e numericamente.
3.  Possa computar simbolicamente as derivadas destas funções.
4.  Que as expressões simbólicas geradas sejam simples, na medida do possível.

Quero deixar claro que não sou nenhum especialista em computação simbólica e que, muito provavelmente, um sistema para uso real-world precisaria implementar várias otimizações dos algoritmos aqui usados.

Mãos à obra, então! Estou usando três pacotes: `purrr`, `lazyeval`, e `glue`. O uso deles será explicado ao longo do texto.

O primeiro detalhe é que quero ter uma função *chamável*, isto é, que eu possa avaliar f(x) diretamente para algum número, mas ao mesmo tempo preciso que ela possa armazenar mais informações, por exemplo, uma representação em string ou qual é a sua derivada. Para isso, posso usar os atributos em R.

Em R, todo objeto pode guardar dados através da função `attr()`. Pode-se depois acessá-los via `attr()` ou `%@%`. Então basta pegar uma função matemática ordinária em R e adicionar os dados que forem necessários a ela via atributos. Também modificarei o método `print()` e o `as.character` delas para que o trabalho com essas funções no console seja mais agradável. Por último, criarei uma função para computar simbolicamente a n-ésima derivada.

``` r
library(purrr)
library(glue)
library(lazyeval)

symbolic = function(f, repr, df, type, params = list(), inverse = NULL) {
  class(f) = c("symbolic", "function")
  attr(f, "repr") = repr # uma representação da função, como string
  attr(f, "df") = lazy(df) # a derivada da função
  attr(f, "inverse") = lazy(inverse) # a inversa da função. não será usada ainda.
  attr(f, "type") = type # que tipo de função isso é
  attr(f, "params") = params # os parâmetros que definem uma função daquele tipo
  f
}

# funções auxiliares
is_symbolic = function(x) inherits(x, "symbolic")

as.character.symbolic = function(f) f%@%"repr"

print.symbolic = function(f) cat(glue("x -> {f}"))

# função para calcular a n-ésima derivada recursivamente
D = function(f, n = 1) {
  if (n == 0) # não faz nada
    f
  else if (n == 1) # se quer a primeira derivada, apenas retorna o atributo df de f
    lazy_eval(f%@%"df")
  else # se não, calcula a n-1 ésima derivada da sua derivada
    D(lazy_eval(f%@%"df"), n - 1)
}
```

Uma ferramenta muito importante e usada extensivamente neste projeto é a *lazy evaluation*. Isto ficará claro quando eu definir a primeira função dentro deste sistema: a função nula. Sabe-se que a derivada da função nula é a própria função nula. Defino-a por uma via aparentemente circular, que intuitivamente deveria resultar em alguma espécie de erro, mas não é isso que ocorre. Veja:

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
D(Null) # a própria função nula
#> x -> 0
```

Defino `Null` como o resultado de `symbolic()` aplicado a uma lista de parâmetros e um deles é o próprio `Null`, e mesmo assim tudo funciona corretamente? O segredo para isso é a função `lazy()`, que é usada no interior de `symbolic()`. Ela captura a *expressão* que define a derivada, mas não a executa. De fato, não preciso computar a derivada de uma função logo que a defino, só precisamos saber *como* computá-la, e é precisamente isso que `lazy(df)` faz. Somente em `D()` que preciso ter a derivada computada de fato, e lá que uso `lazy_eval()` para obtê-la.

Experimente rodar o código anterior retirando as chamadas a `lazy()`. Você irá obter a seguinte mensagem de erro:

    Error in symbolic(f = function(x) 0, repr = "0", df = Null, type = "null") : 
    object 'Null' not found

Isto ocorre porque `Null` ainda não está definido no momento em que `symbolic()` é chamada. A lazy evaluation cortorna isto. Ela diz que, quando eu quiser calcular a derivada de `Null`, basta retornar a própria `Null`. Só que quando isso acontecer, `Null` já terá sido definida. Problema resolvido :)

Podemos, então, definir mais alguns tipos de funções:

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

# Monômios
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

Sendo estrito, a definição de inversa de monômios que dei só vale para domínio nos positivos, mas este é o tipo de sofisticação que ainda não resolverei nesta série de posts. Testando pra ver se está tudo funcionando corretamente:

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

Até agora conseguimos definir algumas funções elementares, mas ainda não podemos fazer nada muito divertido com elas. O cálculo começa a ficar interessante quando podemos definir novas funções através de somas, produtos e, com destaque especial, composições. No próximo post da série explicarei como adicionar isto ao sistema. Até lá!

-   [Parte 2/4: Definindo somas, produtos e composições](http://lurodrigo.com/2017/05/computacao-simbolica-R-2-4/)
-   Parte 3/4: Ensinando as simplificações álgebricas
-   Parte 4/4: Tornando a representação das funções mais inteligente

O código como encontrado ao final deste post pode ser visto [aqui](https://github.com/lurodrigo/symbolic/blob/master/R/symbolic_01.R).
