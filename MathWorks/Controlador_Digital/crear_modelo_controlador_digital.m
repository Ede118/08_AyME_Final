function archivo = crear_modelo_controlador_digital()
% Genera una COPIA del modelo de referencia con el controlador en un bloque.
% No modifica Modelo_Lazo_Cerrado_Discretizado.slx ni sus subsistemas.
carpeta = fileparts(mfilename('fullpath'));
raiz = fileparts(carpeta);
addpath(raiz,carpeta);
p = parametros_controlador_digital();
origen = fullfile(raiz,'Modelo_Lazo_Cerrado_Discretizado.slx');
nombre = 'Modelo_Lazo_Cerrado_MATLAB_Function';
archivo = fullfile(carpeta,[nombre '.slx']);
assert(~bdIsLoaded(nombre),'Cierre %s antes de regenerarlo para proteger cambios en memoria.',nombre);
copyfile(origen,archivo);
load_system(archivo);
limpieza = onCleanup(@() close_system(nombre,0));

% Quitar unicamente PID, observador y modulador de la copia. Los bloques
% fisicos, ZOH, saturaciones, puertos y parametros de simulacion se conservan.
for sid = [355 368 525]
    bloque = Simulink.ID.getFullName([nombre ':' num2str(sid)]);
    puertos = get_param(bloque,'PortHandles');
    for entrada = puertos.Inport
        linea = get_param(entrada,'Line');
        if linea ~= -1
            fuente = get_param(linea,'SrcPortHandle');
            delete_line(nombre,fuente,entrada);
        end
    end
    for salida = puertos.Outport
        linea = get_param(salida,'Line');
        if linea ~= -1, delete_line(linea); end
    end
    delete_block(bloque);
end

b = agregar_bloque_controlador_digital(nombre,'Controlador MATLAB Function',p);
set_param(b,'Position',[270 160 575 470]);
fuentes = [735 736 730 732 733 352 353];
for k=1:numel(fuentes)
    fuente = Simulink.ID.getFullName([nombre ':' num2str(fuentes(k))]);
    if k==4
        convertir=[nombre '/Iabc a vector'];
        add_block('simulink/Signal Attributes/Bus to Vector',convertir,'Position',[165 280 205 310]);
        conectar(nombre,fuente,1,convertir,1);
        conectar(nombre,convertir,1,b,k);
    else
        conectar(nombre,fuente,1,b,k);
    end
end
add_block('simulink/Sources/Constant',[nombre '/Reset controlador'], ...
    'Value','0','Position',[180 420 210 440]);
conectar(nombre,[nombre '/Reset controlador'],1,b,8);

% La salida Vabc original alimenta un Demux del actuador y el puerto 6.
% Se conserva la representacion de bus Vdq0 del puerto 7 mediante un adaptador.
conectar(nombre,b,1,Simulink.ID.getFullName([nombre ':716']),1);
add_block('simulink/Signal Routing/Demux',[nombre '/Separar Vabc'], ...
    'Outputs','3','Position',[645 570 650 645]);
add_block('simulink/Signal Routing/Bus Creator',[nombre '/Bus Vabc codigo'], ...
    'Inputs','3','OutDataTypeStr','Bus: Vabc','NonVirtualBus','on', ...
    'Position',[730 570 735 645]);
conectar(nombre,b,1,[nombre '/Separar Vabc'],1);
for k=1:3
    linea=add_line(nombre,['Separar Vabc/' num2str(k)],['Bus Vabc codigo/' num2str(k)],'autorouting','on');
    etiquetas={'Va','Vb','Vc'};
    set_param(linea,'Name',etiquetas{k});
end
conectar(nombre,[nombre '/Bus Vabc codigo'],1,Simulink.ID.getFullName([nombre ':675']),1);
add_block('simulink/Signal Routing/Demux',[nombre '/Separar Vdq0'], ...
    'Outputs','3','Position',[645 470 650 545]);
add_block('simulink/Signal Routing/Bus Creator',[nombre '/Bus Vdq0 codigo'], ...
    'Inputs','3','OutDataTypeStr','Bus: Vdq0','NonVirtualBus','on','Position',[730 470 735 545]);
conectar(nombre,b,2,[nombre '/Separar Vdq0'],1);
for k=1:3
    linea=add_line(nombre,['Separar Vdq0/' num2str(k)],['Bus Vdq0 codigo/' num2str(k)],'autorouting','on');
    etiquetas={'Vd','Vq','V0'};
    set_param(linea,'Name',etiquetas{k});
end
conectar(nombre,[nombre '/Bus Vdq0 codigo'],1,Simulink.ID.getFullName([nombre ':676']),1);
for k=3:8
    nombreTerm = [nombre '/Diagnostico ' num2str(k)];
    add_block('simulink/Sinks/Terminator',nombreTerm,'Position',[650 160+35*k 670 180+35*k]);
    conectar(nombre,b,k,nombreTerm,1);
end

Simulink.BlockDiagram.arrangeSystem(nombre);
save_system(nombre,archivo);
% El .slx original es un diagrama de SUBSISTEMA, no un modelo simulable.
% Conservar ese tipo permite reemplazar la referencia en el banco existente.
% Para compilar y simularlo tambien se crea un modelo contenedor normal.
banco='Banco_Controlador_MATLAB_Function';
assert(~bdIsLoaded(banco),'Cierre %s antes de regenerarlo.',banco);
new_system(banco);
cerrarBanco=onCleanup(@() close_system(banco,0));
add_block('simulink/Ports & Subsystems/Subsystem Reference',[banco '/Sistema'], ...
    'ReferencedSubsystem',nombre,'Position',[250 90 560 400]);
entradas={'Temperatura ambiente','Id inicial','Torque de carga', ...
    'Referencia posicion motor','Referencia velocidad motor','Resistencia dinamica','Temperatura referencia'};
salidas={'Posicion medida','Corrientes medidas','Temperatura medida','Velocidad motor', ...
    'Torque motor','Orden Vabc','Tensiones Vdq0'};
for k=1:7
    add_block('simulink/Sources/In1',[banco '/' entradas{k}], ...
        'Port',num2str(k),'Position',[50 70+45*k 80 84+45*k]);
    add_block('simulink/Sinks/Out1',[banco '/' salidas{k}], ...
        'Port',num2str(k),'Position',[700 70+45*k 730 84+45*k]);
    add_line(banco,[entradas{k} '/1'],['Sistema/' num2str(k)]);
    add_line(banco,['Sistema/' num2str(k)],[salidas{k} '/1']);
end
set_param(banco,'InitFcn','actualizar_parametros_controlador_digital(bdroot);', ...
    'SolverType','Variable-step','Solver','ode23t','MaxStep','Ts', ...
    'StopTime','0.05','ReturnWorkspaceOutputs','on');
set_param(banco,'SimulationCommand','update');
save_system(banco,fullfile(carpeta,[banco '.slx']));
fprintf('Subsistema generado: %s\nBanco compilado: %s\n',archivo,banco);
end

function conectar(modelo,origen,puertoOrigen,destino,puertoDestino)
phO=get_param(origen,'PortHandles'); phD=get_param(destino,'PortHandles');
add_line(modelo,phO.Outport(puertoOrigen),phD.Inport(puertoDestino),'autorouting','on');
end
