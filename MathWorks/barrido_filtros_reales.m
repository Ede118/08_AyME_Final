function resultados = barrido_filtros_reales(opciones)
% Barre encoder, RTD, corrientes e inversor, un grupo no ideal por vez.
% Entrada: estructura opcional de configuracion (ver configuracion_defecto).
% Salida: tabla, trazas, configuracion y parametros; tambien guarda MAT/CSV/JSON.
% No guarda cambios en los SLX ni modifica coeficientes.m.
if nargin<1, opciones=struct(); end
raiz=fileparts(mfilename('fullpath')); addpath(raiz);
cfg=configuracion_defecto(raiz,opciones);
cfg.VerGraficos=seleccionar_graficos(cfg.VerGraficos);
fuente='Simulaciones_Actuadores_Reales'; sensores='Sensores_Reales'; banco='Banco_Barrido_Filtros_Reales';
assert(~bdIsLoaded(fuente) && ~bdIsLoaded(sensores) && ~bdIsLoaded(banco), ...
    'Guarde y cierre Simulaciones_Actuadores_Reales, Sensores_Reales y el banco antes de ejecutar.');
archivos={fullfile(raiz,[fuente '.slx']),fullfile(raiz,[sensores '.slx']),fullfile(raiz,'coeficientes.m')};
hashes=cellfun(@hash_archivo,archivos,'UniformOutput',false);
codigo=fileread(archivos{3}); corte=strfind(codigo,'%[text] # Gráficas');
assert(~isempty(corte),'No se encontro el fin de parametros en coeficientes.m.');
evalin('base',codigo(1:corte(1)-1));
origenConsigna='perfil corto de verificacion';
if strcmp(cfg.Perfil,'modelo'), origenConsigna=asegurar_consigna(raiz); end
variables={'wn_E','zeta_E','wn_I','zeta_I','wn_V','zeta_V','tau_RTD','T_ld', ...
    'T_amb','init_theta','init_w','init_Ts','r','sat_V','m_l','b_eq', ...
    'J_eq','Kp_mov','Ki_mov','Kd_mov','K_et','K_ew','Pp','I_sMAX','T_sMAX'};
base=struct();
for k=1:numel(variables), base.(variables{k})=evalin('base',variables{k}); end
anteriorGen=Simulink.fileGenControl('getConfig');
% Ruta corta: los filtros de biblioteca generan archivos sujetos al limite de Windows.
carpetaTemporal=fullfile(fileparts(raiz),'Agents','bt');
if ~isfolder(carpetaTemporal), mkdir(carpetaTemporal); end
trabajo=tempname(carpetaTemporal); mkdir(trabajo);
Simulink.fileGenControl('set','CacheFolder',fullfile(trabajo,'cache'), ...
    'CodeGenFolder',fullfile(trabajo,'codegen'),'createDir',true);
limpieza=onCleanup(@() cerrar_banco(banco,fuente,sensores,anteriorGen));
load_system(archivos{1}); new_system(banco);
add_block([fuente '/Real1'],[banco '/Sistema']);
core=[banco '/Sistema'];
correcciones=normalizar_cableado(core);
fprintf('Banco temporal: copia de %s/Real1. Conexiones corregidas: %d.\n',fuente,correcciones);
fprintf('Bases: encoder=%g, corrientes=%g, inversor=%g rad/s; tau_RTD=%g s.\n', ...
    base.wn_E,base.wn_I,base.wn_V,base.tau_RTD);
set_param(banco,'SolverType','Variable-step','Solver','ode15s', ...
    'ZeroCrossAlgorithm','Adaptive', ...
    'RelTol',num2str(cfg.RelTol),'AbsTol',num2str(cfg.AbsTol), ...
    'MaxStep',num2str(cfg.PasoMaximo),'StopTime',num2str(cfg.TiempoFinal), ...
    'ReturnWorkspaceOutputs','on','SaveOutput','off');
[tiempo,thetaRef,omegaRef]=preparar_entradas(banco,fuente,cfg,base);
sensor=[core '/Subsystem Reference'];
encoder=[sensor '/Encoder- LP 2nd'];
rtd=[sensor '/Sensor RTD - LP 1nd'];
corriente=cellfun(@(f)[sensor '/Sensor ' f ' - LP 2nd'],{'Ia','Ib','Ic'},'UniformOutput',false);
inversor=cellfun(@(f)[core '/Inverter ' f ' - LP 2nd'],{'Va','Vb','Vc'},'UniformOutput',false);
todos=[{encoder,rtd},corriente,inversor];
for k=1:numel(todos)
    parametros=get_param(todos{k},'DialogParameters');
    if isfield(parametros,'Ts'), set_param(todos{k},'Ts','0','init_option','Inherited from block input'); end
end
for nombre={'Saturation','Saturation1','Saturation2'}
    if cfg.IncluirSaturacion, estado='off'; else, estado='through'; end
    set_param([core '/' nombre{1}],'Commented',estado);
end
% Medir estados fisicos y mediciones por separado, evitando confundirlos.
planta=[core '/Planta (Modelo Global No Lineal)']; sensor=[core '/Subsystem Reference'];
registrar(planta,1,'theta'); registrar(planta,4,'omega');
registrar(planta,3,'temperatura'); registrar(planta,5,'torque');
registrar(sensor,puerto_sensor(sensor,'posicion'),'theta_medida');
registrar(sensor,puerto_sensor(sensor,'temperatura'),'temperatura_medida');
registrar([core '/Estimador de Estado Reducido'],1,'omega_estimada');
registrar_bus(planta,2,'corrientes',{'Ia','Ib','Ic'});
registrar_bus([planta '/Subsistema Electromagnetico'],1,'corrientes_dq0',{'Id','Iq','I0'});
registrar_bus(sensor,2,'corrientes_medidas',{'Ia','Ib','Ic'});
registrar_bus([core '/Modulador de Torque Equivalente'],1,'tensiones_orden',{'Va','Vb','Vc'});
busAplicado=find_system(core,'SearchDepth',1,'BlockType','BusCreator');
assert(numel(busAplicado)==1,'No se identifico el bus de tension aplicado a planta.');
puertosBus=get_param(busAplicado{1},'PortHandles'); nombresFase={'Va','Vb','Vc'};
% Mantener nombres de fase incluso cuando el bypass elimina filtros en compilacion.
for k=1:3
    entrada=puertosBus.Inport(k); linea=get_param(entrada,'Line'); origen=get_param(linea,'SrcPortHandle');
    delete_line(core,origen,entrada);
    adaptador=[core '/Fase_' nombresFase{k}];
    add_block('simulink/Math Operations/Gain',adaptador,'Gain','1');
    puertos=get_param(adaptador,'PortHandles');
    add_line(core,origen,puertos.Inport(1));
    linea=add_line(core,puertos.Outport(1),entrada); set_param(linea,'Name',nombresFase{k});
end
registrar(busAplicado{1},1,'tensiones_aplicadas');
grupos={'encoder','RTD','corrientes','inversor'};
filas=struct([]); series=struct(); id=0;
figura=[];
numeroCasos=3*(1+numel(cfg.FactoresFrecuencia))+1+numel(cfg.FactoresTau);
[entradas,casos]=crear_casos(banco,cfg,base,encoder,rtd,corriente,inversor,todos);
if cfg.UsarParalelo
    assert(license('test','Distrib_Computing_Toolbox'), ...
        'Se requiere Parallel Computing Toolbox para UsarParalelo=true.');
    pool=gcp('nocreate');
    if isempty(pool), pool=parpool('Processes',cfg.NumTrabajadores); end
    assert(isa(pool,'parallel.ProcessPool'),'Usar un pool de procesos, no de threads.');
    save_system(banco,fullfile(trabajo,[banco '.slx']));
    fprintf('Ejecutando %d casos con %d trabajadores. Los graficos se recorren al terminar el lote.\n',numeroCasos,pool.NumWorkers);
    salidas=parsim(entradas,'ShowProgress','on','ShowSimulationManager','off', ...
        'UseFastRestart','off','TransferBaseWorkspaceVariables','off', ...
        'ManageDependencies','on', ...
        'SetupFcn',@() preparar_worker_barrido(raiz,codigo(1:corte(1)-1),trabajo), ...
        'CleanupFcn',@limpiar_worker_barrido);
end
for g=1:numel(grupos)
    grupo=grupos{g};
    if strcmp(grupo,'RTD'), factores=cfg.FactoresTau; else, factores=cfg.FactoresFrecuencia; end
    for factor=[0 factores]
        id=id+1;
        sufijo=strrep(strrep(strrep(sprintf('%.17g',factor),'.','p'),'-','m'),'+','p');
        etiqueta=[grupo '_x' sufijo];
        parametro=casos(id).parametro; A1=casos(id).A1; A2=casos(id).A2;
        fila=struct('caso',etiqueta,'grupo',grupo,'factor',factor,'parametro',parametro, ...
            'A1',A1,'A2',A2,'ideal',factor==0,'completo',false,'tiempo_final',NaN, ...
            'error_max_rad',NaN,'error_final_rad',NaN,'omega_max_rad_s',NaN, ...
            'corriente_max_A',NaN,'tension_orden_max_V',NaN,'tension_aplicada_max_V',NaN, ...
            'temperatura_max_C',NaN,'error_medicion_theta_max_rad',NaN, ...
            'error_medicion_temperatura_max_C',NaN,'mensaje','');
        fila.error_medicion_corriente_max_A=NaN;
        fila.error_inversor_max_V=NaN;
        fprintf('\n[%d] %s: parametro=%g, A1=%g, A2=%g\n',id,etiqueta,parametro,A1,A2);
        reloj=tic;
        try
            if cfg.UsarParalelo
                out=salidas(id);
            else
                out=sim(entradas(id));
            end
            if ~any(strcmp(out.who,'tout')) && ~isempty(out.ErrorMessage)
                error('Barrido:Simulacion','%s',out.ErrorMessage);
            end
            fila.tiempo_final=out.tout(end);
            x=out.theta; ref=interp1(tiempo,thetaRef,x.Time,'linear','extrap');
            fila.error_max_rad=max(abs(x.Data(:)-ref(:)));
            fila.error_final_rad=x.Data(end)-ref(end);
            fila.omega_max_rad_s=max(abs(out.omega.Data(:)));
            fila.temperatura_max_C=max(out.temperatura.Data(:));
            fila.corriente_max_A=max_bus(out.corrientes);
            fila.tension_orden_max_V=max_bus(out.tensiones_orden);
            fila.tension_aplicada_max_V=max_bus(out.tensiones_aplicadas);
            fila.error_medicion_theta_max_rad=error_senales(out.theta,out.theta_medida);
            fila.error_medicion_temperatura_max_C=error_senales(out.temperatura,out.temperatura_medida);
            fila.error_medicion_corriente_max_A=error_buses(out.corrientes,out.corrientes_medidas);
            fila.error_inversor_max_V=error_buses(out.tensiones_orden,out.tensiones_aplicadas);
            fila.completo=abs(fila.tiempo_final-cfg.TiempoFinal)<1e-9 && all(isfinite(x.Data(:)));
            if ~fila.completo, fila.mensaje='Ejecucion incompleta; revisar TimeOut o diagnosticos del solver.'; end
            if ~isempty(out.ErrorMessage)
                fila.completo=false; fila.mensaje=out.ErrorMessage;
            end
            campos={'theta','omega','temperatura','torque','theta_medida','temperatura_medida','omega_estimada'};
            trazas=struct();
            for j=1:numel(campos)
                s=out.get(campos{j}); indices=unique(round(linspace(1,numel(s.Time),min(cfg.MaxPuntosTraza,numel(s.Time)))));
                trazas.(campos{j})=struct('Time',s.Time(indices),'Data',s.Data(indices));
            end
            dq=out.corrientes_dq0;
            nombresDQ={'Id','Iq','I0'}; camposDQ=fieldnames(dq);
            assert(numel(camposDQ)==3,'Se esperaban tres estados de corriente dq0.');
            for kDQ=1:3
                campo=nombresDQ{kDQ};
                if isfield(dq,campo), s=dq.(campo); else, s=dq.(camposDQ{kDQ}); end
                indices=unique(round(linspace(1,numel(s.Time),min(cfg.MaxPuntosTraza,numel(s.Time)))));
                trazas.(campo)=struct('Time',s.Time(indices),'Data',s.Data(indices));
            end
            abc=out.corrientes; nombresABC={'Ia','Ib','Ic'};
            for kABC=1:3
                campo=nombresABC{kABC}; s=abc.(campo);
                indices=unique(round(linspace(1,numel(s.Time),min(cfg.MaxPuntosTraza,numel(s.Time)))));
                trazas.(campo)=struct('Time',s.Time(indices),'Data',s.Data(indices));
            end
            series.(etiqueta)=trazas;
            fprintf('t=%g s; error max=%g rad; Imax=%g A; completo=%d\n', ...
                fila.tiempo_final,fila.error_max_rad,fila.corriente_max_A,fila.completo);
            if ~fila.completo, fprintf('Diagnostico: %s\n',fila.mensaje); end
        catch ME
            fila.mensaje=getReport(ME,'basic','hyperlinks','off');
            fprintf('FALLO registrado (el barrido continua): %s\n',ME.message);
        end
        fila.segundos_calculo=toc(reloj);
        if cfg.UsarParalelo
            fila.segundos_calculo=salidas(id).SimulationMetadata.TimingInfo.TotalElapsedWallTime;
        end
        filas=[filas;fila]; %#ok<AGROW>
        resultados=struct('tabla',struct2table(filas,'AsArray',true),'series',series,'configuracion',cfg, ...
            'parametros_base',base,'correcciones_cableado_en_copia',correcciones, ...
            'referencia',struct('Time',tiempo,'theta',thetaRef,'omega',omegaRef,'origen',origenConsigna));
        guardar_resultados(resultados,cfg.CarpetaResultados);
        if cfg.VerGraficos
            figura=mostrar_estados_barrido(resultados,etiqueta,figura,id,numeroCasos);
            if cfg.PausarGraficos && id<numeroCasos
                input(sprintf('\nCaso %d/%d mostrado. Pulse ENTER para ver el siguiente caso: ',id,numeroCasos),'s');
            end
        end
    end
end
% Las cuatro bases ideales deben coincidir, no solo finalizar sin error.
resultados.verificacion_ideales=verificar_ideales(series,filas,cfg);
resultados.fuentes_sin_cambios=true;
for k=1:numel(archivos)
    assert(strcmp(hashes{k},hash_archivo(archivos{k})),'Cambio inesperado en %s.',archivos{k});
end
guardar_resultados(resultados,cfg.CarpetaResultados);
disp(resultados.tabla(:,{'caso','parametro','completo','tiempo_final', ...
    'corriente_max_A','tension_aplicada_max_V'}));
fprintf('\nBARRIDO_TERMINADO. Resultados: %s\n',cfg.CarpetaResultados);
end

function cfg=configuracion_defecto(raiz,opciones)
cfg=struct('Perfil','modelo','TiempoFinal',16,'FactoresFrecuencia',1:5, ...
    'FactoresTau',1:5,'EscalaRTD','tau','IncluirSaturacion',true, ...
    'TorquePerturbacion',NaN,'InstantePerturbacion',8,'ResistenciaDinamica',true, ...
    'PasoMaximo',1e-3,'RelTol',1e-5,'AbsTol',1e-7,'LimiteCalculoSegundos',120, ...
    'MaxPuntosTraza',4000,'VerGraficos','preguntar','PausarGraficos',true, ...
    'UsarParalelo',false,'NumTrabajadores',2, ...
    'CarpetaResultados',fullfile(fileparts(raiz),'Agents','Barridos_Reales','resultados'));
nombres=fieldnames(opciones);
for k=1:numel(nombres)
    assert(isfield(cfg,nombres{k}),'Opcion desconocida: %s.',nombres{k});
    cfg.(nombres{k})=opciones.(nombres{k});
end
validatestring(cfg.Perfil,{'modelo','verificacion'}); validatestring(cfg.EscalaRTD,{'tau','frecuencia'});
validateattributes(cfg.TiempoFinal,{'double'},{'scalar','positive','finite'});
validateattributes(cfg.NumTrabajadores,{'double'},{'scalar','integer','positive','finite'});
for valores={cfg.FactoresFrecuencia,cfg.FactoresTau}
    validateattributes(valores{1},{'double'},{'vector','real','positive','finite','nonempty'});
    assert(numel(unique(valores{1}))==numel(valores{1}),'No repetir factores.');
end
cfg.FactoresFrecuencia=cfg.FactoresFrecuencia(:).';
cfg.FactoresTau=cfg.FactoresTau(:).';
assert(cfg.InstantePerturbacion>0 && cfg.InstantePerturbacion<cfg.TiempoFinal, ...
    'La perturbacion debe ocurrir dentro del horizonte simulado.');
if ~isfolder(cfg.CarpetaResultados), mkdir(cfg.CarpetaResultados); end
assert(~contains(cfg.CarpetaResultados,'#'),'Usar una carpeta sin # para el codigo generado.');
end

function mostrar=seleccionar_graficos(opcion)
if islogical(opcion) && isscalar(opcion), mostrar=opcion; return; end
assert((ischar(opcion)||isstring(opcion)) && strcmpi(opcion,'preguntar'), ...
    'VerGraficos debe ser true, false o ''preguntar''.');
while true
    respuesta=upper(strtrim(input('¿Ver los graficos de las seis variables de estado? [S/N]: ','s')));
    if strcmp(respuesta,'S'), mostrar=true; return; end
    if strcmp(respuesta,'N'), mostrar=false; return; end
    fprintf('Escriba S para verlos o N para ejecutar sin graficos.\n');
end
end

function [t,theta,omega]=preparar_entradas(banco,fuente,cfg,base)
if strcmp(cfg.Perfil,'modelo')
    t=(0:0.001:cfg.TiempoFinal)';
    bloques=find_system(fuente,'SearchDepth',1,'BlockType','Lookup_n-D');
    assert(numel(bloques)==2,'Se esperaban los dos perfiles de referencia del modelo.');
    posicion=Simulink.ID.getFullName([fuente ':1']); velocidad=Simulink.ID.getFullName([fuente ':2']);
    tp=slResolve(get_param(posicion,'BreakpointsForDimension1'),posicion); qp=slResolve(get_param(posicion,'Table'),posicion);
    tv=slResolve(get_param(velocidad,'BreakpointsForDimension1'),velocidad); qv=slResolve(get_param(velocidad,'Table'),velocidad);
    validar_tabla(tp,qp); validar_tabla(tv,qv);
    assert(cfg.TiempoFinal<=min(tp(end),tv(end)), 'La consigna no cubre TiempoFinal.');
    t=unique([t;tp(:);tv(:)]); t=t(t>=0 & t<=cfg.TiempoFinal);
    theta=base.r*interp1(tp,qp,t,'linear','extrap'); omega=base.r*interp1(tv,qv,t,'linear','extrap');
else
    t=(0:0.0001:cfg.TiempoFinal)'; fase=min(max((t-0.005)/0.025,0),1);
    theta=base.r*0.001*(1-cos(pi*fase))/2;
    omega=base.r*0.001*pi/(2*0.025)*sin(pi*fase); omega(t<=0.005|t>=0.03)=0;
end
% Fuentes locales constantes y From Workspace con datos almacenados en el banco.
ws=get_param(banco,'ModelWorkspace');
for k=1:2
    nombre=sprintf('ref%d',k); if k==1, datos=[t theta]; else, datos=[t omega]; end
    assignin(ws,nombre,datos);
    add_block('simulink/Sources/From Workspace',[banco '/' nombre], ...
        'VariableName',nombre,'Interpolate','on','OutputAfterFinalValue','Holding final value');
    add_line(banco,[nombre '/1'],['Sistema/' num2str(k)]);
end
amplitud=cfg.TorquePerturbacion; if isnan(amplitud), amplitud=base.T_ld; end
add_block('simulink/Sources/Step',[banco '/Perturbacion torque'], ...
    'Time',num2str(cfg.InstantePerturbacion,17),'Before','0','After',num2str(amplitud,17));
add_line(banco,'Perturbacion torque/1','Sistema/3');
valores=[base.T_amb,0,double(cfg.ResistenciaDinamica),20];
for k=1:4
    nombre=sprintf('constante%d',k); add_block('simulink/Sources/Constant',[banco '/' nombre],'Value',num2str(valores(k),17));
    add_line(banco,[nombre '/1'],['Sistema/' num2str(k+3)]);
end
end

function origen=asegurar_consigna(raiz)
% Usa los puntos del usuario; si faltan todos, genera el perfil sin figuras.
nombres={'consigna_t','consigna_p','consigna_v'};
existen=cellfun(@(n) evalin('base',sprintf('exist(''%s'',''var'')==1',n)),nombres);
assert(all(existen)||~any(existen), ...
    'Faltan puntos de la consigna. Ejecute suavizador_de_consigna para exportar los tres vectores.');
if all(existen)
    origen='puntos del workspace';
else
    codigoPerfil=fileread(fullfile(raiz,'suavizador_de_consigna.m'));
    cortePerfil=strfind(codigoPerfil,'%% 6.');
    assert(~isempty(cortePerfil),'No se identifica el fin del calculo del perfil.');
    % Solo el calculo numerico: no abre figuras, guarda MAT ni cambia Ts en base.
    eval(codigoPerfil(1:cortePerfil(1)-1));
    assignin('base','consigna_t',t(:));
    assignin('base','consigna_p',p_s(:));
    assignin('base','consigna_v',v_s(:));
    origen='suavizador_de_consigna.m (generacion automatica)';
end
fprintf('Referencia: %s; puntos en coordenadas de la carga.\n',origen);
end

function validar_tabla(t,y)
validateattributes(t,{'numeric'},{'vector','real','finite','nonempty'});
validateattributes(y,{'numeric'},{'vector','real','finite','nonempty'});
assert(numel(t)==numel(y) && numel(t)>1 && t(1)==0 && all(diff(t(:))>0), ...
    'Tabla de consigna invalida: tiempos crecientes desde cero y un valor por instante.');
end

function numero=normalizar_cableado(core)
sens=[core '/Subsystem Reference']; origen=get_param(sens,'PortHandles'); numero=0;
posicion=puerto_sensor(sens,'posicion'); temperatura=puerto_sensor(sens,'temperatura');
thetaOut=find_system(core,'SearchDepth',1,'BlockType','Outport','Port','1');
tempOut=find_system(core,'SearchDepth',1,'BlockType','Outport','Port','3');
destinos={[core '/Estimador de Estado Reducido'],2,posicion;[core '/PID Movimiento'],2,posicion; ...
    [core '/Modulador de Torque Equivalente'],4,posicion;thetaOut{1},1,posicion; ...
    [core '/Modulador de Torque Equivalente'],1,temperatura;tempOut{1},1,temperatura};
for k=1:size(destinos,1)
    ph=get_param(destinos{k,1},'PortHandles'); entrada=ph.Inport(destinos{k,2}); linea=get_param(entrada,'Line');
    fuente=origen.Outport(destinos{k,3});
    if linea~=-1 && get_param(linea,'SrcPortHandle')==fuente, continue; end
    if linea~=-1, delete_line(core,get_param(linea,'SrcPortHandle'),entrada); end
    add_line(core,fuente,entrada); numero=numero+1;
end
end

function puerto=puerto_sensor(sensor,tipo)
% Obtiene el numero real del puerto por su nombre, aunque se reordenen salidas.
salidas=find_system(sensor,'SearchDepth',1,'BlockType','Outport');
if strcmp(tipo,'posicion'), prefijo='θ'; else, prefijo='T'; end
coincide=cellfun(@(b) startsWith(get_param(b,'Name'),prefijo),salidas);
assert(nnz(coincide)==1,'No se identifica la salida de %s de sensores.',tipo);
puerto=str2double(get_param(salidas{find(coincide,1)},'Port'));
end

function [entradas,casos]=crear_casos(banco,cfg,base,encoder,rtd,corriente,inversor,todos)
% Entradas: banco, configuracion, bases y rutas de filtros. Salidas: casos aislados.
grupos={'encoder','RTD','corrientes','inversor'}; id=0;
numero=3*(1+numel(cfg.FactoresFrecuencia))+1+numel(cfg.FactoresTau);
casos=repmat(struct('parametro',0,'A1',0,'A2',0),1,numero);
for g=1:4
    if g==2, factores=cfg.FactoresTau; else, factores=cfg.FactoresFrecuencia; end
    for factor=[0 factores]
        id=id+1; entrada=Simulink.SimulationInput(banco);
        entrada=entrada.setModelParameter('TimeOut',cfg.LimiteCalculoSegundos);
        entrada=entrada.setModelParameter('CaptureErrors','on');
        for k=1:numel(todos), entrada=entrada.setBlockParameter(todos{k},'Commented','through'); end
        parametro=0; A1=0; A2=0;
        if factor>0
            switch g
                case 1
                    parametro=factor*base.wn_E; zeta=base.zeta_E; activos={encoder}; variable='wn_E';
                case 2
                    if strcmp(cfg.EscalaRTD,'tau'), parametro=factor*base.tau_RTD;
                    else, parametro=base.tau_RTD/factor; end
                    activos={rtd};
                case 3
                    parametro=factor*base.wn_I; zeta=base.zeta_I; activos=corriente; variable='wn_I';
                case 4
                    parametro=factor*base.wn_V; zeta=base.zeta_V; activos=inversor; variable='wn_V';
            end
            if g==2
                p=get_param(rtd,'DialogParameters');
                if isfield(p,'T'), entrada=entrada.setBlockParameter(rtd,'T',num2str(parametro,17));
                else, entrada=entrada.setVariable('tau_RTD',parametro); end
            else
                A1=2*zeta/parametro; A2=1/parametro^2;
                entrada=entrada.setVariable(variable,parametro);
                for k=1:numel(activos)
                    p=get_param(activos{k},'DialogParameters');
                    if isfield(p,'A1') && isfield(p,'A2')
                        entrada=entrada.setBlockParameter(activos{k},'A1',num2str(A1,17));
                        entrada=entrada.setBlockParameter(activos{k},'A2',num2str(A2,17));
                    end
                end
            end
            for k=1:numel(activos), entrada=entrada.setBlockParameter(activos{k},'Commented','off'); end
        end
        entradas(id)=entrada; %#ok<AGROW>
        casos(id)=struct('parametro',parametro,'A1',A1,'A2',A2); %#ok<AGROW>
    end
end
end

function registrar(origen,puerto,nombre)
padre=get_param(origen,'Parent'); destino=[padre '/Registro_' nombre];
add_block('simulink/Sinks/To Workspace',destino,'VariableName',nombre,'SaveFormat','Timeseries');
o=get_param(origen,'PortHandles'); d=get_param(destino,'PortHandles');
add_line(padre,o.Outport(puerto),d.Inport(1));
end

function registrar_bus(origen,puerto,nombre,campos) %#ok<INUSD>
if isempty(nombre), return; end
registrar(origen,puerto,nombre);
end

function maximo=max_bus(valor)
if isa(valor,'timeseries'), maximo=max(abs(valor.Data),[],'all');
elseif isstruct(valor)
    campos=fieldnames(valor); maximo=0;
    for k=1:numel(campos), maximo=max(maximo,max_bus(valor.(campos{k}))); end
else, error('Tipo de registro no previsto.'); end
end

function errorMax=error_senales(real,medida)
errorMax=max(abs(real.Data(:)-interp1(medida.Time,medida.Data(:),real.Time)));
end

function errorMax=error_buses(real,medida)
if isa(real,'timeseries') && isa(medida,'timeseries')
    errorMax=error_senales(real,medida);
else
    campos=fieldnames(real); camposMedida=fieldnames(medida);
    assert(numel(campos)==numel(camposMedida),'Buses con distinto numero de fases.');
    errorMax=0;
    for k=1:numel(campos)
        errorMax=max(errorMax,error_buses(real.(campos{k}),medida.(camposMedida{k})));
    end
end
end

function verificacion=verificar_ideales(series,filas,cfg)
idx=find([filas.ideal]); assert(numel(idx)==4 && all([filas(idx).completo]),'No completaron las cuatro bases ideales.');
base=series.(filas(idx(1)).caso).theta; errorMax=0;
for k=idx(2:end)
    s=series.(filas(k).caso).theta;
    errorMax=max(errorMax,max(abs(base.Data(:)-interp1(s.Time,s.Data(:),base.Time))));
end
assert(errorMax<1e-7,'Las bases ideales no coinciden: %g rad.',errorMax);
verificacion=struct('bases_ideales',4,'diferencia_maxima_rad',errorMax, ...
    'horizonte_s',cfg.TiempoFinal,'correcta',true);
end

function guardar_resultados(resultados,carpeta)
save(fullfile(carpeta,'barrido.mat'),'resultados');
writetable(resultados.tabla,fullfile(carpeta,'resumen.csv'));
datos=rmfield(resultados,'series'); datos.tabla=table2struct(resultados.tabla);
fid=fopen(fullfile(carpeta,'resumen.json'),'w'); assert(fid~=-1,'No se pudo escribir el resumen.');
fprintf(fid,'%s',jsonencode(datos,'PrettyPrint',true)); fclose(fid);
end

function valor=hash_archivo(archivo)
md=java.security.MessageDigest.getInstance('SHA-256');
fid=fopen(archivo,'r'); cerrar=onCleanup(@() fclose(fid));
while ~feof(fid), md.update(fread(fid,1048576,'*uint8')); end
valor=sprintf('%02x',typecast(md.digest(),'uint8'));
end

function cerrar_banco(banco,fuente,sensores,configuracion)
for nombre={banco,fuente,sensores}, if bdIsLoaded(nombre{1}), close_system(nombre{1},0); end, end
Simulink.fileGenControl('setConfig','config',configuracion);
end
