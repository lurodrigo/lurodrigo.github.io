
infoUI = function(id) {
  ns = NS(id)
  
  box(title = "Info",
    uiOutput(ns("info"))    
  )
}

info = function(input, output, session, common) {
  output$info = renderUI({
    if (is.null(common$react$selecionada))
      return("Vazio.")
    
    loja = lojas[Id == as.integer(common$react$selecionada)]
    p(HTML(glue_data(loja, "{Nome}<br/>{Endereco}")))
  })
}

  