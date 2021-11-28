---
title:  "Criando nossos próprios verbos no dplyr"
date:   2017-09-29 21:50:00 -0300
categories:
  - R
  - R_pt
  - Português
  - Arquivo
tags:
  - dplyr
  - R
  - rlang
  - purrr
  - tidyeval
  - Metaprogramação
excerpt: "Um estudo de caso sobre tidy evaluation"
---

Esse post é bem antigo. Muita coisa pode estar incorreta devido a novidades que aconteceram desde então, ou porque meu entendimento na época não era tão claro. 
{: .notice--warning}

Uma das decisões que tomei como programador R esse ano foi usar as soluções do tidyverse sempre que possível, ainda que pacotes fora dele oferecessem soluções computacionalmente mais eficientes. Isso implica, naturalmente, optar pelo dplyr em vez do data.table. O motivo é que, basicamente, percebi que os recursos computacionais maiores que o dplyr consome são mais baratos que o tempo que eu levava para tentar lembrar o que os hieroglifos do data.table significavam um mês depois que haviam sido escritos.

Entretanto, senti falta de algumas conveniências do data.table, em particular, a possibilidade de alteração de colunas condicional às linhas. Considere o seguinte exemplo: descobri que, devido a alguma falha no sistema, todos os voos registrados no dia primeiro de janeiro aconteceram, na verdade, no dia 7 de setembro. Seria bem simples corrigir isso usando data.table:

``` r
library(nycflights13)
library(data.table)

dt = data.table(flights)
head(dt)
#>    year month day dep_time sched_dep_time dep_delay arr_time
#> 1: 2013     1   1      517            515         2      830
#> 2: 2013     1   1      533            529         4      850
#> 3: 2013     1   1      542            540         2      923
#> 4: 2013     1   1      544            545        -1     1004
#> 5: 2013     1   1      554            600        -6      812
#> 6: 2013     1   1      554            558        -4      740
#>    sched_arr_time arr_delay carrier flight tailnum origin dest air_time
#> 1:            819        11      UA   1545  N14228    EWR  IAH      227
#> 2:            830        20      UA   1714  N24211    LGA  IAH      227
#> 3:            850        33      AA   1141  N619AA    JFK  MIA      160
#> 4:           1022       -18      B6    725  N804JB    JFK  BQN      183
#> 5:            837       -25      DL    461  N668DN    LGA  ATL      116
#> 6:            728        12      UA   1696  N39463    EWR  ORD      150
#>    distance hour minute           time_hour
#> 1:     1400    5     15 2013-01-01 05:00:00
#> 2:     1416    5     29 2013-01-01 05:00:00
#> 3:     1089    5     40 2013-01-01 05:00:00
#> 4:     1576    5     45 2013-01-01 05:00:00
#> 5:      762    6      0 2013-01-01 06:00:00
#> 6:      719    5     58 2013-01-01 05:00:00

dt[month == 1 & day == 1, `:=`(
  month = 7,
  day = 7
)]

head(dt[, .(month, day)])
#>    month day
#> 1:     7   7
#> 2:     7   7
#> 3:     7   7
#> 4:     7   7
#> 5:     7   7
#> 6:     7   7
```

Infelizmente, o dplyr não possui uma forma tão conveniente de tratar esses casos. A [recomendação semioficial](https://github.com/tidyverse/dplyr/issues/631) é usar vários `ifelse`s:

``` r
library(dplyr)

flights %>%
  mutate(
    month = ifelse(month == 1 & day == 1, 7, month),
    day = ifelse(month == 1 & day == 1, 7, day)
  ) %>%
  select(month, day)
#> # A tibble: 336,776 x 2
#>    month   day
#>    <dbl> <int>
#>  1     7     1
#>  2     7     1
#>  3     7     1
#>  4     7     1
#>  5     7     1
#>  6     7     1
#>  7     7     1
#>  8     7     1
#>  9     7     1
#> 10     7     1
#> # ... with 336,766 more rows
```

Opa! Ainda não está correto. Há diferenças semânticas fortes entre o `:=` do data.table e o `mutate`. O data.table primeiro descobre em quais linhas as operações devem ser realizadas e só depois as executa. O código dplyr acima não: a condição no `ifelse` é reavaliada a cada coluna alterada. Além disso, essas operações são feitas no escopo da tabela no estado em que estava antes da execução de qualquer modificação, enquanto o `mutate` sempre usa seu estado mais recente. É por isso que o resultado final não é o esperado: no momento em que a linha

``` r
day = ifelse(month == 1 & day == 1, 7, day)
```

é executada, os valores em `month` já foram modificados para 7 (onde foi o caso), a condição falha e os valores armazenados em `day` não são alterados. No entanto, um workaround é possível: podemos criar uma coluna temporária para armazenar o resultado da condição do ifelse e apagá-la depois das modificações:

``` r
flights %>%
  mutate(
    condicao = month == 1 & day == 1,
    month = ifelse(condicao, 7, month),
    day = ifelse(condicao, 7, day),
    condicao = NULL
  ) %>%
  select(month, day)
#> # A tibble: 336,776 x 2
#>    month   day
#>    <dbl> <dbl>
#>  1     7     7
#>  2     7     7
#>  3     7     7
#>  4     7     7
#>  5     7     7
#>  6     7     7
#>  7     7     7
#>  8     7     7
#>  9     7     7
#> 10     7     7
#> # ... with 336,766 more rows
```

Ok, funciona, mas ainda há duas inconveniências em relação à versão data.table: primeiro, precisamos manipular diretamente uma coluna lógica temporária, e depois, ainda temos que repetir explicitamente o nome da coluna dentro dos `ifelse`s para que o valor atual seja mantido quando a condição falhar.

Percebi, então, que o `mutate` é um verbo inconveniente nesse tipo de situação. Felizmente, o Tidyverse lançou, há algum tempo, o framework de *tidy evaluation* que permite, entre outras coisas, criar novos verbos para o dplyr com alguma facilidade. O objetivo desse post é criar verbos que funcionem de forma similar à sentença `dt[cond, col := val]` do data.table dentro do dplyr.

Criando o verbo `transform_where`
---------------------------------

A solução que desenvolvi para essa situação foi o verbo `transform_where`. Aqui está um exemplo do seu funcionamento:

``` r
flights %>%
  transform_where(
    month == 1 & day == 1,
    month = 7,
    day = 7
  ) %>%
  select(month, day)
#> # A tibble: 336,776 x 2
#>    month   day
#>    <dbl> <dbl>
#>  1     7     7
#>  2     7     7
#>  3     7     7
#>  4     7     7
#>  5     7     7
#>  6     7     7
#>  7     7     7
#>  8     7     7
#>  9     7     7
#> 10     7     7
#> # ... with 336,766 more rows
```

Tão compacto quanto a versão data.table e ainda tem a vantagem de produzir código fácil de ler! E quanto código isso levou? Bem, umas dez linhas:

``` r
library(rlang)
library(purrr)

transform_where = function(.data, condition, ...) {
  condition = enquo(condition) %>% eval_tidy(.data)
  mods = quos(...)

  mods = map2(mods, names(mods), function(quoted_expr, column_name) {
    quo(ifelse(condition, !!quoted_expr, !!sym(column_name))) %>%
      eval_tidy(.data)
  })

  mutate(.data, !!!mods)
}
```

Ok, o código é curto, mas é críptico para quem nunca teve contato com *non-standard evaluation* em geral, e com o framework de tidy evaluation em particular. Vou tentar explicar com algum detalhe como isso tudo está funcionando. Primeiro, os argumentos: `.data` representa a tabela, `condition` a condição, e `...`, os outros argumentos, isto é, as modificações que devem ser realizadas.

Vamos para a primeira linha.

``` r
condition = enquo(condition) %>% eval_tidy(.data)
```

`rlang::enquo` é uma função que faz alguma magia negra para guardar, numa estrutura chamada denominada *quosure*, a *expressão* que foi passada para `condition`, e não seu valor. Afinal, esse valor sequer é válido ainda, pois `month == 1 & day == 1` não indica explicitamente em que tabela `month` e `day` estão. É aqui que entra a função `rlang::eval_tidy`, que executa a expressão passada a ela dentro do ambiente indicado (`.data`). Agora o interpretador sabe onde procurar os `month` e `day`: são colunas da tabela `.data`, oras! Ao final dessa linha, condition guardará um vetor lógico, com `TRUE` nas linhas onde a condição passou e `FALSE` onde falhou. Próxima linha:

``` r
mods = quos(...)
```

`rlang::quos` faz a mesma coisa que `enquo`, mas para uma lista de expressões toda de uma vez. No caso em que essa lista tem nomes, eles também são guardados. Faça o teste:

``` r
func = function(...) {
  print(quos(...))
}

func(a == b, c + 1)
#> [[1]]
#> <quosure: global>
#> ~a == b
#>
#> [[2]]
#> <quosure: global>
#> ~c + 1
#>
#> attr(,"class")
#> [1] "quosures"
func(x = x + 2, y = y*3)
#> $x
#> <quosure: global>
#> ~x + 2
#>
#> $y
#> <quosure: global>
#> ~y * 3
#>
#> attr(,"class")
#> [1] "quosures"
```

A função a seguir é o coração de todo o processo. Ela transforma uma expressão `x = expr` em `x = ifelse(condition, expr, x)`. Ou seja, ela transforma assignments simples em expressões complexas envolvendo condições e `ifelse`s, nos poupando o trabalho de digitá-los.

``` r
function(quoted_expr, column_name) {
  quo(ifelse(condition, !!quoted_expr, !!sym(column_name))) %>%
    eval_tidy(.data)
}
#> function(quoted_expr, column_name) {
#>   quo(ifelse(condition, !!quoted_expr, !!sym(column_name))) %>%
#>     eval_tidy(.data)
#> }
```

Essa função tem dois parâmetros: `quoted_expr`, uma quosure com uma expressão capturada anteriormente, e `column_name`, o nome da coluna em uma string. A função `rlang::quo` salva a expressão passada como parâmetro em uma quosure, e o operador `!!` faz o inverso: transforma uma quosure numa expressão. A função `rlang::sym`, por sua vez, transforma uma string em uma expressão (um símbolo, mais especificamente). Agora já dá pra entender a ação da seguinte linha:

``` r
quo(ifelse(condition, !!quoted_expr, !!sym(column_name)))
```

Imaginemos que `quoted_expr` é uma quosure que guarda a expressão `7` e `column_name` é string `"month"`: após a ação do `!!`, a linha acima equivale a:

``` r
quo(ifelse(condition, 7, month))
```

Essa quosure resultante é passada para `eval_tidy`, que calcula o valor dessa expressão dentro da tabela `.data`. No fim, a função retorna um vetor contendo o novo valor da coluna.

Para quem não conhece, `purrr::map2` é essencialmente uma generalização de `lapply` que toma duas listas ou vetores como argumento, além de uma função de dois parâmetros. Dados `x = c(x1, x2, x3)`, `y = c(y1, y2, y2)` e `f`, retorna uma lista `list(f(x1, y1), f(x2, y2), f(x3, y3))`. Além disso, se o primeiro vetor ou lista tem `names`, esses `names` são mantidos na lista resultante. Agora já dá pra entender o trecho completo.

``` r
mods = map2(mods, names(mods), function(quoted_expr, column_name) {
  quo(ifelse(condition, !!quoted_expr, !!sym(column_name))) %>%
    eval_tidy(.data)
})
```

Pegamos `mods`, uma lista cujos `names` são os nomes das colunas e cujos valores são expressões, e retornamos uma nova lista com os mesmos `names`, nomes das colunas, mas com as colunas já calculadas a partir de um `ifelse` adequado.

Por último, o operador `!!!` é para `quos` o que `!!` é para `quo`: transforma uma lista de quosures em uma sequência de expressões. Então a última linha,

``` r
mutate(.data, !!!mods)
```

após a ação do `!!!`, equivale a

``` r
mutate(.data, x = vetorx, y = vetory)
```

onde `vetorx` e `vetory` são os resultados que foram obtidos anteriormente após a execução dos `ifelse`s. E pronto! Após todas essas manipulações de quosures, chegamos ao resultado que queríamos!

Criando um `mutate_where`:
--------------------------

Eu chamei a função de `transform_where` ao invés de `mutate_where` em analogia à diferença entre as funções `transform` e `mutate`: a primeira executa no contexto inicial da tabela, e a última, sempre no contexto mais recente. O exemplo abaixo esclarece a diferença.

``` r
df = data.frame(x = 1:5)
df %>% transform(x = x + 1, y = x + 1)
#>   x y
#> 1 2 2
#> 2 3 3
#> 3 4 4
#> 4 5 5
#> 5 6 6
df %>% mutate(x = x + 1, y = x + 1)
#>   x y
#> 1 2 3
#> 2 3 4
#> 3 4 5
#> 4 5 6
#> 5 6 7
```

Eu criei um `transform_where` porque parecia atender melhor minhas necessidades, mas é possível conceber situações onde um `mutate_where` fosse mais conveniente. É muito mais difícil fazer isso? Não. Eis o código:

``` r
mutate_where = function(.data, condition, ...) {
  condition = enquo(condition) %>% eval_tidy(.data)
  mods = quos(...)

  mods = map2(mods, names(mods), function(quoted_expr, column_name) {
    quo(ifelse(condition, !!quoted_expr, !!sym(column_name)))
  })

  mutate(.data, !!!mods)
}
```

Ele é *quase* igual ao código do `transform_where`, com uma pequena diferença: não há um `eval_tidy` dentro da função auxiliar. Isso faz com que, ao invés de se calcular logo o valor das colunas modificadas, apenas se substitua as expressões passadas por expressões envoltas por um `ifelse`. Ao contrário de antes, a linha

``` r
mutate(.data, !!!mods)
```

não vira

``` r
mutate(.data, x = vetorx, y = vetory)
```

e sim

``` r
mutate(.data, x = ifelse(condition, 7, x), y = ifelse(condition, 7, y))
```

então essas modificações são executadas com a semântica tradicional do dplyr, isto é, usando eventualmente os valores modificados que acabaram de ser computados, em vez dos valores guardados antes da execução da função.

Qual a melhor das duas funções? Depende do contexto. No caso que abriu o post, certamente um `transform_where` funciona melhor. Agora imagine uma situação onde os dados de partida e chegada estivessem incorretos em algumas linhas. A variável `air_time`, tempo de voo, também precisará ser atualizada. Nesse caso, um `mutate_where` corrigindo os valores de `dep_time` e `arr_time` e recalculando `air_time` como essa diferença resolverá a situação, enquanto um `transform_where`, iria, de fato, manter a coluna `air_time` como estava antes. Na prática, sempre tenho as duas em mãos.

**Exercício para o leitor:** Uma diferença entre o meu `transform_where` e o funcionamento do `data.table` é que esse último consegue criar colunas novas, preenchendo-as com `NA` nas linhas onde a condição é falsa. Sinceramente, esse comportamento me desagrada, por implicar que a tabela poderá sair com formatos diferentes dependendo de uma condição de forma nada explícita. De todo modo, como poderíamos modificar `transform_where` para que ela tenha esse comportamento?
