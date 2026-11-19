function resultados=verificar_barrido_filtros_reales()
% Ejecuta 12 casos cortos: cuatro bases ideales y factores 1/2 de cada grupo.
% Verifica ejecucion, coincidencia de bases y fuentes intactas. No valida el
% desempeno del perfil completo de 16 s ni el equilibrio termico repetitivo.
raiz=fileparts(mfilename('fullpath')); addpath(raiz);
cfg=struct('Perfil','verificacion','TiempoFinal',0.06, ...
    'InstantePerturbacion',0.04,'FactoresFrecuencia',[1 2],'FactoresTau',[1 2], ...
    'TorquePerturbacion',5,'PasoMaximo',2e-4,'LimiteCalculoSegundos',90,'VerGraficos',false, ...
    'CarpetaResultados',fullfile(raiz,'Barridos_Reales','verificacion'));
resultados=barrido_filtros_reales(cfg);
assert(height(resultados.tabla)==12,'Se esperaban doce casos.');
assert(all(resultados.tabla.completo | ~cellfun(@isempty,resultados.tabla.mensaje)), ...
    'Una ejecucion incompleta no tiene diagnostico registrado.');
assert(resultados.fuentes_sin_cambios && resultados.verificacion_ideales.correcta);
tabla=resultados.tabla;
casos={'encoder_x1','RTD_x1','corrientes_x1','inversor_x1'};
metricas={'error_medicion_theta_max_rad','error_medicion_temperatura_max_C', ...
    'error_medicion_corriente_max_A','error_inversor_max_V'};
for k=1:numel(casos)
    fila=tabla(strcmp(tabla.caso,casos{k}),:);
    assert(~fila.completo || fila.(metricas{k})>1e-6,'El filtro no introduce efecto medible.');
end
campos={'theta','omega','Id','Iq','I0','temperatura'};
for caso=fieldnames(resultados.series)'
    assert(all(isfield(resultados.series.(caso{1}),campos)),'Faltan estados para graficar.');
end
fprintf('VERIFICACION_BARRIDO_OK: %d/12 casos completos; los restantes tienen diagnostico. Cuatro bases iguales y fuentes intactas.\n',sum(tabla.completo));
end
