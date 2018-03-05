
mapaUI = function(id) {
  ns = NS(id)
  
  box(title = "Mapa", solidHeader = TRUE, width = NULL,
    leafletOutput(ns("map"))
  )
}

mapa = function(input, output, session, common) {
  output$map = renderLeaflet({
    leaflet() %>%
      addTiles() %>%
      addMarkers(lat = lojas$lat, lng = lojas$lng, layerId = as.character(lojas$Id))
  })
  
  observeEvent(input$map_marker_click, {
    common$react$selecionada = input$map_marker_click$id
  })
  
  observeEvent(common$react$lojasBusca, {
    leafletProxy(session$ns("map")) %>%
      clearMarkers() %>%
      addMarkers(lat = common$react$lojasBusca$lat, 
                 lng = common$react$lojasBusca$lng, 
                 layerId = as.character(common$react$lojasBusca$Id))
  })
}