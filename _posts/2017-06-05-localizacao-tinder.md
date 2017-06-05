---
title:  "Como eu consegui descobrir a localização dos meus matches no Tinder (ou quase)"
date:   2017-06-05 15:00:00 -0300
categories:
  - Português
  - R
  - R_pt
  - Python
tags:
  - "Métodos Numéricos"
  - "Geometria Analítica"
  - Tinder
mathjax: true
excerpt: "Tl;dr: com matemática."
---

Eu já havia percebido uma vulnerabilidade de segurança no Tinder havia um tempo. 
Ele permite que você saiba as distâncias em que outros usuários se encontram em
relação a você. Embora pareça inofensiva, informações sobre distâncias, somadas 
a um pouco de perspicácia, permite descobrir a posição exata de qualquer pessoa na terra. 
Para isso, usa-se uma técnica chamada [*trilateração*][1]. Evidentemente, não
fui o primeiro a pensar neste problema: a técnica é usada no GPS, por exemplo,
e também já foi empregada com precisamente a mesma finalidade que a minha
pela [Include Security][2]. De todo modo, precisava de um tema para o projeto
da disciplina de Cálculo Numérico este semestre e essa ideia parecia viável
(para as minhas limitações de tempo) e suficientemente divertida, e cá estamos.

A técnica é baseada em geometria elementar. Consideremos, inicialmente, que a 
terra é perfeitamente plana. Imagine que um contato está
a uma distância de 5 quilômetros de você, que se encontra no ponto A. O conjunto de possíveis localizações
dele determina uma circunferência de 5km de raio. Agora você vai
para uma segunda posição B e verifica novamente a distância dita pelo aplicativo, que
agora é de 7km. Se o problema for bem posto, tipicamente a busca será reduzida
para duas possibilidades:

![]({{ site.url }}/images/01.png)

Movendo-se para uma terceira localização, basta comparar a distância fornecida
pelo aplicativo com a distância aos dois pontos que restaram, e será possível
eliminar o caso falso. Pronto, localização descoberta! Claro, você deve ter 
algumas objeções agora:

1. **A distância fornecida pelo Tinder é arredondada, não é a distância real.**. No aplicativo não, mas
a [*Pynder*][3], API pirata do Tinder para Python, permite pegar a distância 
com precisão dupla. Se essa distância for a correta, estamos bem. 
2. **A premissa de que a pessoa não se move enquanto mudamos de posição é muito forte!**.
De fato, mas a verdade é que esse deslocamento nunca será feito na prática. A API 
nos permite definir nossa latitude e longitude de forma arbitrária, sem termos 
que ter nos movido de fato.
3. **A terra não é plana, Luiz**. Claro, tanto que irei modelar a Terra como
uma esfera ao longo do texto. Apesar disso, em muitos aspectos a geometria 
da superfície da esfera é análoga a do plano, *quando os conceitos envolvidos
são corretamente correspondidos*, e essa intuição é de muito uso.

## A formulação matemática do problema

A terra será modelada como uma esfera de raio 6378.008km, que é o valor
calculado para o [raio médio da Terra][4] a partir do elipsoide [WGS-84][5]. 
A precisão obtida será, obviamente, menor que aquela que eu teria caso usasse o próprio 
WGS-84, mas ao menos para esse projeto o *trade-off* entre 0.5% de precisão e o
grande ganho em simplicidade das contas compensa. A posição de um ponto na superfície
dessa esfera é especificada por uma latitude e uma longitude, costumeiramente
representados pelas letras $\phi$ e $\lambda$, respectivamente.

![]({{ site.url }}/images/Central_angle.svg){: .align-right}

Neste caso, o ângulo central $\Delta\sigma$ entre os pontos $\phi_1, \lambda_1$ e $\phi_2, \lambda_2$ é
dado pela fórmula 

$$\Delta\sigma((\phi_1, \lambda_1), (\phi_2, \lambda_2))=\arccos\bigl(\sin\phi_1\cdot\sin\phi_2+\cos\phi_1\cdot\cos\phi_2\cdot\cos(\Delta\lambda)\bigr)$$

Para obter a distância de fato, basta multiplicar este ângulo pelo raio da Terra. Na prática,
acho mais interessante trabalhar com os ângulos centrais diretamente que com as distâncias.

Medições são feitas em três pontos $A = (\phi_A, \lambda_A)$, 
$B = (\phi_B, \lambda_B)$ e $C = (\phi_C, \lambda_C)$ arbitrários. A única restrição é que
três pontos não sejam colineares, ou melhor, que não estejam na mesma *geodésia*,
o análogo ao conceito de reta quanto falamos da superfície da Terra. Isso deve ser observado
porque, neste caso, o terceiro ponto é inútil em distinguir 
a posição real entre a posição falsa, dado que as distâncias observadas serão as 
mesmas.

![]({{ site.url }}/images/02.png)

O objetivo é descobrir qual o ponto $P = (\phi_*, \lambda_*)$ com medições de 
ângulo central
$d_A = \Delta\sigma(P, A)$, $d_B = \Delta\sigma(P, B)$ e $d_C = \Delta\sigma(P, C)$.
Definindo a função $F(X) = (\Delta\sigma(X, A) - d_A, \Delta\sigma(X, B) - d_B)$, 
vê-se claramente que o ponto que estamos procurando é uma raiz de F. Portanto,
nosso problema se resume em encontrar as soluções da equação $F(X) = 0$.


## A coleta dos dados

## O sistema de coordenadas conveniente

## A solução numérica

## O resultado final

## Try it yourself!

[1]:https://en.wikipedia.org/wiki/Trilateration
[2]:http://blog.includesecurity.com/2014/02/how-i-was-able-to-track-location-of-any.html
[3]:https://github.com/charliewolf/pynder
[4]:https://en.wikipedia.org/wiki/Earth_radius#Mean_radius
[5]:https://en.wikipedia.org/wiki/World_Geodetic_System#WGS84
