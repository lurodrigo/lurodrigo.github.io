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
  
  output$plotx = renderPlot({
    ggplot(df()) + geom_density(mapping = aes(x = x))
  })
  
  output$ploty = renderPlot({
    ggplot(df()) + geom_density(mapping = aes(x = y))
  })
  
  # aula de hj  
  common = new.env()
  
  common$react = reactiveValues(
    lojasBusca = lojas
  ) 

  callModule(mapa, "mapa", common)
  callModule(busca, "busca", common)
  callModule(info, "info", common)
}

