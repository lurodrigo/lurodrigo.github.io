---
title:  "Partições e idiomas"
date:   2017-08-23 20:00:00 -0300
categories:
  - Português
  - Matemática
  - Álgebra
tags:
  - Álgebra
  - Partições
  - Equivalência
mathjax: true
excerpt: "Uma condição matemática para a classificação de idiomas"
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

Este ano comecei a ler o livro [Not Exactly: In Praise of Vagueness][1]. O objetivo
do livro é mostrar como a imprecisão é inerente às nossas tentativas de entender
o mundo e como a filosofia, a linguística e a ciência da computação tentam lidar com
essa questão.

Um caso simples que ilustra esse problema: como classificar a fala das pessoas
em idiomas? Por que, por exemplo, o português e o espanhol são
considerados idiomas diferentes, ainda que tenham muito léxico, sintaxe e história em comum?
O que faz com que o português falado em Lisboa e o português
falado em Natal sejam considerados o mesmo idioma, ainda que existam várias
diferenças em léxico, sintaxe e fonética? Em que momento as diferenças
deixam de meramente definir dialetos diferentes e passam a definir novos idiomas?
Ou seja, como classificamos os dialetos em categorias maiores, *idiomas*,
de uma forma que faça algum sentido?

## Partições e relações de equivalência

Esse tipo de classificação, no jargão matemático, se chama de *partição*. Imagine
que temos um conjunto $A$. Uma partição $P$ do conjunto $A$ seria uma coleção
de subconjuntos de $A$ satisfazendo dois critérios:

* Todo elemento de $A$ está em algum conjunto de $P$.
* Um elemento de $A$ não pode estar em dois conjuntos diferentes de $P$ ao mesmo tempo.

Se voltarmos ao problema de dividir dialetos em idiomas, isso equivale a
a impôr as seguintes restrições à nossa tarefa:

* Todo dialeto pertence a algum idioma.
* Um dialeto não pode pertencer a dois idiomas ao mesmo tempo.

Razoável, não? Pois bem, continuemos. Quando a partição está feita, podemos
pensar que os elementos de um mesmo conjunto de $P$ têm algo em comum, são,
em algum sentido, *equivalentes*. Matematicamente, uma partição induz uma
relação de equivalência, uma relação $\equiv$ que satisfaz as seguintes propriedades:

* É *reflexiva*: $A \equiv A$, todo $A$ está relacionado a si mesmo.
* É *simétrica*: Para quaisquer $A$ e $B$, quando $A \equiv B$, $B \equiv A$ também. Isto é, quando A está relacionado a B, B está relacionado a A.
* É *transitiva*: Quando $A \equiv B$ e $B \equiv C$, $A \equiv C$ também. Ou seja, quando A está ligado a B e B está ligado a C, A está ligado a C também.

Uma relação de equivalência é, em essência, uma relação que tem uma estrutura
parecida com a relação familiar de igualdade. Podemos verificar que a relação
"pertencer a um mesmo conjunto na partição" define uma relação de equivalência:

* É reflexiva, pois todo elemento de $A$ está no mesmo conjunto de $P$ que o próprio $A$, por óbvio.
* É simétrica. Dizer que $A$ e $B$ ou que $B$ e $A$ estão num mesmo conjunto dá no mesmo.
* É transitiva. Quando $A$ e $B$ estão no mesmo conjunto, $B$ e $C$ estão no mesmo conjunto, $A$ e $C$ estão no mesmo conjunto também, pois do contrário $B$ teria que estar em dois conjuntos diferentes de $P$, um absurdo.

A verdade é que partições e relações de equivalência são, essencialmente, dois
modos diferentes de enxergar a mesma coisa. Assim como toda
partição induz uma relação de equivalência, toda relação de equivalência induz uma
partição. Essa partição é feita de modo intuitivo: colocamos dois elementos num mesmo
conjunto quando eles são equivalentes (segundo a relação de equivalência que estabelecemos).
Cada conjunto desses é denominado uma *classe de equivalência*, e a partição
é a coleção formada por todas essas classes de equivalência.

Para exemplificar: peguemos o conjunto $A = \\{0, 1, 2, 3, 4, 5, 6, 7, 8, 9\\}$. Uma relação
de equivalência que podemos definir sobre ele é a seguinte: chamaremos dois elementos
desse conjunto de equivalentes quando o resto da divisão deles por 2 for o mesmo.
Essa relação induz uma partição: podemos formar a classe de equivalência de
todos os elementos cujo resto da divisão por 2 é 0, $\\{0, 2, 4, 6, 8\\}$ e a classe
de equivalência dos elementos que deixam resto 1, $\\{1, 3, 5, 7, 9\\}$. Ou seja,
a relação de equivalência que defini particionou o conjunto em dois,
os pares e os ímpares.

A matemática nos permite concluir o seguinte: para construir partições,
podemos pensar em critérios, relações de equivalência. **Mas para isso, é necessário
que esse critério satisfaça reflexividade, simetria e, em especial, transitividade.**

## Inteligibilidade mútua

Bem, temos que pensar em um critério para distinguir entre dialetos e idiomas.
O mais simples que se pode pensar é o da *inteligibilidade mútua*: dois
dialetos fazem parte
de um mesmo idioma se os falantes de um, sem treinamento ou exposição prévia,
conseguem se comunicar sem muitos problemas com os do outro, e vice-versa. Razoável,
se pensarmos que o papel fundamental da linguagem é de mediar a comunicação.

Segundo a teoria matemática construída, esse critério só vai funcionar se for
transitivo, o que infelizmente não é o caso. Um exemplo onde a inteligibilidade
mútua falha em ser transitiva é o caso
de *contínuo de dialetos*. Tipicamente os dialetos tendem a ir se diferenciando
conforme a distância geográfica. Um dialeto A é parecido com um dialeto B falado a 100km,
que é parecido com dialeto C a 100km de B, e assim vai. Essas diferenças vão
se acumulando de tal forma que uma hora chegaremos em um dialeto Z que já não conversa
mais com o dialeto A.

A península ibérica fornece um exemplo: O português do sul entende o português
do norte, o português do norte entende o galego, já na Espanha, o galego entende
o falante de leonês, que entende o falante de castelhano. Mas o português não
é mutuamente inteligível com o castelhano! Se galego é um dialeto
de português ou um idioma a parte é uma questão que ainda gera debates, e qualquer resposta
a favor de um lado ou de outro será arbitrária.

Podemos modificar nosso critério para tentar resolver o problema da transitividade.
Dizemos que dois dialetos são de um mesmo idioma quando são mutuamente inteligíveis
ou quando, ao menos, existe uma *variadade padronizada*, uma versão *lingua franca*
dele que os falantes de ambos dialetos entendem e podem usar para se comunicar.
É o que acontece com o árabe, o mandarim e o alemão, por exemplo. Isso implica,
no entanto, aceitar que o cantonês e o chinês de Shanghai são o mesmo
idioma, embora uma conversa entre falantes das duas variedades seja inviável.

Poderíamos levar isso mais adiante: poderíamos dizer que dois dialetos A e B são
de um mesmo idioma se existe uma sequência de dialetos A, C, D, E, ..., B onde
cada dialeto é mutuamente inteligível com o próximo. Matematicamente, a solução
é perfeita. Mas a consequência é que com esse critério teríamos apenas um
punhado de idiomas no mundo: o indo-europeu, o semita, o austronésio e etc. E
de que adiantaria um critério tão amplo como esse? Nada. Não tem jeito: sem transitivade,
qualquer critério vai pecar por falta ou excesso.

[1]: https://www.amazon.com/Not-Exactly-Kees-van-Deemter/dp/0199645736
