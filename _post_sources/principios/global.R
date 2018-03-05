# global.R

library(shiny)
library(shinydashboard)
library(dplyr)
library(ggplot2)
library(leaflet)
library(data.table)
library(glue)

lojas = readRDS("lojas.rds")[!is.na(lat)]

source("mapa.R", encoding = "UTF-8")
source("busca.R", encoding = "UTF-8")
source("info.R", encoding = "UTF-8")