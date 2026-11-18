function p = inicializar_controlador_digital()
% Carga SOLO parametros anteriores a "# Graficas" de coeficientes.m.
% Ejecutar de nuevo si se desea restaurar la configuracion del archivo.
carpeta = fileparts(mfilename('fullpath'));
raiz = fileparts(carpeta);
addpath(raiz, carpeta);
codigo = fileread(fullfile(raiz,'coeficientes.m'));
limite = strfind(codigo,'%[text] # Gráficas');
assert(~isempty(limite),'No se encontro el limite de la seccion de parametros.');
evalin('base', codigo(1:limite(1)-1));
p = parametros_controlador_digital();
assignin('base','p_control',p);
end
