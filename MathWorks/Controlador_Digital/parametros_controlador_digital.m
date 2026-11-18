function p = parametros_controlador_digital()
% Lee las variables YA cargadas por coeficientes.m; no cambia las ganancias.
% No ejecuta la seccion de graficas ni recalcula la sintonia.
nombres = {'Ts','J_eq','Kp_mov','Ki_mov','Kd_mov','K_et','K_ew', ...
    'Pp','lambda','L_d','L_q','Rd','Rq','R0','b_eq','k_l','g','r', ...
    'R_sREF','alpha_Cu','T_sREF'};
p = struct();
for k=1:numel(nombres)
    valor = evalin('base', nombres{k});
    validateattributes(valor, {'double'}, {'real','finite','scalar'}, mfilename, nombres{k});
    p.(nombres{k}) = valor;
end
assert(p.Ts>0 && p.J_eq>0 && p.r>0, 'Ts, J_eq y r deben ser positivos.');
modelo = 'Modelo_Lazo_Cerrado_Discretizado';
cargado = bdIsLoaded(modelo);
if ~cargado
    load_system(fullfile(fileparts(fileparts(mfilename('fullpath'))), [modelo '.slx']));
end
selector = Simulink.ID.getHandle([modelo ':522']);
p.umbral_Rs = slResolve(get_param(selector,'Threshold'),selector);
% La implementacion preserva las seis memorias cero del archivo inspeccionado.
% Si se cambian esas condiciones iniciales en la referencia, exigir actualizar
% tambien la inicializacion del codigo en lugar de comparar modelos distintos.
for sid=[696 695 743 742 751 750]
    memoria=Simulink.ID.getHandle([modelo ':' num2str(sid)]);
    inicial=slResolve(get_param(memoria,'InitialCondition'),memoria);
    assert(isequal(inicial,0),'El Unit Delay SID %d ya no tiene condicion inicial cero.',sid);
end
if ~cargado, close_system(modelo,0); end
end
