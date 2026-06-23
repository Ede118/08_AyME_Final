clc; clear; close;
constantes;

% Defino parámetros nominales
m_l = 0;
b_l_nominal = 0.1;

J_l = (m*l_cm^2 + J_cm) + m_l*l_l^2; %[kg*m2];
J_eq = J_m + J_l/(r^2);

b_eq = b_m + b_l_nominal/(r^2);

% contantes definidas
w_pos = 800;
zitta = 0.75;
n = 2*zitta + 1;

% Ganancias del controlador PID
ba = J_eq*n*w_pos
K_sa = J_eq*n*w_pos^2
K_sia = J_eq*w_pos^3

%% Polos del sistema a lazo abierto:
Ts = 40;
Rs = R_sREF * (1+alfa_Cu*(Ts-T_sREF));
s1 = 0;
s2 = (-(Lq*b_eq+Rs*J_eq)+sqrt((Lq*b_eq+Rs*J_eq).^2-4*J_eq*Lq*(Rs*b_eq+3/2*P_p^2*lambda_m^2)))/(2*J_eq*Lq);
s3 = (-(Lq*b_eq+Rs*J_eq)-sqrt((Lq*b_eq+Rs*J_eq).^2-4*J_eq*Lq*(Rs*b_eq+3/2*P_p^2*lambda_m^2)))/(2*J_eq*Lq);
polos_lazo_abierto = [s1, s2, s3];

%% Polos del controlador para valores nominales (igual a minimos)
syms s
% Definir la ecuación característica
P_s = s^3 + (ba/J_eq)*s^2 + (K_sa/J_eq)*s + (K_sia/J_eq);
% Calcular los polos (raíces del polinomio)
polos_PID_nominales = solve(P_s == 0, s)

%% Valores maximos
% Defino parámetros nominales
m_l = 1.5;
b_l_nominal = 0.1;

J_l = (m*l_cm^2 + J_cm) + m_l*l_l^2; %[kg*m2];
J_eq = J_m + J_l/(r^2);

b_eq = b_m + b_l_nominal/(r^2);

% Ganancias del controlador PID
ba = J_eq*n*w_pos
K_sa = J_eq*n*w_pos^2
K_sia2 = J_eq*w_pos^3

%% Polos del controlador para valores máximos
syms s
% Definir la ecuación característica
P_s = s^3 + (ba/J_eq)*s^2 + (K_sa/J_eq)*s + (K_sia2/J_eq)
% Calcular los polos (raíces del polinomio)
polos_PID_maximos = solve(P_s == 0, s)


%% GRAFICA

% Crear la figura
figure;
set(gcf, 'Position', [100, 100, 1000, 600]); % Ajustar a 800x600 píxeles
hold on;
grid on;
axis equal; % Para que la escala en los ejes sea uniforme

% Graficar los polos en el plano complejo con 'x' roja y azul
plot(real(polos_lazo_abierto), imag(polos_lazo_abierto), 'mx', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'Polos Lazo Abierto');
plot(real(polos_PID_nominales), imag(polos_PID_nominales), 'rx', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'Polos PID - valores nominales/minimos');
plot(real(polos_PID_maximos), imag(polos_PID_maximos), 'bx', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'Polos PID - valores máximos');

% Etiquetas de los ejes
xlabel('Parte Real');
ylabel('Parte Imaginaria');
title('Ubicación de Polos y Ceros en el Plano Complejo');

% Agregar leyenda
legend;
