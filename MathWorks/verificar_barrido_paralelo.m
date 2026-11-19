function informe=verificar_barrido_paralelo()
% Compara ocho casos cortos en serie y en un pool de procesos.
% Sin entradas. Salida: informe de equivalencia; guarda resultados de ambos.
raiz=fileparts(mfilename('fullpath')); addpath(raiz);
cfg=struct('Perfil','verificacion','TiempoFinal',0.04, ...
    'InstantePerturbacion',0.025,'FactoresFrecuencia',1,'FactoresTau',1, ...
    'VerGraficos',false,'IncluirSaturacion',true,'NumTrabajadores',2, ...
    'CarpetaResultados',fullfile(fileparts(raiz),'Agents','Barridos_Reales','verificacion_serial_parsim'));
serie=barrido_filtros_reales(cfg);
cfg.CarpetaResultados=fullfile(fileparts(raiz),'Agents','Barridos_Reales','verificacion_paralela');
paralelo=barrido_filtros_reales_paralelo(cfg);
assert(height(paralelo.tabla)==8 && isequal(serie.tabla.caso,paralelo.tabla.caso));
assert(isequal(serie.tabla.completo,paralelo.tabla.completo));
assert(serie.fuentes_sin_cambios && paralelo.fuentes_sin_cambios);
campos={'theta','omega','Id','Iq','I0','temperatura'}; diferencia=0;
for caso=fieldnames(serie.series)'
    nombre=caso{1}; assert(isfield(paralelo.series,nombre));
    for k=1:numel(campos)
        a=serie.series.(nombre).(campos{k}); b=paralelo.series.(nombre).(campos{k});
        assert(isequal(size(a.Time),size(b.Time)) && max(abs(a.Time-b.Time))<1e-10);
        escala=max(1,max(abs(a.Data(:))));
        error=max(abs(a.Data(:)-b.Data(:)))/escala;
        assert(error<1e-8,'Las trazas no coinciden en %s/%s.',nombre,campos{k});
        diferencia=max(diferencia,error);
    end
end
assert(numel(fieldnames(serie.series))==numel(fieldnames(paralelo.series)));
limite=paralelo.parametros_base.sat_V;
completos=paralelo.tabla.completo;
assert(all(paralelo.tabla.tension_aplicada_max_V(completos)<=limite+1e-8));
pool=gcp('nocreate');
informe=struct('casos',8,'trabajadores',pool.NumWorkers, ...
    'completos',sum(completos),'diferencia_relativa_maxima',diferencia, ...
    'saturacion_verificada',true,'fuentes_intactas',true);
fid=fopen(fullfile(cfg.CarpetaResultados,'verificacion_paralelo.json'),'w');
assert(fid~=-1); cerrar=onCleanup(@() fclose(fid));
fprintf(fid,'%s',jsonencode(informe,'PrettyPrint',true));
disp(informe); fprintf('PARALELO_EQUIVALENTE_OK\n');
end

