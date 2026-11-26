function cargar_p_control()
% Crea p_control en el workspace base a partir de los coeficientes del proyecto.
carpeta = fileparts(mfilename('fullpath'));
addpath(carpeta, fullfile(carpeta, '..', 'Agents', 'Controlador_Digital'));

% Ts se define al final de la sección de parámetros de coeficientes.m.
if ~evalin('base', "exist('Ts', 'var')")
    codigo = fileread(fullfile(carpeta, 'coeficientes.m'));
    inicioGraficas = regexp(codigo, '(?m)^%\[text\] # Gráficas\s*$', 'once');
    assert(~isempty(inicioGraficas), 'No se encontró la sección Gráficas en coeficientes.m.');
    evalin('base', codigo(1:inicioGraficas-1));
end

modelo = 'Modelo_Lazo_Cerrado_Discretizado';
if ~bdIsLoaded(modelo)
    load_system(fullfile(carpeta, [modelo '.slx']));
    cerrarReferencia = onCleanup(@() close_system(modelo, 0));
end

assignin('base', 'p_control', parametros_controlador_digital());
end
