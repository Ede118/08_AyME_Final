function resultados = validar_controlador_digital()
% Compara el codigo contra los TRES subsistemas reales de la referencia.
% Banco sin planta: ambos controladores reciben exactamente las mismas muestras.
% Incluye posicion inicial no nula, secuencia cero, cambios de referencia,
% temperatura variable, resistencia fija/dinamica y estados de Tustin.
carpeta=fileparts(mfilename('fullpath')); raiz=fileparts(carpeta);
addpath(raiz,carpeta);
p=parametros_controlador_digital();
ref='Modelo_Lazo_Cerrado_Discretizado'; load_system(fullfile(raiz,[ref '.slx']));
h='Validacion_Controlador_Digital';
assert(~bdIsLoaded(h),'Cierre el banco de validacion antes de ejecutarlo.');
new_system(h); limpieza=onCleanup(@() close_system(h,0));
set_param(h,'SolverType','Fixed-step','Solver','FixedStepDiscrete', ...
    'FixedStep',num2str(p.Ts,17),'StopTime',num2str(2000*p.Ts,17), ...
    'ReturnWorkspaceOutputs','on');
entradaSimulacion=Simulink.SimulationInput(h);
t=(0:2000)'*p.Ts;
escala=t/t(end);
valores={0.21+0.04*sin(2*pi*escala), ...
         0.3*cos(2*pi*escala), ...
         0.2+0.05*sin(3*pi*escala)+0.01*(escala>=0.45), ...
         [0.4*sin(5*pi*escala)+0.1, 0.3*cos(4*pi*escala)-0.05, -0.2*sin(7*pi*escala)+0.07], ...
         20+60*escala, ...
         double(escala>=0.3 & escala<0.75), ...
         40+5*sin(pi*escala)};
for k=1:7
    variable=['ayme_valid_u' num2str(k)];
    entradaSimulacion=entradaSimulacion.setVariable(variable,[t valores{k}]);
    add_block('simulink/Sources/From Workspace',[h '/U' num2str(k)], ...
        'VariableName',variable,'Interpolate','off','OutputAfterFinalValue','Holding final value', ...
        'SampleTime',num2str(p.Ts,17));
end
add_block('simulink/Sources/Constant',[h '/Reset'],'Value','0');
codigo=agregar_bloque_controlador_digital(h,'Codigo',p); %#ok<NASGU>
for k=1:7, unir(h,['U' num2str(k) '/1'],['Codigo/' num2str(k)]); end
unir(h,'Reset/1','Codigo/8');

add_block([ref '/PID Movimiento'],[h '/PID']);
add_block([ref '/Estimador de Estado Reducido'],[h '/Observador']);
add_block([ref '/Modulador de Torque Equivalente'],[h '/Modulador']);
% Las ganancias copiadas se resuelven contra los mismos parametros del base.
add_block('simulink/Signal Routing/Demux',[h '/Separar Iabc'],'Outputs','3');
add_block('simulink/Signal Routing/Bus Creator',[h '/Bus Iabc'],'Inputs','3');
unir(h,'U4/1','Separar Iabc/1');
etiquetas={'Ia','Ib','Ic'};
for k=1:3
    linea=unir(h,['Separar Iabc/' num2str(k)],['Bus Iabc/' num2str(k)]);
    set_param(linea,'Name',etiquetas{k});
end
unir(h,'U1/1','PID/3'); unir(h,'U2/1','PID/4'); unir(h,'U3/1','PID/2');
unir(h,'Observador/1','PID/1'); unir(h,'PID/1','Observador/1'); unir(h,'U3/1','Observador/2');
unir(h,'U5/1','Modulador/1'); unir(h,'Observador/1','Modulador/2');
unir(h,'Bus Iabc/1','Modulador/3'); unir(h,'U3/1','Modulador/4');
unir(h,'PID/1','Modulador/5'); unir(h,'U6/1','Modulador/6'); unir(h,'U7/1','Modulador/7');
for k=1:2
    nombre=['Vector ref ' num2str(k)];
    add_block('simulink/Signal Attributes/Bus to Vector',[h '/' nombre]);
    unir(h,['Modulador/' num2str(k)],[nombre '/1']);
end
salidas={'vabc','vdq0','torque','omega','theta'};
refPuertos={'Vector ref 1/1','Vector ref 2/1','PID/1','Observador/1','Observador/2'};
for k=1:numel(salidas)
    guardar(h,['Codigo/' num2str(k)],['codigo_' salidas{k}]);
    guardar(h,refPuertos{k},['ref_' salidas{k}]);
end
for k=6:8
    add_block('simulink/Sinks/Terminator',[h '/Fin' num2str(k)]);
    unir(h,['Codigo/' num2str(k)],['Fin' num2str(k) '/1']);
end
salida=sim(entradaSimulacion);
resultados=struct('Ts',p.Ts,'numero_muestras',numel(t),'comparaciones',struct());
for k=1:numel(salidas)
    nombre=salidas{k};
    a=salida.get(['codigo_' nombre]); b=salida.get(['ref_' nombre]);
    assert(isequal(a.Time,b.Time),'Los tiempos de comparacion deben coincidir.');
    va=reshape(a.Data,[],numel(t))'; vb=reshape(b.Data,[],numel(t))';
    % Timeseries puede almacenar vectores como N x 3 o 3 x 1 x N.
    if size(a.Data,1)==numel(t), va=reshape(a.Data,numel(t),[]); end
    if size(b.Data,1)==numel(t), vb=reshape(b.Data,numel(t),[]); end
    error=abs(va-vb);
    maximo=max(error,[],'all'); relativo=max(error./(1+abs(vb)),[],'all');
    resultados.comparaciones.(nombre)=struct('maximo_absoluto',maximo,'maximo_escalado',relativo);
    fprintf('%s: max absoluto %.6g; escalado %.6g\n',nombre,maximo,relativo);
    assert(all(isfinite(va),'all') && relativo<1e-6,'No hay equivalencia en %s.',nombre);
end

% Verifica tambien la ejecucion como funcion MATLAB y el reinicio de memorias.
clear controlador_digital
directo=zeros(numel(t),3);
for k=1:numel(t)
    directo(k,:)=controlador_digital(valores{1}(k),valores{2}(k),valores{3}(k), ...
        valores{4}(k,:)',valores{5}(k),valores{6}(k),valores{7}(k),0,p)';
end
v=salida.get('codigo_vabc'); v=reshape(v.Data,[],numel(t))';
if size(salida.get('codigo_vabc').Data,1)==numel(t)
    serie=salida.get('codigo_vabc'); v=reshape(serie.Data,numel(t),[]);
end
resultados.error_funcion_vs_bloque=max(abs(directo-v),[],'all');
assert(resultados.error_funcion_vs_bloque<1e-8,'La funcion MATLAB difiere del bloque.');
reinicio=controlador_digital(valores{1}(1),valores{2}(1),valores{3}(1), ...
    valores{4}(1,:)',valores{5}(1),valores{6}(1),valores{7}(1),1,p);
assert(max(abs(reinicio-directo(1,:)'))<1e-10,'El reset no restaura la primera muestra.');
resultados.reset_correcto=true;
resultados.parametros=p;
% Prueba breve de ejecucion con la planta, sensores e inversor conservados.
% No sustituye los ensayos largos ni la comprobacion de limites del proyecto.
banco='Banco_Controlador_MATLAB_Function';
load_system(fullfile(carpeta,[banco '.slx']));
cerrarBanco=onCleanup(@() close_system(banco,0));
tFisico=(0:500)'*p.Ts;
frecuencia=2*pi/(2000*p.Ts);
posicion=0.001*(1-cos(frecuencia*tFisico));
velocidad=0.001*frecuencia*sin(frecuencia*tFisico);
externas=[tFisico,20*ones(size(tFisico)),zeros(numel(tFisico),2), ...
    posicion,velocidad,ones(size(tFisico)),40*ones(size(tFisico))];
fisica=Simulink.SimulationInput(banco);
fisica=fisica.setExternalInput(externas);
fisica=fisica.setModelParameter('StopTime',num2str(tFisico(end),17), ...
    'SaveOutput','on','OutputSaveName','yout','SaveFormat','Dataset');
simFisica=sim(fisica);
resultados.integracion=struct('tiempo_final',simFisica.tout(end), ...
    'numero_puntos_solver',numel(simFisica.tout));
assert(abs(simFisica.tout(end)-tFisico(end))<1e-12,'La simulacion integrada no termino.');
for k=1:simFisica.yout.numElements
    valoresSalida=simFisica.yout.getElement(k).Values;
    comprobar_finito(valoresSalida);
end
resultados.integracion.salidas_finitas=true;
destino=fullfile(carpeta,'resultados'); if ~isfolder(destino), mkdir(destino); end
save(fullfile(destino,'validacion_controlador_digital.mat'),'resultados');
fid=fopen(fullfile(destino,'validacion_controlador_digital.json'),'w');
cerrar=onCleanup(@() fclose(fid));
fprintf(fid,'%s',jsonencode(resultados,'PrettyPrint',true));
fprintf('VALIDACION_CONTROLADOR_OK\n');
end

function comprobar_finito(valor)
if isa(valor,'timeseries')
    assert(all(isfinite(valor.Data),'all'),'Salida fisica no finita.');
elseif isstruct(valor)
    campos=fieldnames(valor);
    for k=1:numel(campos), comprobar_finito(valor.(campos{k})); end
else
    error('Tipo de salida no previsto en la validacion fisica.');
end
end

function linea=unir(modelo,origen,destino)
linea=add_line(modelo,origen,destino,'autorouting','on');
end

function guardar(modelo,origen,nombre)
add_block('simulink/Sinks/To Workspace',[modelo '/' nombre], ...
    'VariableName',nombre,'SaveFormat','Timeseries');
unir(modelo,origen,[nombre '/1']);
end
