function figura=mostrar_estados_barrido(resultados,caso,figura,indice,total)
% Agrupa dq0 y corrientes de fase reales lado a lado en una sola figura.
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
campos={{'theta'},{'omega'},{'Id','Iq','I0'},{'Ia','Ib','Ic'},{'temperatura'}};
titulos={'Posicion angular del motor','Velocidad angular del motor', ...
    'Corrientes en coordenadas dq0', ...
    sprintf('Corrientes de fase reales | pico registrado = %.4g A',fila.corriente_max_A), ...
    'Temperatura del estator'};
unidades={'\theta_m [rad]','\omega_m [rad/s]','Corriente [A]','Corriente [A]','T_s [°C]'};
etiquetas={{''},{''},{'i_d','i_q','i_0'},{'i_a','i_b','i_c'},{''}};
colores=lines(3);
grupo=fila.grupo{1}; casoIdeal=[grupo '_x0'];
hayActual=isfield(resultados.series,caso); hayIdeal=isfield(resultados.series,casoIdeal);
for k=1:5
    if k==5, ax=nexttile(distribucion,[1 2]); else, ax=nexttile(distribucion); end
    hold(ax,'on'); hayDatos=false;
    for j=1:numel(campos{k})
        campo=campos{k}{j}; nombre=etiquetas{k}{j};
        if fila.factor>0 && hayIdeal && isfield(resultados.series.(casoIdeal),campo)
            s=resultados.series.(casoIdeal).(campo);
            plot(ax,s.Time,s.Data,'--','Color',colores(j,:),'LineWidth',1, ...
                'DisplayName',strtrim([nombre ' ideal']));
        end
        if hayActual && isfield(resultados.series.(caso),campo)
            s=resultados.series.(caso).(campo); hayDatos=true;
            if fila.factor==0, etiqueta='ideal'; else, etiqueta=sprintf('x%g',fila.factor); end
            plot(ax,s.Time,s.Data,'Color',colores(j,:),'LineWidth',1.3, ...
                'DisplayName',strtrim([nombre ' ' etiqueta]));
        end
    end
    if ~hayDatos
        aviso='Sin datos del caso actual';
        if k==4, aviso='Sin trazas abc: repetir el barrido con la version actual'; end
        text(ax,0.5,0.5,aviso,'Units','normalized','HorizontalAlignment','center');
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
    condicion=sprintf('RTD x%g: tau = %g s; demas filtros ideales',fila.factor,fila.parametro);
else
    condicion=sprintf('%s x%g: wn = %g rad/s; demas filtros ideales',grupo,fila.factor,fila.parametro);
end
if ~fila.completo, condicion=[condicion ' | EJECUCION INCOMPLETA']; end
title(distribucion,sprintf('Caso %d/%d | %s',indice,total,condicion),'Interpreter','none');
drawnow;
end
