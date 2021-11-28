---
title:  "Sobre uma pequena conexão entre anagramas e números primos"
date:   2018-04-26 10:00:00 -0300
categories:
  - Português
  - Matemática
  - Computação
tags:
  - Álgebra
  - Algoritmos
  - Computação
  - Aritmética
  - Números primos
mathjax: true
excerpt: "Ou: pensando como um algebrista."
---

<script type="text/javascript" async
  src="https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.5/MathJax.js?config=TeX-MML-AM_CHTML">
</script>

<script type="text/x-mathjax-config">
        MathJax.Hub.Config({
            extensions: ["tex2jax.js"],
            jax: ["input/TeX", "output/HTML-CSS"],
            tex2jax: {
                inlineMath: [ ['$','$'], ["\\(","\\)"] ],
                displayMath: [ ['$$','$$'], ["\\[","\\]"] ],
                processEscapes: true
            },
        "HTML-CSS": { availableFonts: ["TeX"] }
  });
</script>

Esses dias estava circulando no twitter
o seguinte algoritmo para verificar se duas palavras são anagramas:

<blockquote class="twitter-tweet" data-lang="pt"><p lang="en" dir="ltr">Clever algorithm to find out whether or not 2 words are anagrams <a href="https://t.co/rRNqnq6wG9">pic.twitter.com/rRNqnq6wG9</a></p>&mdash; Fermat&#39;s Library (@fermatslibrary) <a href="https://twitter.com/fermatslibrary/status/988399621402656773?ref_src=twsrc%5Etfw">23 de abril de 2018</a></blockquote>
<script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

*Tradução livre: Algoritmo esperto para descobrir se duas palavras são ou não
anagramas.*

*Relacione cada uma das 26 letras A, B, C, D\dots a um número primo. Multiplique
os primos correspondentes às letras de cada palavra. Como todo inteiro é um
primo ou um produto único de primos (pelo [Teorema Fundamental da Aritmética][1]),
duas palavras são anagramas se os resultados forem iguais. Exemplo:*

$$f(A) = 2, f(E) = 5, f(R) = 7$$

$$f(ARE) = 2 \times 7 \times 5 = 70$$

$$f(EAR) = 5 \times 2 \times 7 = 70$$

Do ponto de vista técnico, há problemas<sup><a href="#1">\[1\]</a></sup> a serem considerados para uma implementação
computacional efetiva desse algoritmo, mas
é possível identificar uma estrutura matemática até rica e profunda nele. Ao
mesmo tempo, é suficientemente simples para ser entendido por não-matemáticos.
A ideia do post é identificar quais as estruturas algébricas envolvidas nessa
ligação entre anagramas e aritmética.

## Um pouquinho de terminologia da álgebra

*Matemáticos podem pular essa seção.*
{: .notice}

Uma *estrutura algébrica* é um conjunto que tem algumas operações definidas sobre ele.
Uma estrutura álgebra que todos conhecem é o *conjunto*, a estrutura que obtemos quando
não definimos nenhuma operação. :)

Falemos de estruturas algébricas mais interessantes. Um *monoide* é um conjunto com uma
operação binária $\cdot$ satisfazendo duas condições:

* Associatividade: Dados três elementos $a, b, c$ do conjunto, vale
$(a \cdot b) \cdot c = a \cdot (b \cdot c)$. Essencialmente, isso quer dizer
que, dada uma sequência de operações a serem realizadas, não trocando
a ordem dos elementos, tanto faz se começo a fazer as contas pela esquerda
ou pela direita.

* Elemento neutro: Existe um elemento $e$ de modo que, qualquer que seja
o elemento $a$ do conjunto, vale $a \cdot e = e \cdot a = a$. Ou seja,
fazer a conta quando um dos operandos é $e$ não muda o resultado.

Sejamos mais concretos.

*Exemplo 1:* Um exemplo de monoide é $(\mathbb{N} \cup \\{0\\}, +)$, isto é, o
conjunto dos inteiros não-negativos com a operação soma. Considere a soma $2 + 3 + 5$,
por exemplo. Essa soma poderia ser feita
de dois modos: $(2 + 3) + 5 = 5 + 5 = 10$ ou $2 + (3 + 5) = 2 + 8 = 10$. Nos
dois casos, tivemos o mesmo resultado. Como isso acontece quaisquer que sejam
os números escolhidos, podemos dizer que a soma é associativa. O elemento
neutro da soma é o número $0$, que não faz nenhuma diferença ao ser somado
com algum outro número.

$(\mathbb{N}, \times)$ (sem o zero!) também é um monoide. Por exemplo,
$(2 \times 3) \times 5 = 6 \times 5 = 30 = 2 \times 15 = 2 \times (3 \times 5)$,
e isso acontece independentemente da escolha dos números. O elemento
neutro da multiplicação é o número $1$, que não faz nenhuma diferença quando
multiplicado com algum outro número.

*Exemplo 2:* Em computação, uma *string* é uma sequência de caracteres de
algum alfabeto finito. Exemplos são "Tamarindo", "isso não é uma string" e
"" (a string vazia). Uma operação natural envolvendo strings é a *concatenação*
(que aqui chamo de ++), que consiste em adicionar os caracteres de uma string
ao final da outra: "monoides" ++ "e" ++ "tal" = "monoidesetal". O conjunto
das strings, junto com a operação de concatenação, forma um monoide, onde o
elemento neutro é a string vazia.

*Exemplo 3:* Um exemplo um pouco semelhante é dado pelas tabelas.
Tabelas com colunas compatíveis podem ser concatenadas, gerando uma tabela
com os dados das duas. A tabela com 0 linhas é o elemento neutro desse monoide.

*Exemplo 4:* Os exemplos 2 e 3 foram construídos da mesma maneira.
São exemplos de [monoides livres][5], aqueles construídos como o conjunto de sequências sobre um
determinado alfabeto, com a operação de concatenação. Em um caso o alfabeto é de fato constituído por caracteres,
no outro, os "caracteres" são os valores possíveis que uma linha pode assumir.

*Exemplo 5:* Pensemos em somente dois valores: `par` ou `ímpar`. Definimos uma
operação soma sobre esses dois valores de forma intuitiva: `par` + `par` =
`ímpar` + `ímpar` = `par` e `par` + `ímpar` = `ímpar` + `par` = `ímpar`. O conjunto {`par`, `impar`} com essa soma é um monoide, onde
o elemento neutro é `par`.

Podemos pensar monoides como uma estrutura em que elementos
podem ser "combinados" ou "acumulados" de certa forma. Acontece que, abstraindo
um pouco as particularidades dos objetos e das operações, percebemos que alguns
monoides se comportam da mesma maneira que outros.

Pense no conjunto
$\\{1, 2, 4, 8, 16, \dots\\}$ isto é, as potências inteiras e positivas de 2. Se
multiplicamos duas potências de base 2, conseguimos uma terceira potência
de base 2. $4 = 2 \times 2$, $8 = 2 \times 2 \times 2$, e multiplicando
4 por 8 temos 32, que é $2 \times 2 \times 2 \times 2 \times 2$. Quando
multiplicamos duas potências de base dois, o que estamos fazendo é essencialmente
contar quantos 2 multiplicados aparecem nos dois números, e somamos. Em 4,
temos o número 2 repetido duas vezes; em 8, repetido três vezes; logo, o resultado
é o número onde 2 aparece cinco vezes, 32. Num certo sentido, multiplicar
potências de uma mesma base é *a mesma coisa* que somar.

Essa intuição pode ser formalizada. Dizemos que o monoide do exemplo 1
(os naturais e zero com a soma) e o monoide que acabei de criar são *isomórficos*.
Um *isomorfismo* (de monoides) é uma correspondência 1-pra-1 (em matematiquês, uma função bijetiva)
entre os elementos dos monoides que mantém as operações funcionando.
Isso quer dizer que eu posso trabalhar com um monoide ou com o outro
conforme a conveniência, porque do **ponto de vista das operações, esses dois
monoides são apenas representações diferentes da mesma coisa**.

No caso anterior, o isomorfismo é dado pela função $f: n \mapsto 2^n$. $f$ leva 0 em 1,
1 em 2, 2 em 4, 3 em 8, 4 em 16 e assim vai. Essa função
é inversível: podemos voltar atrás com a função $f^{-1}: n \mapsto \log_2 n$.
Com 8, temos $\log_2 8 = 3$; com 16, $\log_2 16 = 4$; enfim, podemos transitar
livremente entre um conjunto e outro usando $f$ e $f^{-1}$.

*Observação:* se temos uma correspondência 1-para-1 entre $\\{0, 1, 2, 3, 4, \dots\\}$
e $\\{1, 2, 4, 8, \dots\\}$, significa que os dois conjuntos têm a mesma
quantidade de elementos, ainda que o segundo seja apenas uma parte do primeiro.
Conjuntos infinitos são complicados.
{: .notice}

Eu havia dito que um isomorfismo mantém as operações funcionando. Matematicamente,
se temos dois monoides $(A, \cdot_A)$ e $(B, \cdot_B)$, um isomorfismo $f$ satisfaz
a condição  $f(a \cdot_A b) = f(a) \cdot_B f(b)$. Pensemos no caso concreto
em que estamos trabalhando. Os monoides são $(\mathbb{N} \cup \\{0\\}, +)$ e
$(\\{1, 2, 4, 8, \dots\\}, \times)$. Temos $f(2) = 4$, $f(3) = 8$ e $f(2 + 3) = f(5) = 32$.
Observamos que $f(2 + 3) = f(2) \times f(3)$! Podemos somar os números primeiro
e depois transformar, podemos transformar os números primeiro e depois multiplicar:
tudo vai dar no mesmo.

Pensando na outra direção, acabamos de inventar um jeito de fazer multiplicações
fazendo apenas somas. Para multiplicar dois números, olhamos qual potência
de base 2 corresponde a esses números. Somamos os expoentes dessas potências,
e calculamos a potência com esse novo expoente. Isso é *exatamente* o que os logaritmos fazem.
logaritmos são isomorfismos entre grupos (uma especialização dos monoides),
que transformam multiplicações em adições. Isso teve uma grande importância
histórica, pois na falta de computadores é mais fácil e seguro fazer somas
que multiplicações. Na verdade, até com computadores isso às vezes acontece.

![]({{site.url}}/images/tabela_log.jpg)

Para multiplicar dois números grandes,
olhamos o logaritmo deles (na tabela de logaritmos), somamos esses números
e olhamos na tabela qual número tem o logaritmo igual a essa soma. O número
encontrado é a multiplicação dos dois anteriores.

De modo geral, o papel dos isomorfismos é tirar toda a bagunça que está
sobre um objeto complicado e mostrar que, no fundo, aquele objeto é mais simples
do que parecia inicialmente.

## E o que isso tem a ver com anagramas?

Como podemos descobrir se duas strings são anagramas uma da outra? Bem, um modo
de fazer isso é colocando as duas em ordem alfabética. "are" e "ear", quando
postas em ordem alfabética, viram ambas "aer", logo, são anagramas. E como
podemos ordenar strings? O modo mais eficiente (computacionalmente) para isso é
contar quantas vezes cada caractere aparece e, a partir disso, construir uma nova string.
Esse algoritmo se chama [Counting Sort][2] e é o método
de ordenação mais eficiente que há para certos tipos de dados.

Um exemplo do seu uso: em "amar" temos 'a' repetido 2 vezes e
'm' e 'r' aparecendo uma vez cada. Portanto, a ordenação de "amar" é "aarm".
Como "arma" quando ordenada também vira "aarm", concluímos que "arma" e "amar"
são anagramas.

Observamos uma coisa: não precisamos de fato ordenar as palavras para verificar
se são anagramas. A ordem das letras dentro da palavra não importa, só precisamos
saber quantas vezes cada letra aparece. Se a contagem bater, são anagramas.

Um isomorfismo preserva informação. Já a contagem de aparições de letras em
palavras, que chamarei de $[\cdot]$, descarta informação. É possível ir de "amar" ao
[multiconjunto][3] ["amar"] = {'a': 2, 'm': 1, 'r': 1}, mas de {'a': 2, 'm': 1, 'r': 1}
não há como distinguir entre "amar" ou "arma". Essa transformação não é um
isomorfismo.

A operação correspondente à concatenação é a soma de multiconjuntos. Por exemplo,
a soma de dois multiconjuntos onde 'a' aparece duas vezes e 'm' e 'r' aparecem uma vez
é um multiconjunto onde 'a' aparece quatro vezes e 'm' e 'r' aparecem duas vezes.
A transformação preserva a estrutura da operação: ["arma" ++ "amar"] = ["armaamar"] = {'a': 4, 'm': 2, 'r': 2} e
["arma"] ++ ["amar"] = {'a': 2, 'm': 1, 'r': 1} + {'a': 2, 'm': 1, 'r': 1} =
{'a': 4, 'm': 2, 'r': 2}. Podemos concatenar
duas strings e contar as letras ou contar as letras e
somar os multiconjuntos, dá no mesmo.

*Observação:* os matemáticos e leitores do [meu texto sobre partições][4]
talvez notem que a contagem de letras cria partições no conjunto de strings.
De fato, "ser anagrama de" é uma relação de equivalência: se A é anagrama de B
e B é anagrama de C, A é anagrama de C. As condições de reflexividade e simetria
são facilmente verificadas. Os multiconjuntos que obtemos aplicando
$[\cdot]$ às strings têm uma correspondência natural com (são isomórficos a)
as classes de equivalência, formadas pelas strings que são anagramas entre si.
{: .notice}

Quando apenas a estrutura é garantidamente
preservada, temos um *homomorfismo*. Homomorfismos são a regra geral;
isomorfismos são um caso particular: nem sempre é possível ou desejável preservar
informação. Um outro exemplo de homomorfismo que não preserva informação é
dado pela função que leva um inteiro $n$ em `par` ou `impar`,
se $n$ for par ou ímpar, respectivamente (ver exemplo 5). Com isso, provamos
que, para verificar se a soma de vários números inteiros é par ou ímpar, não
precisamos nem conhecer quais números estamos somando, só precisamos saber quantos ímpares e quantos pares
temos. Afinal, se é homomorfismo, tanto faz se primeiro somamos e depois verificamos
paridade ou se primeiro verificamos paridade e depois somamos!

Voltando. Na verdade, com o homomorfismo que construímos, não apenas preservamos como
ganhamos estrutura: a soma de multiconjuntos é *comutativa*, enquanto a
concatenação de strings não é. Podemos somar dois multiconjuntos em qualquer
ordem e teremos o mesmo resultado, mas a concatenação de strings depende
da ordem dos operandos. "abc" ++ "def" = "abcdef", enquanto "def" ++ "abc" = "defabc".
A comutatividade de uma operação costuma ser desejável porque garante que podemos
utilizar vários resultados previstos para operações comutativas. Todos
os resultados que conhecemos para monoides valem para monoides comutativos, mas
existem teoremas que valem exclusivamente para monoides comutativos.
De certa forma, fizemos uma troca: perdemos informação para ganhar estrutura.
E, nesse caso, a comutativade é fundamental: é justamente ela que garante que
o resultado da contagem dará o mesmo independente da ordem das letras, oras!

Por último, notamos que há um isomorfismo entre multiconjuntos
e (uma parte dos<sup><a href="#2">\[2\]</a></sup>) números inteiros.
Para um alfabeto com três letras, temos multiconjuntos
com três letras (e suas repetições). Podemos associar
a primeira letra ao número 2, a segunda ao número 3 e a terceira ao 5. Se
tivermos mais letras, é só continuar na sequência de primos.

O fato dessa ligação entre letras e primos ser um isomorfismo garante que
contar mais uma letra é a mesma coisa que multiplicar pelo primo correspondente.
Aplicando isso à string toda, descobrimos que contar todas as letras é *matematicamente a mesma coisa*
que multiplicar números primos, são apenas representações diferentes da mesma operação.

Para fechar, um último comentário: se a associação fosse apenas um homomorfismo,
não teríamos falsos negativos. Se duas palavras têm as mesmas letras, elas
iriam para os mesmos números, que multiplicados dariam o mesmo resultado. O problema
é com falsos positivos: poderia ser que, dependendo da forma como a associação
entre letras e números fosse feita, palavras formadas por letras diferentes
levassem ao mesmo resultado de multiplicação. Um exemplo é 'a' $\mapsto$ 2,
'b' $\mapsto$ 18, 'c' $\mapsto$ 3, 'd' $\mapsto$ 12. "ab" vai em $2 \times 18 = 36$,
o mesmo resultado de "cd", que vai em $3 \times 12 = 36$. Isso não acontece
com primos, pois o [Teorema Fundamental da Aritmética][1]
garante que existe um *único* jeito de formar um número como multiplicação de
primos. Isso garante o isomorfismo: como essa decomposição é única, basta
contar quantas vezes cada primo aparece para reconstruir a contagem original das letras.

### Mas tanta linguagem nova pra quê?

O leitor crítico pode se perguntar por que fazer uma análise tão minuciosa,
repleta de terminologia técnica, de um algoritmo relativamente trivial.
A resposta imediata é que isso tudo é muito divertido e bonito. A resposta séria é que,
quando abstraímos as particularidades dos objetos que estamos trabalhando e pensamos só na forma
como os objetos se relacionam uns com os outros, podemos aplicar as mesmas técnicas
para objetos que se comportam da mesma forma, ainda que venham de contextos
completamente diferentes!

De fato, eu comentei no exemplo 4 que as strings são apenas um caso particular
de uma construção mais geral: sequências finitas sobre um alfabeto. Isso implica
que o algoritmo que estudamos pode ser aplicado, em princípio, para verificar
"anagramas" em qualquer tipo de sequência. Poderíamos, por exemplo,
verificar se dois textos diferentes são compostos exatamente das mesmas palavras,
usando a mesma técnica.

Para que o algoritmo funcione,
tanto faz a natureza dos objetos: sequências de caracteres, tabelas, imagens, *whatever*!
O que importa são as propriedades desses objetos quando combinados. Não a toa
essas ideias, importadas da álgebra abstrata,
são aplicadas em programação funcional: podemos escrever um mesmo código
para trabalhar com infinitos tipos de objetos, desde que tenham uma certa estrutura em comum.

<span id="1">\[1\]</span>: O principal problema técnico desse algoritmo é que o resultado da multiplicação
de vários primos vai crescendo rapidamente à medida que a quantidade de letras
aumenta, e os computadores tipicamente só conseguem armazenar de forma eficiente
números inteiros de até um certo tamanho. Acima disso, o algoritmo vai se
comportar de forma muito pouco eficiente. Talvez com outro modelo de computação
essa implementação seja mais viável.

<span id="2">\[2\]</span>: Tecnicamente, o isomorfismo é entre os multiconjuntos com $n$ letras
e o conjunto dos inteiros que não têm outros fatores primos que não os $n$ primeiros
primos.

[1]: https://pt.wikipedia.org/wiki/Teorema_fundamental_da_aritm%C3%A9tica
[2]: https://en.wikipedia.org/wiki/Counting_sort
[3]: https://pt.wikipedia.org/wiki/Multiconjunto
[4]: {{site.url}}/2017/08/classificacao/
[5]: https://pt.wikipedia.org/wiki/Monoide_livre
