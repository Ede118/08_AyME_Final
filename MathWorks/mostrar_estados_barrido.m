function figura=mostrar_estados_barrido(resultados,caso,figura,indice,total)
% Muestra los seis estados fisicos y reutiliza una sola figura entre casos.
% Entradas: resultados, nombre del caso, figura previa e indices del barrido.
% Salida: figura actual; compara cada variante con el ideal de su mismo grupo.
if nargin<3, figura=[]; end
if nargin<4, indice=1; total=height(resultados.tabla); end
fila=resultados.tabla(strcmp(resultados.tabla.caso,caso),:);
assert(height(fila)==1,'No se encontro un unico caso %s.',caso);
if isempty(figura)||~isgraphics(figura,'figure')
    figura=figure('Name','Estados del barrido parametrico','NumberTitle','off', ...
        'Color','w','Tag','BarridoEstadosInteractivo','Position',[80 80 1150 820]);
else
    figure(figura); clf(figura);
end
distribucion=tiledlayout(figura,3,2,'TileSpacing','compact','Padding','compact');
campos={'theta','omega','Id','Iq','I0','temperatura'};
titulos={'Posicion angular del motor','Velocidad angular del motor', ...
    'Corriente de eje d','Corriente de eje q','Corriente de eje cero','Temperatura del estator'};
unidades={'\theta_m [rad]','\omega_m [rad/s]','i_d [A]','i_q [A]','i_0 [A]','T_s [°C]'};
grupo=fila.grupo{1}; casoIdeal=[grupo '_x0'];
hayActual=isfield(resultados.series,caso); hayIdeal=isfield(resultados.series,casoIdeal);
for k=1:6
    ax=nexttile(distribucion); hold(ax,'on');
    if fila.factor>0 && hayIdeal && isfield(resultados.series.(casoIdeal),campos{k})
        s=resultados.series.(casoIdeal).(campos{k});
        plot(ax,s.Time,s.Data,'k--','LineWidth',1,'DisplayName','Ideal');
    end
    if hayActual && isfield(resultados.series.(caso),campos{k})
        s=resultados.series.(caso).(campos{k});
        if fila.factor==0, etiqueta='Ideal'; else, etiqueta=sprintf('Factor x%d',fila.factor); end
        plot(ax,s.Time,s.Data,'Color',[0 0.45 0.74],'LineWidth',1.3,'DisplayName',etiqueta);
    else
        text(ax,0.5,0.5,'Sin datos del caso actual','Units','normalized','HorizontalAlignment','center');
    end
    if k<=2
        if k==1, ref=resultados.referencia.theta; else, ref=resultados.referencia.omega; end
        plot(ax,resultados.referencia.Time,ref,':','Color',[0.8 0.2 0.1], ...
            'LineWidth',1,'DisplayName','Referencia');
    end
    title(ax,titulos{k}); ylabel(ax,unidades{k}); xlabel(ax,'Tiempo [s]');
    grid(ax,'on'); legend(ax,'Location','best'); xlim(ax,[0 resultados.configuracion.TiempoFinal]);
end
if fila.factor==0
    condicion='Todos los filtros ideales';
elseif strcmp(grupo,'RTD')
    condicion=sprintf('RTD x%d: tau = %g s; demas filtros ideales',fila.factor,fila.parametro);
else
    condicion=sprintf('%s x%d: wn = %g rad/s; demas filtros ideales',grupo,fila.factor,fila.parametro);
end
if ~fila.completo, condicion=[condicion ' | EJECUCION INCOMPLETA']; end
title(distribucion,sprintf('Caso %d/%d | %s',indice,total,condicion),'Interpreter','none');
drawnow;
end
