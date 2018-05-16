var tb_idhm = [];
var tb_idh = [];

set_message = function(id) {
    linha = tb_idhm[id-1];
    pais1 = tb_idh[linha.p1-1];
    pais2 = tb_idh[linha.p2-1];
    pais3 = tb_idh[linha.p3-1];
    pais4 = tb_idh[linha.p4-1];

    $('#texto').html(
      `<strong>${linha.Nome}</strong> tem IDH ${linha.IDHM}. <strong>${pais1.Pais}</strong>,
    com ${pais1.IDH}, é o país com IDH mais próximo. Outros países com nível
    de desenvolvimento humano similar são
     <strong>${pais2.Pais}</strong> (${pais2.IDH}), <strong>${pais3.Pais}</strong> (${pais3.IDH}) e <strong>${pais4.Pais}</strong> (${pais4.IDH}).`
    );
}

$(document).ready(function() {
    $('#municipio').selectize({
        options: [],
        labelField: 'label',
        valueField: 'id',
        placeholder: "Escolha uma localização",
        searchField: ['label'],
        onChange: function(value) {
          set_message(value);
        }
    });

    $.getJSON("http://lurodrigo.com/data/tb_idhm_precomp.json", function(data) {
        tb_idhm = data;
        //inicializa opções
        selectize = $('#municipio')[0].selectize;
        selectize.clearOptions();

        for (i = 0; i < tb_idhm.length; i++) {
            selectize.addOption(tb_idhm[i]);
        }

        selectize.refreshOptions();
    });

    $.getJSON("http://lurodrigo.com/data/tb_idh_min.json", function(data) {
      tb_idh = data;
    });
});
