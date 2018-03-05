
buscaUI = function(id) {
  ns = NS(id)  
  
  box(title = "Busca", width = NULL,
    textInput(ns("busca"), "Buscar por:")    
  )       
}

busca = function(input, output, session, common) {
  observeEvent(input$busca, {
    if (input$busca == "")
      common$react$lojasBusca = lojas
    
    agregado = paste(lojas$Nome, lojas$Endereco, lojas$Bairro, lojas$Municipio, sep = ",")
    common$react$lojasBusca = lojas[grepl(toupper(input$busca), toupper(agregado))]
  })
}