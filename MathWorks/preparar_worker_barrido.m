function preparar_worker_barrido(raiz,codigo,trabajo)
% Inicializa cada trabajador con los mismos parametros y buses del cliente.
% Entradas: carpeta MathWorks, parametros y carpeta temporal. Sin salidas.
setappdata(0,'BarridoDirectorioAnterior',pwd);
setappdata(0,'BarridoFileGenAnterior',Simulink.fileGenControl('getConfig'));
tarea=getCurrentTask();
carpeta=fullfile(trabajo,sprintf('w%d',tarea.ID));
if ~isfolder(carpeta), mkdir(carpeta); end
cd(carpeta);
Simulink.fileGenControl('set','CacheFolder',fullfile(carpeta,'cache'), ...
    'CodeGenFolder',fullfile(carpeta,'codegen'),'createDir',true);
addpath(raiz);
evalin('base',codigo);
end
