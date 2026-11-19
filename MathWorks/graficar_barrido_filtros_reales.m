function graficar_barrido_filtros_reales(resultados)
% Grafica error de posicion por grupo. Entrada: estructura o ruta a barrido.mat.
% Las trazas estan reducidas para graficar; las metricas usan todas las muestras.
if ischar(resultados) || isstring(resultados)
    datos=load(resultados,'resultados'); resultados=datos.resultados;
end
figure('Name','Barridos de sensores e inversor','Color','w');
tiledlayout(2,2); grupos={'encoder','RTD','corrientes','inversor'};
for g=1:numel(grupos)
    nexttile; hold on; idx=find(strcmp(resultados.tabla.grupo,grupos{g}));
    for k=idx'
        caso=resultados.tabla.caso{k};
        if ~isfield(resultados.series,caso), continue; end
        s=resultados.series.(caso).theta;
        referencia=interp1(resultados.referencia.Time,resultados.referencia.theta,s.Time,'linear','extrap');
        plot(s.Time,s.Data(:)-referencia(:),'DisplayName',strrep(caso,'_',' '),'LineWidth',1.2);
    end
    title(grupos{g}); xlabel('Tiempo [s]'); ylabel('Error posicion motor [rad]');
    grid on; legend('Location','best');
end
end
