function resultados=barrido_filtros_reales_paralelo(opciones)
% Ejecuta el barrido con parsim y conserva el recorrido de graficos con Enter.
% Entrada: opciones del barrido. Salida: tabla, trazas y verificaciones.
if nargin<1, opciones=struct(); end
opciones.UsarParalelo=true;
if ~isfield(opciones,'IncluirSaturacion'), opciones.IncluirSaturacion=true; end
if ~isfield(opciones,'CarpetaResultados')
    opciones.CarpetaResultados=fullfile(fileparts(mfilename('fullpath')), ...
        'Barridos_Reales','resultados_paralelo');
end
resultados=barrido_filtros_reales(opciones);
end
