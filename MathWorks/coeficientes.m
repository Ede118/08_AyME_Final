%% Condiciones Iniciales
init_w_l = 0;
init_theta_l = 0;

%% Sistema de la Carga
% Coeficientes
b_l = 0.1;                          % Incert +- 0.3
m = 1.0;                            
l_cm = 0.25;                        
J_cm = 0.0208;                      
l_l = 0.50;                         
m_l = 1.5;                          % Var 0 ~ 1.5
J_l = 0.0833 + m_l * l_l^2;                          
k_l = 0.1;                          
g = 9.80665;

% Especificaciones de operacion
T_ld = 5.0;                         % Step f(t)

%% Sistema del Tren de Transmision
% Coeficientes
% Motor 2 load
% w_m = r * w_l
r_m2l = 120.0;                     

% Especificaciones de operacion
n_lNOM = 60;
T_qNOM = 17.0;
T_qMAX = 45.0;

%% Sistema de la PMSM
% Especificaciones de operacion
n_mNOM = 6600;
V_slNOM = 30.0;
I_sNOM = 0.4;
I_sMAX = 2.0;
T_sMAX = 115.0;
T_amb = 20;                             % Var -15 ~ 40

% Subsistema Mecanico
J_m = 14.0e-6;
b_m = 15.0e-6;

%% Sistema Mecanico Equivalente
% Coeficientes
J_eq = J_m + J_l/(r_m2l^2);
b_eq = b_m + b_l/(r_m2l^2);


%% Sistema de la PMSM
% Subsistema Electromagnetico
Pp = 3;
lambda = 0.016;
L_q = 5.8;
L_d = 6.6;
L_ls = 0.8;

% Subsistema Termico
R_sREF = 1.02;
alpha_Cu = 3.9e-3;
C_ts = 0.818;
R_tsamb = 146.7;
T_sREF = 20;

%% Sistema de Alimentacion
% Especificaciones de operacion
V_sl = 48;                              % Var 0 ~ 48
f_e = 0;                                % Var -330 ~ 330

%% Sistema de Sensores

% Coeficientes

% Especificaciones de operacion