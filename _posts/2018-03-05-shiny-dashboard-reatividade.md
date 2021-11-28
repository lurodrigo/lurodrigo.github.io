---
title:  "Uma introdução ao Shiny e reatividade"
date:   2018-03-05 10:00:00 -0300
categories:
  - R
  - R_pt
  - Português
  - Arquivo
tags:
  - R
  - Shiny
  - Reatividade
  - shinydashboard
mathjax: true
excerpt: "Entendendo as ferramentas para controle da reatividade no Shiny"
---

Esse post é bem antigo. Muita coisa pode estar incorreta devido a novidades que aconteceram desde então, ou porque meu entendimento na época não era tão claro. 
{: .notice--warning}

O Shiny é um framework web para criação de aplicativos interativos. Diferente dos frameworks para desenvolvimento web usuais, não há, *necessariamente*, necessidade de conhecer HTML, CSS ou Javascript, as linguagens básicas usadas para construir páginas da web.

A estrutura de um aplicativo Shiny
----------------------------------

Um aplicativo Shiny consiste de pelo menos dois arquivos: `ui.R` e `server.R`. O arquivo `ui.R` descreve a interface do aplicativo e o `server.R`, a lógica. Na verdade, é possível construir aplicativos em um único arquivo `app.R`, mas é um approach inadequado para qualquer aplicativo com alguma complexidade, então não comentarei sobre. Opcionalmente, é possível definir um arquivo `global.R`. Tudo que for definido no arquivo `global.R` estará acessível tanto em ambos `ui.R` e `server.R`. Portanto, recomendo usar o arquivo global para carregar os pacotes e definir funções, variáveis e constantes úteis para o aplicativo.

``` r
# global.R

library(shiny)
library(shinydashboard)
```

O arquivo `ui.R` especifica a estrutura da página através de uma *domain- specific language*. Essencialmente, o Shiny provê um conjunto de funções R que, nestadase combinadas de maneira adequada, geram o código HTML correspondente. Eu gosto de usar o pacote `shinydashboard`, que permite a criação de dashboards com estrutura um pouco mais complexa e melhor aparência em comparação aos aplicativos Shiny padrão sem ter que se preocupar muito com as configurações. A página mais simples possível a ser gerada com o Shiny Dashboard é a seguinte:

``` r
# ui.R

dashboardPage(
  dashboardHeader(),
  dashboardSidebar(),
  dashboardBody()
)
```

Note que isso só gera HTML:

``` r
print(dashboardPage(
  dashboardHeader(),
  dashboardSidebar(),
  dashboardBody()
))
#> <body class="skin-blue" style="min-height: 611px;">
#>   <div class="wrapper">
#>     <header class="main-header">
#>       <span class="logo"></span>
#>       <nav class="navbar navbar-static-top" role="navigation">
#>         <span style="display:none;">
#>           <i class="fa fa-bars"></i>
#>         </span>
#>         <a href="#" class="sidebar-toggle" data-toggle="offcanvas" role="button">
#>           <span class="sr-only">Toggle navigation</span>
#>         </a>
#>         <div class="navbar-custom-menu">
#>           <ul class="nav navbar-nav"></ul>
#>         </div>
#>       </nav>
#>     </header>
#>     <aside class="main-sidebar" data-collapsed="false">
#>       <section class="sidebar"></section>
#>     </aside>
#>     <div class="content-wrapper">
#>       <section class="content"></section>
#>     </div>
#>   </div>
#> </body>
```

O arquivo `server.R` deve se encerrar em uma função com três parâmetros: `input`, `output` e `session`, sendo o último opcional. Logo, o arquivo `server.R` mais simples é o seguinte:

``` r
# server.R

function(input, output, session) {
  
}
```

Tendo esses três arquivos, já é possível gerar nosso primeiro aplicativo Shiny. No RStudio, clique no botão "Run App" que está onde o botão "Source" costumava estar.

![Bastante interessante]({{ site.url }}/images/principios/vazio.PNG)

Estrutura da UI
---------------

Podemos, é claro, customizar a interface. Podemos passar para a função `dashboardHeader()`, entre outras coisas, o parâmetro title. Também é possível criar menus *dropdown*.

``` r
dashboardHeader(title = "Appzinho")
```

As abas são criadas utilizando a função `sidebarMenu()` e passadas como parâmetro para o `dashboardSidebar()`. Para a função `sidebarMenu()` devem ser passados items criados com a função `menuItem()`. O primeiro item é o nome da aba como ela deve aparecer na sidebar. O parâmetro `tabName` é o mais importante: deve ser id único para identificar aquela aba. O parâmetro `icon`, opcional, associa à aba um ícone. Os identificadores que a função `icon` aceita podem ser encontrados [neste link](http://fontawesome.io/icons).

``` r
dashboardSidebar(
  sidebarMenu(
    menuItem("Aba 1", tabName = "aba1", icon = icon("star")),
    menuItem("Aba 2", tabName = "aba2", icon = icon("tag"))
  )
)
```

De modo similar, o *conteúdo* é especificado na função `tabItems()`, que deve ser passada como parâmetro para `dashboardBody()`. O conteúdo de cada aba é criado dentro da função `tabItem()`. Seu parâmetro mais importante é o `tabName`, que liga o link de uma aba na sidebar ao seu conteúdo. Obviamente, o valor de `tabName` deve corresponder ao de algum `menuItem()` da sidebar.

``` r
dashboardBody(
  tabItems(
    tabItem(tabName = "aba1", 
      "Conteúdo da primeira aba"
    ),
    tabItem(tabName = "aba2", 
      "Conteúdo da segunda aba"
    )
  )
)
```

Com todas essas modificações no arquivo `ui.R`:

``` r
# ui.R

dashboardPage(
  dashboardHeader(title = "Appzinho"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Aba 1", tabName = "aba1", icon = icon("star")),
      menuItem("Aba 2", tabName = "aba2", icon = icon("tag"))
    )
  ),
  dashboardBody(
    tabItems(
      tabItem(tabName = "aba1", 
        "Conteúdo da primeira aba"
      ),
      tabItem(tabName = "aba2", 
        "Conteúdo da segunda aba"
      )
    )
  )
)
```

![]({{ site.url }}/images/principios/ui.PNG)

O conteúdo se organiza dentro de caixinhas (*boxes*) que podem ser de quatro tipos diferentes: `box()`, `tabBox()`, `infoBox()`, `valueBox()`. A forma como eles se distribuem pela página pode ser por colunas, por linhas, ou um misto dos dois. A [página do shinydashboard](http://rstudio.github.io/shinydashboard/structure.html) explica melhor essas possibilidades. Por enquanto, vou apenas criar duas caixinhas vazias para, nas próximas seções, criar alguma funcionalidade.

``` r
dashboardBody(
    tabItems(
      tabItem(tabName = "aba1", 
        fluidRow(
          box(title = "Opções"),
          box(title = "Resultado", status = "primary")
        )
      ),
      tabItem(tabName = "aba2", 
        "Conteúdo da segunda aba"
      )
    )
  )
```

![]({{ site.url }}/images/principios/boxes.PNG)

Eventos vs Reatividade
----------------------

A lógica pela qual as interações usuário-sistema ocorrem no Shiny é um pouco diferente do que ocorre em outros frameworks. A grande maioria deles utiliza uma lógica baseada em eventos. Isto inclui VBA, jQuery, .NET... Esses frameworks functionam, essencialmente, a partir da definição de *handlers* para eventos que te interessam. Por exemplo, imagine que uma interface tem uma caixinha "Sim/Não" cujo valor interferisse na interface. Você teria que escrever código que transformasse a interface do estado "sim" para o estado "não" e vice-versa.

O principal problema do *approach* de eventos é que você tem que se preocupar com o estado atual da aplicação e definir como chegar no próximo estado. Usando uma analogia péssima, é como se precisássemos programar como chegar ao estado *s*<sub>*n* + 1</sub> em função do estado *s*<sub>*n*</sub>.

Já o Shiny usa um approach chamado *reatividade*. A ideia é evitar que nos preocupemos com o estado da aplicação: descrevemos como *s*<sub>*n*</sub> depende de *n* somente. O estado do aplicativo é definido como uma *função* de determinadas variáveis. Isto é, você definir como a interface deve estar quando as variáveis assumirem seus valores. Toda vez que os valores forem atualizados, o Shiny *reage* e atualiza automaticamente os elementos da interface que dependem dele.

Vários frameworks novos, como o Angular (da Google) e o React (do Facebook) seguem essa ideia, mas ela na verdade é bem antiga. Planilhas do excel são exemplos clássicos de ambientes reativos: você define o valor de uma célula como um cálculo a partir do valor de outras. Toda vez que uma dessas células é atualizada, o valor é recalculado.

Um primeiro exemplo de reatividade
----------------------------------

Vamos produzir uma funcionalidade bem simples: o usuário deve os fornecer uma texto e um número, e a saída produzida deve ser o texto dado repetido n vezes. Para isso, precisamos primeiramente definir objetos de entrada e de saída.

### Objetos de entrada e saída

Os valores resultantes das interações do usuário com o aplicativo entram através de objetos de input. Eles devem ser definidas no arquivo `ui.R` através de funções que tipicamente terminam em *Input* [1]. Precisamos de uma caixa de texto e de uma caixa numérica. O código abaixo faz isso. O parâmetro mais importante é o primeiro: define um id para esses elementos. É através desses ids que conseguiremos recuperar seus valores mais tarde.

``` r
textInput("texto", label = "Texto: ")

numericInput("numero", label = "Número: ", value = 0, min = 0)
```

Precisamos também de um objeto de output para exibir o resultado. Objetos de output também são definidos no `ui.R`, tipicamente por via de funções terminadas em *Output*. No caso, queremos uma saída de texto. Nesse caso simples passamos um único parâmetro, o seu id.

``` r
textOutput("saida")
```

Aplicando isso ao `ui.R`:

``` r
tabItem(tabName = "aba1", 
  fluidRow(
    box(title = "Opções", solidHeader = TRUE,
      textInput("texto", label = "Texto: "),
      numericInput("numero", label = "Número: ", value = 0, min = 0)
    ),
    box(title = "Resultado", status = "primary",
      textOutput("saida")
    )
  )
)
```

Obtemos o seguinte:

![]({{ site.url }}/images/principios/inputs.PNG)

Já podemos brincar com os elementos de entrada, mas nada acontece ainda porque precisamos definir o que a aplicação deve fazer.

### Definindo o comportamento da aplicação

É nesse pedaço que entra o arquivo `server.R`. O código que faz a funcionalidade que queremos é bem simples:

``` r
rep(texto, numero) %>% paste(collapse = " ")
```

Basta então aplicar a lógica do Shiny. Os valores de entrada devem ser acessados através da variável `input` e os de saída, especificados através da variável `output`. Com um detalhe: esse código deve estar dentro de uma função renderizadora correspondente ao tipo de output. Como temos um `textOutput`, precisamos enviar esse código para a função `renderText()` e então atribuir esse valor algum output.

Vejamos como isto fica na prática:

``` r
# global.R

library(shiny)
library(shinydashboard)
library(dplyr)
```

``` r
# server.R

function(input, output, session) {
  output$saida = renderText({
    rep(input$texto, input$numero) %>% paste(collapse = " ")
  })
}
```

Obtemos o seguinte resultado:

![]({{ site.url }}/images/principios/rep.PNG)

Note que, anteriormente, eu havia falado que a ideia da reatividade é definir elementos da interface em *função* do valor das outras. Neste caso, `saida` é uma função dos valores de `input$texto` e `input$numero`. Note que isso não ocorre de maneira explicita: não definimos nenhuma `function` com esses dois parâmetros. Os mecanismos internos do Shiny leem o bloco de código que passamos para a função renderizadora e conseguem detectar quais os *valores reativos* de que esse código depende. Neste caso são apenas dois. Sabendo disso, o Shiny reexecuta o bloco de código toda vez que um dos valores for atualizado.

Um segundo exemplo de reatividade
---------------------------------

O próximo exemplo irá mostrar que descrever interações através da reatividade não é uma tarefa tão trivial.

### Parando reações: isolate()

Teremos inicialmente um input numérico e um botão. Deve ser gerado um gráfico contendo n pontos aleatórios. Esse botão deve gerar um novo plot aleatório toda vez que for clicado.

Começamos definindo os novos elementos gráficos necessários. Precisaremos de uma caixa numérica, um botão e uma saída de plot. O código seguinte para a segunda aba faz isso:

``` r
tabItem(tabName = "aba2", 
  fluidRow(
    box(title = "Parâmetros",
      numericInput("npontos", "Número de pontos:", value = 10, min = 0),
      actionButton("atualizar", "Atualizar")
    ),
    box(title = "Plot",
      plotOutput("plot")
    )
  )        
)
```

O código corresponde no server seria o seguinte:

``` r
output$plot = renderPlot({
  df = data.frame(
    x = rnorm(input$npontos),
    y = rnorm(input$npontos)
  )
  
  ggplot(df, aes(x = x, y = y)) + geom_point() + 
    geom_smooth(method = "lm", se = FALSE)
})
```

O exemplo anterior, do modo como está, tem um pequeno contratempo: Ele gera um gráfico novo toda vez que o valor de npontos mudar. Ocorre que esse talvez não seja o melhor comportamento, pois quando digitamos um número grande, serão gerados alguns plots intermediários com duração efêmera, o que pode, dependendo do tipo de processamento, causar travamentos ou impacto visual desagradável.

Precisamos então colocar o botão de atualizar para funcionar, mas temos uma questão conceitual para pensar primeiro. Num framework reativo, as expressões reativas são recalculadas toda vez que um dos valores reativos muda. Queremos que o plot seja gerado novamente a cada clique no botão, então é claro que o plot depende, de certa forma, do botão. Mas o que seria o *valor* do botão? Claramente, um botão não tem armazena nenhum valor intrinsecamente. A solução implementada pelos engenheiros do Shiny é associar ao botão o número de vezes que ele foi clicado. Dessa forma, toda vez que for clicado, a contagem aumenta e as reações são desencadeadas.

Voltando ao nosso código, basta que adicionemos uma referência a `input$atualizar` em algum momento no interior de `renderPlot()`. No caso, terá de ser uma referência um tanto vazia:

``` r
output$plot = renderPlot({
  input$atualizar
  
  df = data.frame(
    x = rnorm(input$npontos),
    y = rnorm(input$npontos)
  )
  
  ggplot(df, aes(x = x, y = y)) + geom_point() + 
    geom_smooth(method = "lm", se = FALSE) 
})
```

O botão agora funciona, mas ainda precisamos fazer com que o plot pare de atualizar toda vez que o número de pontos for alterado. Ele certamente depende desse número de pontos, porém. E agora?

Esse é um caso de uso típico da função `isolate()`: queremos usar um valor ou expressão reativa, mas não queremos criar uma relação de dependência reativa. Basta colocar o valor ou a expressão reativa dentro de `isolate()`:

``` r
output$plot = renderPlot({
  input$atualizar
  
  npontos = isolate(input$npontos)
  df = data.frame(
    x = rnorm(npontos),
    y = rnorm(npontos)
  )
  
  ggplot(df, aes(x = x, y = y)) + geom_point() + 
    geom_smooth(method = "lm", se = FALSE) 
})
```

### Condutores reativos: reactive()

No caso em que trabalhamos só com um plot, é aceitável gerar esses dados aleatórios dentro do renderPlot(). Suponha que queiramos gerar dois (ou mais) gráficos diferentes a partir da mesma tabela. Não poderíamos mais simplesmente gerar os tabela dentro de um dos renderizadores, pois ela não seria acessível dentro do outro renderizador. Também não faria sentido colocar o código que gera os pontos em cada renderizador, pois seriam gerados *com alta probabilidade* plots diferentes.

Precisamos, então, gerar os pontos *fora* dos renderizadores de algum modo. Tente o seguinte:

``` r
# server.R

function(input, output, session) {
  output$saida = renderText({
    rep(input$texto, input$numero) %>% paste(collapse = " ")
  })
  
  npontos = isolate(input$npontos)
  
  df = data.frame(
    x = rnorm(npontos),
    y = rnorm(npontos)
  )
  
  output$plot = renderPlot({
    input$atualizar

    ggplot(df, aes(x = x, y = y)) + geom_point() + 
      geom_smooth(method = "lm", se = FALSE) 
  })
}
```

Agora o plot não atualiza mais *de jeito nenhum*! Por quê? Porque df não está definido num contexto reativo, ela está no corpo da função do modo usual. Isso implica que aquele trecho de código só será executado uma vez, logo que o server.R é carregado no início. Note que isso independe do uso de `isolate()`.

Para resolver esse tipo de situação (e outras mais) foi pensado o conceito de *condutor reativo*, que se aplica ao que queremos fazer com o `df`. Queremos que ele seja uma função de npontos (e do botão de atualizar) e que, por sua vez, os plots sejam uma função de `df`. A terminologia surge por analogia: `df` estará *conduzindo* reações dos inputs até os outputs.

Ok, como sempre, primeiro temos que definir os plots na ui:

``` r
tabItem(tabName = "aba2", 
  fluidRow(
    box(title = "Parâmetros",
      numericInput("npontos", "Número de pontos:", value = 10, min = 0),
      actionButton("atualizar", "Atualizar")
    ),
    box(title = "Plot",
      plotOutput("plot")
    )
  ),
  fluidRow(
    box(title = "Distribuição do x",
      plotOutput("plotx")    
    ),
    box(title = "Distribuição do y",
      plotOutput("ploty")    
    )
  )
)
```

Para definir condutores reativos, usamos a função `reactive()` com um valor ou expressão dentro. Um detalhe chato é que, para usar os valores definidos deste modo, precisamos suceder o nome com parênteses, do mesmo modo que chamamos funções.

``` r
# server.R

function(input, output, session) {
  output$saida = renderText({
    rep(input$texto, input$numero) %>% paste(collapse = " ")
  })
  
  df = reactive({
    input$atualizar
    npontos = isolate(input$npontos)
    
    data.frame(
      x = rnorm(npontos),
      y = rnorm(npontos)
    )
  })

  output$plot = renderPlot({
    ggplot(df(), aes(x = x, y = y)) + geom_point() + 
      geom_smooth(method = "lm", se = FALSE) 
  })
  
  output$plotx = renderPlot({
    ggplot(df()) + geom_density(mapping = aes(x = x))
  })
  
  output$ploty = renderPlot({
    ggplot(df()) + geom_density(mapping = aes(x = y))
  })
}
```

![]({{ site.url }}/images/principios/densidade.PNG)

### Ações event-like: observe() e observeEvent()

Existem casos de uso que simplesmente não se encaixam de uma forma óbvia no paradigma de reatividade. Casos envolvendo botões são os mais clássicos. Imagine que queremos colocar uma caixa de texto para definir o título do plot. É conveniente um botão para apagar a caixa de texto. A ação de apagar o texto claramente acontece como reação ao aperto de botão, mas ela não gera valor nenhum. Nesse caso, usamos observadores. Eles observam toda vez que os valores reativos no código mudam e, quando isso ocorre, o reexecuta, mas nenhum valor precisa ser gerado.

Primeiro, adicionemos os elementos necessários à UI.

``` r
box(title = "Parâmetros",
  textInput("titulo", "Título do plot: "),
  numericInput("npontos", "Número de pontos:", value = 10, min = 0),
  actionButton("atualizar", "Atualizar"),
  actionButton("limpar", "Limpar")
)
```

Para implementar observadores, podemos usar equivalentemente `observe()` ou `observeEvent()`. A diferença entre as duas é que `observeEvent()` observa apenas um valor reativo, enquanto `observe()` observa todos os valores reativos no seu interior. Utilizamos a função `updateTextInput()` para mudar o valor contido na caixa de texto.

``` r
output$plot = renderPlot({
  ggplot(df(), aes(x = x, y = y)) + geom_point() + 
    geom_smooth(method = "lm", se = FALSE) + 
    ggtitle(input$titulo)
})

observeEvent(input$limpar, {
  updateTextInput(session, "titulo", value = "")
})

# com observe():

# observe({
#   input$limpar
#   updateTextInput(session, "titulo", value = "")
# })
```

[1] Uma lista mais completa de tipos de elementos de input e output disponíveis no Shiny pode ser encontrada [aqui](http://shiny.rstudio.com/reference/shiny/latest/).
