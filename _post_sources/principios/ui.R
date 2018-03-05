# ui.R

dashboardPage(
  dashboardHeader(title = "Appzinho"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Aba 1", tabName = "aba1", icon = icon("star")),
      menuItem("Aba 2", tabName = "aba2", icon = icon("tag")),
      menuItem("Aba 3", tabName = "aba3", icon = icon("map"))
    )
  ),
  dashboardBody(
    tabItems(
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
      ),
      tabItem(tabName = "aba2", 
        fluidRow(
          box(title = "Parâmetros",
            textInput("titulo", "Título do plot: "),
            numericInput("npontos", "Número de pontos:", value = 10, min = 0),
            actionButton("atualizar", "Atualizar"),
            actionButton("limpar", "Limpar")
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
      ),
      tabItem(tabName = "aba3", 
        fluidRow(
          column(width = 9,
            mapaUI("mapa")
          ),
          column(width = 3,
            buscaUI("busca")
          )
        ), 
        fluidRow(
          column(width = 9,
            infoUI("info")
          )
        )
      )
    )
  )
)