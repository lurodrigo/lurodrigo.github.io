---
title: "Compara IDH"
layout: single
excerpt: "Escolha um bairro e eu te digo os países com desenvolvimento humano similar."
sitemap: false
permalink: /compara_idh/
script: |
    <script src="/assets/js/selectize.min.js" type="text/javascript"></script>
    <script type="text/javascript" src="/assets/js/idh.js"></script>
---

<link rel="stylesheet" type="text/css" href="{{site.url}}/assets/css/selectize.default.css">

<style>
  #municipio {
    width: 700px;
  }
</style>
	
<p><select id="municipio"></select></p>
<p id="texto"></p>

Observações: Os dados de IDH dos bairros foram obtidos [aqui][1]; os dos países, [aqui][2]. Só tenho dados de IDH de bairros (às vezes agregações maiores) de algumas regiões metropolitanas. Os dados são de 2010. A comparação entre bairros e países pode não ser muito justa (considere que países são muito mais heterogêneos que bairros). Leve isso na esportiva.

[1]: http://www.atlasbrasil.org.br/2013/pt/download/
[2]: http://hdr.undp.org/en/data
