%[text] # Inicialización de Objetos Especiales
BusTypes();
%[text] # Coeficientes del Modelo "Sistema No Lineal"
%[text] <u>**Todos los coeficientes se encuentran con unidades SI**</u>
%[text] ## Condiciones Iniciales
init_w          = 0;
init_theta      = 0;
init_Iq         = 0;
init_Id         = 0;
init_I0         = 0;
init_Ts         = 20;
%[text] ## Sistema de la Carga
%[text] ### Coeficientes
b_l         = 0.1;                          % Incert +- 0.03
m           = 1.0;                            
l_cm        = 0.25;                        
J_cm        = 0.0208;                      
l_l         = 0.50;                         
m_l         = 1.5;                          % Var 0 ~ 1.5
J_l_min     = (m*l_cm^2 + J_cm);
J_l         = J_l_min + m_l * l_l^2;
k_l_min     = m*l_cm;
k_l         = k_l_min + m_l*l_l;                          
g           = 9.80665;
%[text] ### Especificaciones de Operacion
T_ld        = 5.0;                         % Step f(t)
%[text] ## Sistema del Tren de Transmision
%[text] ### Coeficientes
% Motor 2 load
% w_m = r * w_l
r       = 120.0;                     
%[text] ## Sistema Mecanico
%[text] ### Especificaciones de operacion 
n_lNOM      = 60;       % rpm
T_qNOM      = 17.0;
T_qMAX      = 45.0;
%[text] ### Coeficientes del Subsistema Mecanico
J_m         = 14.0e-6;
b_m         = 15.0e-6;
%[text] ### Coeficientes del Sistema Mecanico Equivalente
J_eq        = J_m + J_l/(r^2);
J_eq_min    = J_m + J_l_min/(r^2);
b_eq        = b_m + b_l/(r^2);
%[text] ## Sistemas de la Maquina PMSM
%[text] ### Especificaciones de Operacion
n_mNOM      = 6600;
V_slNOM     = 30.0;
I_sNOM      = 0.4;
I_sMAX      = 2.0;
T_sMAX      = 115.0;
T_amb       = 20;                             % Var -15 ~ 40
%[text] ### Subsistema Electromagnetico
Pp          = 3;
lambda      = 0.016;
L_q         = 5.8e-3;
L_d         = 6.6e-3;
L_ls        = 0.8e-3;
%[text] ### Subsistema Termico
R_sREF      = 1.02;
alpha_Cu    = 3.9e-3;
C_ts        = 0.818;
R_tsamb     = 146.7;
T_sREF      = 20;
%[text] ## Sistema de Alimentacion
%[text] ### Especificaciones de operacion
V_sl        = 48;                         % Var 0 ~ 48
f_e         = 0;                          % Var -330 ~ 330
%[text] ## Sistema de Sensores
%[text] ### Coeficientes
% 
%[text] ### Especificaciones de operacion
%
%[text] ## Modulador de Torque Equivalente
%[text] ### Coeficientes de Resistencias para control de corriente
p           = -5000;
Rq          = abs(p)*L_q;
Rd          = abs(p)*L_d;
R0          = abs(p)*L_ls;
%[text] ## Controlador PID de posición/velocidad
%[text] ### Polos asignados en el controlador de movimiento
zeta_mov    = 0.75;
wn_mov      = 800;
%[text] ### Ganancias
Kd_mov      = wn_mov * (2*zeta_mov + 1) * J_eq;
Kp_mov      = wn_mov^2 * (2*zeta_mov + 1) * J_eq;
Ki_mov      = wn_mov^3 * J_eq;

wn_mov_     = (Ki_mov / J_eq_min)^(1/3);
zeta_mov_   = 0.5*( Kd_mov/(J_eq_min*wn_mov_) - 1 ) %[output:361e830f]
%[text] ## Observador de Estado Reducido
%[text] ### Ganancias
p_obs       = 3200;
K_et        = 2*p_obs;
K_ew        = p_obs^2;
%[text] ## Controlador discreto


Ts          = 0.1;
%%
%[text] # Gráficas
%[text] ## Barrido de masa con ganancias fijas a carga máxima
% Modelo mecanico ideal compensado: solo varia la inercia de la planta.
masa_diseno = 1.5; % [kg]
J_diseno = J_m + (J_l_min + masa_diseno*l_l^2)/r^2;
Kd_fijo = J_diseno*wn_mov*(2*zeta_mov + 1);
Kp_fijo = J_diseno*wn_mov^2*(2*zeta_mov + 1);
Ki_fijo = J_diseno*wn_mov^3;

masas_barrido = linspace(0, masa_diseno, 11);
polos_barrido = complex(zeros(3, numel(masas_barrido)));
modelos_barrido = cell(1, numel(masas_barrido));
for k_masa = 1:numel(masas_barrido)
    masa_actual = masas_barrido(k_masa);
    J_actual = J_m + (J_l_min + masa_actual*l_l^2)/r^2;
    denominador = [1, Kd_fijo/J_actual, Kp_fijo/J_actual, Ki_fijo/J_actual];
    polos_barrido(:,k_masa) = roots(denominador);
    % Modelo auxiliar que muestra solo los polos caracteristicos.
    modelos_barrido{k_masa} = zpk([], polos_barrido(:,k_masa), 1);
    modelos_barrido{k_masa}.Name = sprintf('m_l = %.2f kg', masa_actual);
end

figura_barrido = figure('Color', 'w', ...
    'Name', 'Migracion de polos por variacion de masa');
mapa_barrido = pzplot(figura_barrido, modelos_barrido{:});
colores_barrido = parula(numel(masas_barrido));
for k_masa = 1:numel(masas_barrido)
    mapa_barrido.Responses(k_masa).Color = colores_barrido(k_masa,:);
    mapa_barrido.Responses(k_masa).MarkerSize = 10;
    mapa_barrido.Responses(k_masa).LineWidth = 1.8;
end
mapa_barrido.Legend.Visible = 'on';
mapa_barrido.Legend.Location = 'eastoutside';
mapa_barrido.AxesStyle.GridVisible = 'on';
mapa_barrido.AxesStyle.GridType = 's-plane';
mapa_barrido.AxesStyle.GridDamping = [0 0.5 0.75 0.9 1];
mapa_barrido.AxesStyle.GridFrequency = [400 800 1200 2000 3000 4000];
disp('Polos con masa nula:'); disp(polos_barrido(:,1));
disp('Polos con masa maxima, punto de diseno:'); disp(polos_barrido(:,end));

%[text] ## Tabla del barrido de masa: polos y propiedades del par conjugado
n_masas = numel(masas_barrido);
polo_real_tabla = zeros(n_masas,1);
polo_complejo_pos = complex(zeros(n_masas,1));
polo_complejo_neg = complex(zeros(n_masas,1));
for k_masa = 1:n_masas
    polos_masa = polos_barrido(:,k_masa);
    [~, indice_real] = min(abs(imag(polos_masa)));
    polo_real_tabla(k_masa) = real(polos_masa(indice_real));
    par_conjugado = polos_masa;
    par_conjugado(indice_real) = [];
    [~, orden_par] = sort(imag(par_conjugado), 'descend');
    polo_complejo_pos(k_masa) = par_conjugado(orden_par(1));
    polo_complejo_neg(k_masa) = par_conjugado(orden_par(2));
end
wn_par = abs(polo_complejo_pos);
wd_par = abs(imag(polo_complejo_pos));
zeta_par = -real(polo_complejo_pos)./wn_par;
% Tau de la envolvente del par. No es el tiempo de establecimiento exacto
% de la respuesta completa (tambien depende de ceros y residuos modales).
tau_par_ms = 1000./(-real(polo_complejo_pos));
J_barrido = J_m + (J_l_min + masas_barrido(:)*l_l^2)/r^2;
tabla_polos_masa = table(masas_barrido(:), J_barrido, ...
    polo_real_tabla, polo_complejo_pos, polo_complejo_neg, ...
    wn_par, wd_par, zeta_par, tau_par_ms, ...
    'VariableNames', {'Masa_kg','J_eq_kgm2','Polo_real', ...
    'Polo_complejo_pos','Polo_complejo_neg','wn_rad_s', ...
    'wd_rad_s','Zeta_par','Tau_envolvente_ms'});
fprintf('\nBARRIDO DE MASA: GANANCIAS FIJAS A CARGA MAXIMA\n');
disp(tabla_polos_masa);

%[text] ## Comparación de polos
%%\ LTI equivalente de tres estados y comparacion de polos de control
% Usa los parametros definidos anteriormente en este mismo archivo.
% Requiere Control System Toolbox para construir el objeto ss.
% Usa los parametros actuales de coeficientes.m (incluida su carga de diseno).
% Hipotesis: Rs constante; ley minima complementaria; gravedad y torque
% de reluctancia omitidos; i_d se supone identicamente nula.
% Subsistema termico y eje cero fuera de este LTI.
% No representa la linealizacion general del GNL ni la cascada completa.

%%\ Parametros de planta
T_linealizacion = T_amb;  % Temperatura usada para fijar la resistencia [degC]
Rs_lineal = R_sREF * (1 + alpha_Cu * (T_linealizacion - T_sREF));
Kt = (3/2) * Pp * lambda;
Ke = Pp * lambda;

% x = [theta_m; omega_m; i_q]
% u = [v_q; T_dl], con T_dl referido al eje de carga.
A_planta = [0, 1,                 0;
    0, -b_eq/J_eq,        Kt/J_eq;
    0, -Ke/L_q,          -Rs_lineal/L_q];
B_planta = [0,       0;
    0,      -1/(r*J_eq);
    1/L_q,   0];

% Todas las variables del modelo reducido como salidas.
C_planta = eye(3);
D_planta = zeros(3, 2);
planta_LTI = ss(A_planta, B_planta, C_planta, D_planta);
planta_LTI.StateName = {'theta_m','omega_m','i_q'};
planta_LTI.InputName = {'v_q','T_dl'};
planta_LTI.OutputName = {'theta_m','omega_m','i_q'};

%%\ Polos de planta, modulador interno y movimiento
p_planta = eig(A_planta);
% Modulador de torque: dinamica interna ideal de los lazos de corriente.
% Su conversion algebraica torque/corriente no agrega estados ni polos.
p_corriente = [-Rd/L_d; -Rq/L_q; -R0/L_ls];
% Polos del lazo cerrado ideal de movimiento (PID + inercia compensada).
% No son los polos del PID aislado ni los de toda la cascada real.
p_movimiento = roots(conv([1, 2*zeta_mov*wn_mov, wn_mov^2], [1, wn_mov]));
p_movimiento_ganancias = roots([1, Kd_mov/J_eq, Kp_mov/J_eq, Ki_mov/J_eq]);

fprintf('\nCarga: %.3f kg; J_eq: %.9g kg m^2; Rs: %.6f ohm\n', ...
    m_l, J_eq, Rs_lineal);
disp('Planta LTI de tres estados [s^-1]:'); disp(p_planta);
disp('Movimiento ideal: polos objetivo [s^-1]:'); disp(p_movimiento);
disp('Movimiento ideal: polos con ganancias actuales [s^-1]:');
disp(p_movimiento_ganancias);
disp('Modulador interno: polos de corriente d, q, 0 [s^-1]:'); disp(p_corriente);

%%\ Pole-Zero Map nativo (Control System Toolbox, MATLAB R2026b)
% La planta GNL se representa aqui por su LTI equivalente, bajo las
% hipotesis indicadas arriba. Sus ceros dependen de entrada y salida.
% Usar transferencias analiticas minimas evita ceros espurios por i_d
% no controlable/no observable en los canales hacia theta_m.
den_em = [J_eq*L_q, J_eq*Rs_lineal+b_eq*L_q, b_eq*Rs_lineal+Kt*Ke];
den_posicion = conv([1 0], den_em);
G_planta_vq = tf(Kt, den_posicion);
G_planta_carga = tf(-[L_q Rs_lineal]/r, den_posicion);
G_planta_vq.Name = 'Planta LTI eq. GNL: v_q -> theta_m';
G_planta_carga.Name = 'Planta LTI eq. GNL: T_dl -> theta_m';
z_planta_vq = zero(G_planta_vq); % No tiene ceros finitos.
z_planta_carga = zero(G_planta_carga);

% Desacople electrico ideal antes de cerrar los lazos de corriente:
% los tres canales 1/(L_k*s) tienen un polo en el origen cada uno.
p_tension = zeros(3,1);
G_tension = tf(1, [L_q 0]); % Un canal representativo; 3 polos coincidentes.
G_tension.Name = 'Modulacion de tension ideal (3 polos en 0)';
G_corriente = tf(5000, [1 5000]);
G_corriente.Name = 'Lazos de corriente ideales (3 polos en -5000)';
% Modelo caracteristico: representa solo los polos solicitados, no los
% ceros de seguimiento del PID ni los polos de la cascada completa.
G_polos_movimiento = zpk([], p_movimiento, 1);
G_polos_movimiento.Name = 'Movimiento ideal: polos caracteristicos';

figuras_polos = gobjects(2,1);
mapas_pz = cell(2,1);
for vista = 1:2
    figuras_polos(vista) = figure('Color','w', ...
        'Name',sprintf('Pole-Zero Map - vista %d',vista));
    if vista == 1
        mapas_pz{vista} = pzplot(figuras_polos(vista), ...
            G_planta_vq,'k',G_planta_carga,'k', ...
            G_tension,'m',G_corriente,'r',G_polos_movimiento,'b');
        polos_visibles = [p_planta;p_tension;p_corriente;p_movimiento];
        paso_radial = 1000;
    else
        mapas_pz{vista} = pzplot(figuras_polos(vista), ...
            G_planta_vq,'k',G_planta_carga,'k', ...
            G_tension,'m',G_polos_movimiento,'b');
        polos_visibles = [p_planta;p_tension;p_movimiento];
        paso_radial = 200;
    end
    mapa = mapas_pz{vista};
    mapa.Legend.Visible = 'on';
    mapa.Legend.Location = 'southoutside';
    mapa.Legend.Interpreter = 'tex';
    mapa.AxesStyle.GridVisible = 'on';
    mapa.AxesStyle.GridType = 's-plane';
    mapa.AxesStyle.GridDamping = [0 0.5 0.75 0.9 1];
    radios = unique(round(abs(polos_visibles),6));
    mapa.AxesStyle.GridFrequency = unique([ ...
        paso_radial:paso_radial:max(abs(polos_visibles)), radios(radios>0).']);
    ancho_polos = max(1,-min(real(polos_visibles)));
    margen_x = ancho_polos/18;
    mapa.XLimits = [-ancho_polos-margen_x,margen_x];
    limite_y = max(0.55*ancho_polos,1.15*max(abs(imag(polos_visibles))));
    mapa.YLimits = [-limite_y limite_y];
    for k_respuesta = 1:numel(mapa.Responses)
        mapa.Responses(k_respuesta).MarkerSize = 10;
        mapa.Responses(k_respuesta).LineWidth = 1.8;
    end
end
figura_polos = figuras_polos(1);
figura_polos_ampliada = figuras_polos(2);

%%\ Mapa complementario con simbolos propios por grupo
% pzplot reserva x para polos y o para ceros y no admite MarkerStyle.
% Esta figura adicional conserva una leyenda con los simbolos solicitados.
figura_simbolos = figure('Color','w','Name','Polos y ceros por grupo', ...
    'Position',[100 100 1400 700]);
tiledlayout(1,2,'TileSpacing','compact');
for vista = 1:2
    ax = nexttile; hold(ax,'on');
    polos_visibles = [p_planta;p_movimiento;p_tension];
    if vista == 1
        polos_visibles = [polos_visibles;p_corriente];
        paso_radial = 1000;
    else
        paso_radial = 200;
    end
    ancho_polos = max(1,-min(real(polos_visibles)));
    radios = unique([paso_radial:paso_radial:max(abs(polos_visibles)), ...
        round(abs(polos_visibles).',6)]);
    angulos = linspace(pi/2,3*pi/2,500);
    for radio = radios(radios>0)
        plot(ax,radio*cos(angulos),radio*sin(angulos),':', ...
            'Color',[0.7 0.7 0.7],'HandleVisibility','off');
    end
    for angulo = pi/2:pi/12:3*pi/2
        plot(ax,[0 ancho_polos*cos(angulo)], ...
            [0 ancho_polos*sin(angulo)],':','Color',[0.8 0.8 0.8], ...
            'HandleVisibility','off');
    end
    plot(ax,real(p_planta),imag(p_planta),'kx','MarkerSize',12, ...
        'LineWidth',2,'DisplayName','Polos GNL');
    plot(ax,real(z_planta_carga),imag(z_planta_carga),'ko','MarkerSize',10, ...
        'LineWidth',2,'DisplayName','Cero GNL (\theta_{m})');
    plot(ax,real(p_tension),imag(p_tension),'ms','MarkerSize',16, ...
        'LineWidth',2,'DisplayName','Polos Modulador de Tensión (\times 3)');
    if vista == 1
        plot(ax,real(p_corriente),imag(p_corriente),'rd','MarkerSize',11, ...
            'LineWidth',2,'DisplayName','Polos Controlador Corriente (\times 3)');
    end
    plot(ax,real(p_movimiento),imag(p_movimiento),'b^','MarkerSize',10, ...
        'LineWidth',2,'DisplayName','Polos Controlador Movimiento');
    xline(ax,0,'k-','HandleVisibility','off');
    yline(ax,0,'k-','HandleVisibility','off');
    grid(ax,'off'); box(ax,'on'); daspect(ax,[1 1 1]);
    xlim(ax,[-ancho_polos-ancho_polos/18,ancho_polos/18]);
    limite_y = max(0.55*ancho_polos,1.15*max(abs(imag(polos_visibles))));
    ylim(ax,[-limite_y limite_y]);
    xlabel(ax,'Re(s) [s^{-1}]'); ylabel(ax,'Im(s) [s^{-1}]');
    title(ax,sprintf('Vista %d: circulos de distancia al origen',vista));
    legend(ax,'Location','southoutside','Interpreter','tex');
end
% Exportacion opcional: exportgraphics(figura_simbolos,'Mapa.pdf','ContentType','vector');


%[appendix]{"version":"1.0"}
%---
%[metadata:styles]
%   data: {"heading1":{"color":"#268cdd"},"referenceBackgroundColor":"#ffffff","title":{"color":"#212121"}}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
%[output:361e830f]
%   data: {"dataType":"textualVariable","outputData":{"name":"zeta_mov_","value":"1.6883"}}
%---
