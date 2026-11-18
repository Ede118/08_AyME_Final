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

V_slMAX     = 48.0;
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
zeta_mov_   = 0.5*( Kd_mov/(J_eq_min*wn_mov_) - 1 );
%[text] ## Observador de Estado Reducido
%[text] ### Ganancias
p_obs       = 3200;
K_et        = 2*p_obs;
K_ew        = p_obs^2;
%[text] ## Sensores y Actuadores No Ideales
%[text] ### Sensores de Corriente
wn_I        = 5*6000;
zeta_I      = 1;

A1_I        = 1/(wn_I^2);
A2_I        = 2*zeta_I/(wn_I);
%[text] ### Encoder
wn_E        = 5*2000;
zeta_E      = 1;

A1_E        = 1/(wn_E^2);
A2_E        = 2*zeta_E/(wn_E);
%[text] ### RTD
tau_RTD     = 20;
%[text] ### Inverter No Ideal
sat_V       = sqrt(2/3)*V_slMAX;

wn_V        = 20*6000;
zeta_V      = 1;

A1_V        = 1/(wn_V^2);
A2_V        = 2*zeta_V/(wn_V);
%[text] ## Controlador
Ts          = 1e-5;
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
disp('Polos con masa nula:'); disp(polos_barrido(:,1)); %[output:7ed33593]
disp('Polos con masa maxima, punto de diseno:'); disp(polos_barrido(:,end)); %[output:90d5e3af]

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

fprintf('\nCarga: %.3f kg; J_eq: %.9g kg m^2; Rs: %.6f ohm\n', ... %[output:group:41b7cf21] %[output:99965155]
    m_l, J_eq, Rs_lineal); %[output:group:41b7cf21] %[output:99965155]
disp('Planta LTI de tres estados [s^-1]:'); disp(p_planta); %[output:659462fb]
disp('Movimiento ideal: polos objetivo [s^-1]:'); disp(p_movimiento); %[output:9570c196]
disp('Movimiento ideal: polos con ganancias actuales [s^-1]:'); %[output:2ca1f117]
disp(p_movimiento_ganancias); %[output:8ccdda97]
disp('Modulador interno: polos de corriente d, q, 0 [s^-1]:'); disp(p_corriente); %[output:7ac1d1b1]

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

%[text] 

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
fprintf('\nBARRIDO DE MASA: GANANCIAS FIJAS A CARGA MAXIMA\n'); %[output:4a877c51]
disp(tabla_polos_masa); %[output:61b6eea4]

%[text] ## Tabla del barrido en LaTeX para Overleaf
% fprintf interpreta las barras invertidas: escribir \\ para imprimir \.
fprintf('\n%% INICIO TABLA LATEX: copiar desde \\begin{table} hasta \\end{table}\n'); %[output:5bdb6780]
fprintf('\\begin{table}[!htbp]\n'); %[output:1458e66b]
fprintf('    \\centering\n'); %[output:28e0b7e2]
fprintf('    \\small\n'); %[output:8d9d007b]
fprintf('    \\caption{Polos del lazo cerrado ideal de movimiento al variar la masa, con ganancias fijas calculadas para $m_l=%.2f\\;\\mathrm{kg}$.}\n', masa_diseno); %[output:05a2ea8d]
fprintf('    \\label{tab:polos-barrido-masa}\n'); %[output:0afbc253]
fprintf('    \\begin{tabular}{r r r r r r r}\n'); %[output:10ff5a7b]
fprintf('        \\hline\n'); %[output:2f61e83d]
fprintf('        $m_l$ & $p_r$ & $p_{2,3}$ & $\\omega_n$ & $\\omega_d$ & $\\zeta$ & $\\tau$ \\\\\n'); %[output:93b96c23]
fprintf('        $[\\mathrm{kg}]$ & $[\\mathrm{s^{-1}}]$ & $[\\mathrm{s^{-1}}]$ & $[\\mathrm{rad/s}]$ & $[\\mathrm{rad/s}]$ & & $[\\mathrm{ms}]$ \\\\\n'); %[output:25f8b41b]
fprintf('        \\hline\n'); %[output:8dcd14ec]
for k_masa = 1:n_masas %[output:group:86cf9ac3]
    fprintf('        %.2f & $%.2f$ & $%.2f \\pm j%.2f$ & %.2f & %.2f & %.4f & %.3f \\\\\n', ... %[output:9c1c0dfd]
        masas_barrido(k_masa), polo_real_tabla(k_masa), ... %[output:9c1c0dfd]
        real(polo_complejo_pos(k_masa)), wd_par(k_masa), ... %[output:9c1c0dfd]
        wn_par(k_masa), wd_par(k_masa), zeta_par(k_masa), tau_par_ms(k_masa)); %[output:9c1c0dfd]
end %[output:group:86cf9ac3]
fprintf('        \\hline\n'); %[output:53d368a2]
fprintf('    \\end{tabular}\n'); %[output:5f579d1f]
fprintf('\\end{table}\n'); %[output:12b58f46]
fprintf('%% FIN TABLA LATEX\n'); %[output:37cff914]

%[appendix]{"version":"1.0"}
%---
%[metadata:styles]
%   data: {"heading1":{"color":"#268cdd"},"referenceBackgroundColor":"#ffffff","title":{"color":"#212121"}}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
%[output:7ed33593]
%   data: {"dataType":"text","outputData":{"text":"Polos con masa nula:\n   1.0e+03 *\n\n  -3.7225 + 0.0000i\n  -0.4550 + 0.3340i\n  -0.4550 - 0.3340i\n\n","truncated":false}}
%---
%[output:90d5e3af]
%   data: {"dataType":"text","outputData":{"text":"Polos con masa maxima, punto de diseno:\n   1.0e+02 *\n\n  -8.0000 + 0.0000i\n  -6.0000 + 5.2915i\n  -6.0000 - 5.2915i\n\n","truncated":false}}
%---
%[output:99965155]
%   data: {"dataType":"text","outputData":{"text":"\nCarga: 1.500 kg; J_eq: 4.58263889e-05 kg m^2; Rs: 1.020000 ohm\n","truncated":false}}
%---
%[output:659462fb]
%   data: {"dataType":"text","outputData":{"text":"Planta LTI de tres estados [s^-1]:\n   0.0000 + 0.0000i\n -88.1705 +72.8888i\n -88.1705 -72.8888i\n\n","truncated":false}}
%---
%[output:9570c196]
%   data: {"dataType":"text","outputData":{"text":"Movimiento ideal: polos objetivo [s^-1]:\n   1.0e+02 *\n\n  -8.0000 + 0.0000i\n  -6.0000 + 5.2915i\n  -6.0000 - 5.2915i\n\n","truncated":false}}
%---
%[output:2ca1f117]
%   data: {"dataType":"text","outputData":{"text":"Movimiento ideal: polos con ganancias actuales [s^-1]:\n","truncated":false}}
%---
%[output:8ccdda97]
%   data: {"dataType":"text","outputData":{"text":"   1.0e+02 *\n\n  -8.0000 + 0.0000i\n  -6.0000 + 5.2915i\n  -6.0000 - 5.2915i\n\n","truncated":false}}
%---
%[output:7ac1d1b1]
%   data: {"dataType":"text","outputData":{"text":"Modulador interno: polos de corriente d, q, 0 [s^-1]:\n       -5000\n       -5000\n       -5000\n\n","truncated":false}}
%---
%[output:4a877c51]
%   data: {"dataType":"text","outputData":{"text":"\nBARRIDO DE MASA: GANANCIAS FIJAS A CARGA MAXIMA\n","truncated":false}}
%---
%[output:61b6eea4]
%   data: {"dataType":"text","outputData":{"text":"    <strong>Masa_kg<\/strong>    <strong>J_eq_kgm2<\/strong>     <strong>Polo_real<\/strong>    <strong>Polo_complejo_pos<\/strong>    <strong>Polo_complejo_neg<\/strong>    <strong>wn_rad_s<\/strong>    <strong>wd_rad_s<\/strong>    <strong>Zeta_par<\/strong>    <strong>Tau_envolvente_ms<\/strong>\n    <strong>_______<\/strong>    <strong>__________<\/strong>    <strong>_________<\/strong>    <strong>_________________<\/strong>    <strong>_________________<\/strong>    <strong>________<\/strong>    <strong>________<\/strong>    <strong>________<\/strong>    <strong>_________________<\/strong>\n\n        0      1.9785e-05     -3722.5      -454.99+334.01i      -454.99-334.01i      564.43      334.01     0.80611          2.1978      \n     0.15      2.2389e-05       -3163      -465.31+338.83i      -465.31-338.83i       575.6      338.83     0.80839          2.1491      \n      0.3      2.4993e-05     -2713.5      -476.83+344.39i      -476.83-344.39i      588.19      344.39     0.81067          2.0972      \n     0.45      2.7597e-05     -2341.5      -489.82+350.98i      -489.82-350.98i      602.58      350.98     0.81286          2.0416      \n      0.6      3.0201e-05     -2025.5      -504.63+359.04i      -504.63-359.04i      619.32      359.04     0.81481          1.9817      \n     0.75      3.2806e-05     -1750.3      -521.74+369.33i      -521.74-369.33i      639.23      369.33      0.8162          1.9167      \n      0.9       3.541e-05     -1505.1      -541.65+383.25i      -541.65-383.25i      663.52      383.25     0.81632          1.8462      \n     1.05      3.8014e-05     -1282.1      -564.47+403.48i      -564.47-403.48i      693.84      403.48     0.81354          1.7716      \n      1.2      4.0618e-05     -1080.7      -587.89+434.64i      -587.89-434.64i      731.11      434.64      0.8041           1.701      \n     1.35      4.3222e-05     -914.75      -602.88+479.56i      -602.88-479.56i      770.35      479.56      0.7826          1.6587      \n      1.5      4.5826e-05        -800         -600+529.15i         -600-529.15i         800      529.15        0.75          1.6667      \n\n","truncated":false}}
%---
%[output:5bdb6780]
%   data: {"dataType":"text","outputData":{"text":"\n% INICIO TABLA LATEX: copiar desde \\begin{table} hasta \\end{table}\n","truncated":false}}
%---
%[output:1458e66b]
%   data: {"dataType":"text","outputData":{"text":"\\begin{table}[!htbp]\n","truncated":false}}
%---
%[output:28e0b7e2]
%   data: {"dataType":"text","outputData":{"text":"    \\centering\n","truncated":false}}
%---
%[output:8d9d007b]
%   data: {"dataType":"text","outputData":{"text":"    \\small\n","truncated":false}}
%---
%[output:05a2ea8d]
%   data: {"dataType":"text","outputData":{"text":"    \\caption{Polos del lazo cerrado ideal de movimiento al variar la masa, con ganancias fijas calculadas para $m_l=1.50\\;\\mathrm{kg}$.}\n","truncated":false}}
%---
%[output:0afbc253]
%   data: {"dataType":"text","outputData":{"text":"    \\label{tab:polos-barrido-masa}\n","truncated":false}}
%---
%[output:10ff5a7b]
%   data: {"dataType":"text","outputData":{"text":"    \\begin{tabular}{r r r r r r r}\n","truncated":false}}
%---
%[output:2f61e83d]
%   data: {"dataType":"text","outputData":{"text":"        \\hline\n","truncated":false}}
%---
%[output:93b96c23]
%   data: {"dataType":"text","outputData":{"text":"        $m_l$ & $p_r$ & $p_{2,3}$ & $\\omega_n$ & $\\omega_d$ & $\\zeta$ & $\\tau$ \\\\\n","truncated":false}}
%---
%[output:25f8b41b]
%   data: {"dataType":"text","outputData":{"text":"        $[\\mathrm{kg}]$ & $[\\mathrm{s^{-1}}]$ & $[\\mathrm{s^{-1}}]$ & $[\\mathrm{rad\/s}]$ & $[\\mathrm{rad\/s}]$ & & $[\\mathrm{ms}]$ \\\\\n","truncated":false}}
%---
%[output:8dcd14ec]
%   data: {"dataType":"text","outputData":{"text":"        \\hline\n","truncated":false}}
%---
%[output:9c1c0dfd]
%   data: {"dataType":"text","outputData":{"text":"        0.00 & $-3722.52$ & $-454.99 \\pm j334.01$ & 564.43 & 334.01 & 0.8061 & 2.198 \\\\\n        0.15 & $-3163.04$ & $-465.31 \\pm j338.83$ & 575.60 & 338.83 & 0.8084 & 2.149 \\\\\n        0.30 & $-2713.47$ & $-476.83 \\pm j344.39$ & 588.19 & 344.39 & 0.8107 & 2.097 \\\\\n        0.45 & $-2341.46$ & $-489.82 \\pm j350.98$ & 602.58 & 350.98 & 0.8129 & 2.042 \\\\\n        0.60 & $-2025.46$ & $-504.63 \\pm j359.04$ & 619.32 & 359.04 & 0.8148 & 1.982 \\\\\n        0.75 & $-1750.34$ & $-521.74 \\pm j369.33$ & 639.23 & 369.33 & 0.8162 & 1.917 \\\\\n        0.90 & $-1505.06$ & $-541.65 \\pm j383.25$ & 663.52 & 383.25 & 0.8163 & 1.846 \\\\\n        1.05 & $-1282.09$ & $-564.47 \\pm j403.48$ & 693.84 & 403.48 & 0.8135 & 1.772 \\\\\n        1.20 & $-1080.68$ & $-587.89 \\pm j434.64$ & 731.11 & 434.64 & 0.8041 & 1.701 \\\\\n        1.35 & $-914.75$ & $-602.88 \\pm j479.56$ & 770.35 & 479.56 & 0.7826 & 1.659 \\\\\n        1.50 & $-800.00$ & $-600.00 \\pm j529.15$ & 800.00 & 529.15 & 0.7500 & 1.667 \\\\\n","truncated":false}}
%---
%[output:53d368a2]
%   data: {"dataType":"text","outputData":{"text":"        \\hline\n","truncated":false}}
%---
%[output:5f579d1f]
%   data: {"dataType":"text","outputData":{"text":"    \\end{tabular}\n","truncated":false}}
%---
%[output:12b58f46]
%   data: {"dataType":"text","outputData":{"text":"\\end{table}\n","truncated":false}}
%---
%[output:37cff914]
%   data: {"dataType":"text","outputData":{"text":"% FIN TABLA LATEX\n","truncated":false}}
%---
