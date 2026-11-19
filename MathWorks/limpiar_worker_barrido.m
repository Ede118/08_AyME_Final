function limpiar_worker_barrido()
% Restaura directorio y configuracion de archivos de cada trabajador.
% Sin entradas ni salidas; se ejecuta al finalizar el lote de parsim.
if isappdata(0,'BarridoDirectorioAnterior')
    cd(getappdata(0,'BarridoDirectorioAnterior'));
    rmappdata(0,'BarridoDirectorioAnterior');
end
if isappdata(0,'BarridoFileGenAnterior')
    Simulink.fileGenControl('setConfig','config',getappdata(0,'BarridoFileGenAnterior'));
    rmappdata(0,'BarridoFileGenAnterior');
end
end
