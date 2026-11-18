function [vabc, vdq0, torque_mov, omega_hat, theta_hat, idq0, iq_ref, Rs] = ...
    controlador_digital(theta_ref, omega_ref, theta, iabc, temperatura, ...
    resistencia_dinamica, temperatura_ref, reset, p_control)
%#codegen
% CONTROLADOR_DIGITAL Replica el controlador de Modelo_Lazo_Cerrado_Discretizado.
% Ejecutar EXACTAMENTE una vez por Ts. Entradas angulares en el eje motor.
% iabc y vabc: columnas [a;b;c]. idq0 y vdq0: columnas [d;q;0].
% p es un parametro estructurado, creado por parametros_controlador_digital.
% El inversor (filtro/saturacion), sensores, planta y ZOH quedan fuera.
% reset != 0 reinicia las seis memorias ANTES de calcular la muestra actual.
% Las memorias iniciales son cero, como los Unit Delay del modelo de referencia.

p = p_control;
persistent memoria
if isempty(memoria)
    memoria = zeros(6, 1);
end
if reset ~= 0
    memoria = zeros(6, 1);
end
% [integral_error; error_previo; omega_previa; deriv_omega_previa;
%  theta_previa; deriv_theta_previa]. Solo se escriben al final de la muestra.
anterior = memoria;
error_posicion = theta_ref - theta;
integral_error = Integrador_Discreto(error_posicion, anterior(1), anterior(2), p.Ts);

% T = Tbase - Kd*omega_hat. El observador recibe ESTE T de la muestra actual.
% Evaluar primero el PID con velocidad cero permite despejar conjuntamente
% PID + observador, sin introducir un Unit Delay que no existe en el modelo.
torque_base = PID_de_Movimiento(theta_ref, omega_ref, theta, 0, integral_error, p);
[omega_hat, theta_hat, deriv_omega, deriv_theta] = ...
    Estimador_de_Estado_de_Orden_Reducido(torque_base, theta, anterior, p);
torque_mov = PID_de_Movimiento(theta_ref, omega_ref, theta, omega_hat, integral_error, p);

[vabc, vdq0, idq0, iq_ref, Rs] = Modulador_de_Torque_Equivalente( ...
    torque_mov, omega_hat, theta, iabc, temperatura, ...
    resistencia_dinamica, temperatura_ref, p);

memoria = [integral_error; error_posicion; omega_hat; deriv_omega; theta_hat; deriv_theta];
end

function torque = PID_de_Movimiento(theta_ref, omega_ref, theta, omega, integral_error, p)
% SID 525: P sobre error de posicion, I trapezoidal y D sobre error de velocidad.
torque = p.Ki_mov*integral_error + p.Kp_mov*(theta_ref-theta) ...
    + p.Kd_mov*(omega_ref-omega);
end

function [omega, theta_hat, dw, dtheta] = ...
    Estimador_de_Estado_de_Orden_Reducido(torque_base, theta, mem, p)
% SID 355 y sus integradores 737/745, todos con memorias iniciales nulas.
% omega = omega_prev + h*(T/J + K_ew*(theta-theta_hat) + dw_prev)
% theta_hat = theta_prev + h*(omega + K_et*(theta-theta_hat) + dtheta_prev)
% con T = torque_base - Kd_mov*omega y h = Ts/2.
% Se resuelve el sistema lineal de la muestra actual de forma explicita.
h = p.Ts/2;
a = 1 + h*p.K_et;
c = (mem(5) + h*(p.K_et*theta + mem(6)))/a;
den = 1 + h*p.Kd_mov/p.J_eq + h*h*p.K_ew/a;
omega = (mem(3) + h*(torque_base/p.J_eq + p.K_ew*(theta-c) + mem(4)))/den;
theta_hat = c + (h/a)*omega;
torque = torque_base - p.Kd_mov*omega;
dw = torque/p.J_eq + p.K_ew*(theta-theta_hat);
dtheta = omega + p.K_et*(theta-theta_hat);
end

function [vabc, vdq0, idq0, iq_ref, Rs] = Modulador_de_Torque_Equivalente( ...
    torque, omega, theta, iabc, temperatura, dinamica, temperatura_ref, p)
% SID 368: usa posicion MEDIDA y velocidad ESTIMADA, como el cableado original.
idq0 = Transformada_Directa_de_Park(iabc, p.Pp*theta);
Rs = Calculo_de_Resistencia(temperatura, dinamica, temperatura_ref, p);
iq_ref = PID_de_Torque(torque, omega, theta, idq0(1), p);
virtual = Lazo_de_Corriente([0; iq_ref; 0], idq0, p);
vdq0 = Modulador_de_Tension(virtual, idq0, omega, Rs, p);
vabc = Transformada_Inversa_de_Park(vdq0, p.Pp*theta);
end

function iq_ref = PID_de_Torque(torque, omega, theta, id, p)
% Equivale al SID 483, "Modulador y Compensacion de Torque".
% El nombre identifica la funcion solicitada; NO agrega un PID de torque:
% el modelo de referencia solo tiene compensacion y conversion algebraica.
torque_compensado = torque + p.b_eq*omega + (p.k_l*p.g/p.r)*sin(theta/p.r);
constante_torque = (3/2)*p.Pp*(p.lambda + (p.L_d-p.L_q)*id);
iq_ref = torque_compensado/constante_torque;
end

function virtual = Lazo_de_Corriente(referencia, medida, p)
% SID 382. Tres reguladores P; no se agrega accion integral ni saturacion.
virtual = [p.Rd*(referencia(1)-medida(1)); ...
           p.Rq*(referencia(2)-medida(2)); ...
           p.R0*(referencia(3)-medida(3))];
end

function vdq0 = Modulador_de_Tension(virtual, idq0, omega, Rs, p)
% SID 412: cancelacion de resistencia, acoplamientos dq y FEM.
omega_e = p.Pp*omega;
vdq0 = [virtual(1) + Rs*idq0(1) - omega_e*p.L_q*idq0(2); ...
        virtual(2) + Rs*idq0(2) + omega_e*(p.L_d*idq0(1)+p.lambda); ...
        virtual(3) + Rs*idq0(3)];
end

function dq0 = Transformada_Directa_de_Park(abc, theta_e)
% AxisAlignment=Q-axis, PowerInvariant=off. d=sin; q=cos; cero=media.
angulos = [theta_e; theta_e-2*pi/3; theta_e+2*pi/3];
dq0 = [(2/3)*sum(sin(angulos).*abc); ...
       (2/3)*sum(cos(angulos).*abc); ...
       (abc(1)+abc(2)+abc(3))/3];
end

function abc = Transformada_Inversa_de_Park(dq0, theta_e)
angulos = [theta_e; theta_e-2*pi/3; theta_e+2*pi/3];
abc = sin(angulos)*dq0(1) + cos(angulos)*dq0(2) + ones(3,1)*dq0(3);
end

function valor = Integrador_Discreto(entrada, valor_previo, entrada_previa, Ts)
% Replica literal del subsistema Integrador Discreto, SID 690.
valor = valor_previo + (Ts/2)*(entrada+entrada_previa);
end

function Rs = Calculo_de_Resistencia(temperatura, dinamica, temperatura_ref, p)
% SID 522: Switch u2 > Threshold. El umbral se lee del modelo, no se supone.
if dinamica > p.umbral_Rs
    temperatura_usada = temperatura;
else
    temperatura_usada = temperatura_ref;
end
Rs = p.R_sREF*(1 + p.alpha_Cu*(temperatura_usada-p.T_sREF));
end
