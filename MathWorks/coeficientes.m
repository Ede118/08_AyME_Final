%[text] # Inicialización de Objetos Especiales
BusTypes();
%[text] # Coeficientes del Modelo "Sistema No Lineal"
%[text] ## Condiciones Iniciales
init_w          = 0;
init_theta      = 0;
init_Iq         = 0;
init_Id         = 0;
init_I0         = 0;
init_Ts         = 0;
%[text] ## Sistema de la Carga
%[text] ### Coeficientes
b_l         = 0.1;                          % Incert +- 0.3
m           = 1.0;                            
l_cm        = 0.25;                        
J_cm        = 0.0208;                      
l_l         = 0.50;                         
m_l         = 1.5;                          % Var 0 ~ 1.5
J_l         = 0.0833 + m_l * l_l^2;                          
k_l         = 0.1;                          
g           = 9.80665;
%[text] ### Especificaciones de Operacion
T_ld        = 5.0;                         % Step f(t)
%[text] ## Sistema del Tren de Transmision
%[text] ### Coeficientes
% Motor 2 load
% w_m = r * w_l
r_m2l   = 120.0;                     
%[text] ## Sistema Mecanico
%[text] ### Especificaciones de operacion 
n_lNOM      = 60;
T_qNOM      = 17.0;
T_qMAX      = 45.0;
%[text] ### Coeficientes del Subsistema Mecanico
J_m         = 14.0e-6;
b_m         = 15.0e-6;
%[text] ### Coeficientes del Sistema Mecanico Equivalente
J_eq        = J_m + J_l/(r_m2l^2);
b_eq        = b_m + b_l/(r_m2l^2);
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
%[text] ### Ganancias
Kp          = 1;
Ki          = 1;
Kd          = 1;
%[text] ## Observador de Estado Reducido
%[text] ### Ganancias
K_ew         = 1;
K_et         = 1;
%[text] 

%[appendix]{"version":"1.0"}
%---
%[metadata:styles]
%   data: {"heading1":{"color":"#268cdd"},"title":{"color":"#212121"}}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
