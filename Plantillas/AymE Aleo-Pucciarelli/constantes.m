clc; clear;
%% CARGA MECÁNICA
g = 9.80665; %[m/s2]

m = 1;          %[kg]
l_cm = 0.25;    %[m]
J_cm = 0.0208;  %[kg*m2]

b_l_nominal = 0.1; %[N*m/(rad/s)]
b_l_incertidumbre = 0.03;
b_l_rango = [b_l_nominal - b_l_incertidumbre, b_l_nominal + b_l_incertidumbre];
b_l = b_l_rango(1) + (b_l_rango(2) - b_l_rango(1)) * rand; % elige un número aleatorio para bl
b_l = 0.1; %[nominal]
l_l = 0.5;      %[m]
m_l_rango = [0, 1.5]; %[kg]
m_l = m_l_rango(1) + (m_l_rango(2) - m_l_rango(1)) * rand; % elige un número aleatorio para ml
m_l = 0; %[nominal]
J_l = (m*l_cm^2 + J_cm) + m_l*l_l^2; %[kg*m2]

k_l = g*(m*l_cm + m_l*l_l); %[kg*m]

T_ld_rango = [-5,5]; %[N*m]
T_ld = T_ld_rango(1) + (T_ld_rango(2) - T_ld_rango(1)) * rand; % elige un número aleatorio para T_ld
T_ld = 0; %[nominal]

%% TREN DE TRANSMISIÓN
r = 120;

n_l_nom = 60;   %[rpm]
w_l_nom = 6.28; %[rad/s]

T_q_nom = 17;   %[N*m]
T_q_max = 45;   %[N*m]

%% MAQUINA ELECTRICA PMSM
J_m = 14e-6; %[kg*m2]
b_m = 15e-6; %[N*m/(rad/2)]
P_p = 3;     %[pares de polos]
lambda_m = 0.016; %[Wb-t]
Lq = 5.8e-3;  %[H]
Ld = 6.6e-3;  %[H]
Lls = 0.8e-3; %[H]

%% PARÁMETROS EQUIVALENTES
J_eq = J_m + J_l/(r^2);
b_eq = b_m + b_l/(r^2);

%% SUBSISTEMA TÉRMICO
C_ts = 0.818; %[W/(°C/S)]
R_ts_amb = 146.7; %[°C/W]
T_sREF = 20; %[°C]
R_sREF = 1.02; %[°Ω]
tau_ts_amb = R_ts_amb * C_ts; %[s]
alfa_Cu = 3.9e-3; %[1/C°]

T_s_inicial = 40; %[°C]

%% OBSERVADOR
Ke_theta = 6.4e3;
Ke_w = 1.024e7;

%% CONTROLADOR PID
zitta = 0.75;
w_pos = 800;
b_a = J_eq*(2*zitta+1)*w_pos;
K_sa = J_eq*(2*zitta+1)*w_pos^2;
K_sia = J_eq*w_pos^3;

%% OBSERVADOR CON ACCIÓN INTEGRAL
Ke_theta_2 = 9.6e3;
Ke_w_2 = 3.072e7;
Ke_i = 3.2768e10;

%% SENSORES NO IDEALES
w_n_pos = 2000*3; % [rad/s]
w_n_current = 6000*3; % [rad/s]
tau = 0.05;
zitta_sensor = 1;

%% MODULADOR DE TENSIÓN TRIFÁSICO NO IDEAL
w_n_volt = 6000*3; % [rad/s]
zitta_modulador = 1;
Vsl_max = 48; %[V]
v_max = sqrt(2)* Vsl_max/sqrt(3);

%% CONTROLADOR DISCRETO
Ts = 2*pi/(10*5000); % [s]
