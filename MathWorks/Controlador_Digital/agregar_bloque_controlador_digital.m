function bloque = agregar_bloque_controlador_digital(modelo, nombre, p)
% Inserta el codigo completo como MATLAB Function (sin llamadas extrinsic).
carpeta = fileparts(mfilename('fullpath'));
bloque = [modelo '/' nombre];
add_block('simulink/User-Defined Functions/MATLAB Function',bloque, ...
    'Position',[500 180 790 470]);
chart = find(sfroot,'-isa','Stateflow.EMChart','Path',bloque);
chart.Script = fileread(fullfile(carpeta,'controlador_digital.m'));
parametro = find(chart,'-isa','Stateflow.Data','Name','p_control');
parametro.Scope = 'Parameter';
parametro.Tunable = false;
chart.ChartUpdate = 'DISCRETE';
chart.SampleTime = 'Ts';
for nombreEntrada = {'iabc'}
    dato = find(chart,'-isa','Stateflow.Data','Name',nombreEntrada{1});
    dato.Props.Array.Size = '[3 1]';
end
assignin('base','p_control',p);
end
