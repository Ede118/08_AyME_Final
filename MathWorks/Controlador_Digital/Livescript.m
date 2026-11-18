%% Controlador digital de movimiento de la PMSM
% Este script explica controlador_digital.m mediante secciones ejecutables.
% Puede abrirse en el Editor de MATLAB y ejecutarse por secciones (Ctrl+Enter).
% Se conserva la extension .m solicitada; no es un archivo binario .mlx.
%
% OBJETIVO: a partir de referencias y mediciones muestreadas, calcular las
% consignas de tension trifasica que se envian al inversor.
%
% UNICA SALIDA DE ACTUACION:
%                 vabc = [Va*; Vb*; Vc*]             [V]
%
% Es una orden de tension en coordenadas fisicas abc, despues de compensar
% las realimentaciones no lineales y aplicar Park inversa. No es la tension
% efectivamente aplicada al motor: esta resulta de la dinamica y saturacion
% del inversor. Tampoco es el vector de tensiones virtuales de los lazos P.
%
% Las demas salidas de la implementacion original son diagnosticos. No deben
% conectarse como acciones adicionales sobre el motor. Las estimaciones y
% consignas intermedias ya se usan DENTRO del controlador.
%
% Flujo de informacion:
% referencias + sensores -> muestreo -> controlador -> vabc* retenida
% -> inversor (dinamica y saturacion) -> planta -> sensores.
%
% Referencia de implementacion: Modelo_Lazo_Cerrado_Discretizado.slx.
% Este script no modifica ni regenera modelos y no lanza simulaciones.

%% 1. Preparacion y parametros actuales
% Esta seccion carga solo los parametros de coeficientes.m, sin sus graficas.
% Restaura los valores de ese archivo en el workspace base. Si ya se ajustaron
% alli parametros que se desean conservar, usar en su lugar:
%     p_ls = parametros_controlador_digital;
%
% p_ls es aqui una copia para la explicacion. En el MATLAB Function, la misma
% estructura se llama p_control y tiene Scope = Parameter, no Input.
carpeta_ls = fileparts(mfilename('fullpath'));
addpath(carpeta_ls, fileparts(carpeta_ls));
p_ls = inicializar_controlador_digital;
fprintf('Periodo actual Ts = %.9g s = %.6g microsegundos\n', ...
    p_ls.Ts, p_ls.Ts*1e6);
fprintf('Frecuencia de ejecucion fs = %.9g Hz\n', 1/p_ls.Ts);

%% 2. Entradas: referencias, mediciones y configuracion
% Todas las entradas numericas deben ser reales y de tipo double en el uso
% mostrado. iabc es columna 3x1; las demas senales son escalares.
%
% theta_ref y omega_ref se refieren al EJE MOTOR. Si la consigna se genera
% en la articulacion: theta_ref = r*q_ref y omega_ref = r*dq_ref.
% En modo posicion, ambas referencias deben ser cinematicamente compatibles.
%
% theta, iabc y temperatura son mediciones, no estados ideales de la planta.
% Se toman despues de los sensores y del muestreo correspondiente.
%
% No se requiere medir omega: el observador la estima internamente.
% Tampoco entra T_dl: la perturbacion de carga se considera desconocida.
entradas_ls = table( ...
    ["theta_ref"; "omega_ref"; "theta"; "iabc"; "temperatura"; ...
     "resistencia_dinamica"; "temperatura_ref"; "reset"; "p_control"], ...
    ["Escalar"; "Escalar"; "Escalar"; "Columna 3x1"; "Escalar"; ...
     "Escalar"; "Escalar"; "Escalar"; "Estructura de parametros"], ...
    ["rad"; "rad/s"; "rad"; "A"; "grados Celsius"; ...
     "adimensional"; "grados Celsius"; "adimensional"; "Unidades por campo"], ...
    ["Posicion de referencia en el eje motor"; ...
     "Velocidad de referencia en el eje motor"; ...
     "Posicion medida del motor"; ...
     "Corrientes medidas [Ia; Ib; Ic]"; ...
     "Temperatura medida del estator"; ...
     "Seleccion de resistencia variable o fija"; ...
     "Temperatura usada al seleccionar resistencia fija"; ...
     "Reinicio de las memorias antes del calculo actual"; ...
     "Ganancias, constantes fisicas y periodo de muestreo"], ...
    'VariableNames', {'Nombre','Dimension','Unidad','Significado'});
disp(entradas_ls);

%% 3. Parametros: datos que no son mediciones
% Los parametros no se estiman ni se sintonizan en cada llamada. Se leen de
% las variables ya definidas en coeficientes.m y se agrupan en p_control.
%
% Ts: periodo entre ejecuciones; no es la temperatura ni el paso del solver.
% J_eq: inercia empleada por el observador.
% Kp_mov, Ki_mov, Kd_mov: ganancias del PID de movimiento.
% K_et, K_ew: ganancias de correccion del observador.
% Pp: numero de pares de polos; theta_e = Pp*theta.
% lambda: flujo enlazado debido a los imanes.
% L_d, L_q: inductancias utilizadas en reluctancia y desacoplamiento.
% Rd, Rq, R0: ganancias P de corriente, con dimension de resistencia.
% b_eq: friccion viscosa equivalente referida al eje motor.
% k_l, g, r: coeficiente gravitatorio, gravedad y relacion de reduccion.
% R_sREF, alpha_Cu, T_sREF: modelo de resistencia en funcion de temperatura.
% umbral_Rs: umbral del Switch original; se lee del modelo de referencia.
%
% La implementacion inspeccionada usa Ts = 1e-5 s. No se sustituye aqui por
% el candidato de muestreo que se habia discutido en el texto del informe.
% La tabla muestra los valores cargados, en lugar de duplicar sus constantes.
campos_ls = string(fieldnames(p_ls));
valores_ls = cellfun(@(nombre) p_ls.(nombre), cellstr(campos_ls));
parametros_ls = table(campos_ls, valores_ls, ...
    'VariableNames', {'Parametro','ValorActual'});
disp(parametros_ls);

%% 4. Salida de actuacion y salidas de diagnostico
% La funcion de referencia expone ocho resultados para permitir validacion
% y observacion. Solo el PRIMERO se envia al inversor: vabc.
%
% vdq0 contiene tensiones con compensacion NL en ejes [d;q;0]. No debe
% confundirse con "virtual", que es la salida de los reguladores P antes de
% agregar resistencia, acoplamientos y fuerza contraelectromotriz.
%
% torque_mov es T_m*, salida del PID de movimiento. No es necesariamente el
% torque electromagnetico del motor: aun faltan las compensaciones mecanicas
% y las dinamicas de seguimiento del lazo interno.
%
% omega_hat y theta_hat son estimaciones internas. Para analizar errores de
% estimacion se comparan con los estados reales de LA MISMA planta simulada.
% Comparar salidas de dos plantas distintas mide otra diferencia.
salidas_ls = table( ...
    ["vabc"; "vdq0"; "torque_mov"; "omega_hat"; "theta_hat"; ...
     "idq0"; "iq_ref"; "Rs"], ...
    ["Columna 3x1"; "Columna 3x1"; "Escalar"; "Escalar"; "Escalar"; ...
     "Columna 3x1"; "Escalar"; "Escalar"], ...
    ["V"; "V"; "N m"; "rad/s"; "rad"; "A"; "A"; "ohm"], ...
    ["ACTUACION: [Va*; Vb*; Vc*] hacia el inversor"; ...
     "Diagnostico: tension compensada [Vd; Vq; V0]"; ...
     "Diagnostico: consigna de torque de movimiento en eje motor"; ...
     "Diagnostico: velocidad estimada"; ...
     "Diagnostico: posicion estimada"; ...
     "Diagnostico: corrientes medidas transformadas [Id; Iq; I0]"; ...
     "Diagnostico: consigna de corriente en cuadratura"; ...
     "Diagnostico: resistencia usada por el desacoplamiento"], ...
    'VariableNames', {'Nombre','Dimension','Unidad','DestinoOSignificado'});
disp(salidas_ls);

%% 5. PID de movimiento e integrador de Tustin
% Para cada muestra k se calcula:
%
%   e_theta[k] = theta_ref[k] - theta[k]
%   xi[k] = xi[k-1] + (Ts/2)*(e_theta[k] + e_theta[k-1])
%   e_omega[k] = omega_ref[k] - omega_hat[k]
%   T_m*[k] = Kp_mov*e_theta[k] + Ki_mov*xi[k] + Kd_mov*e_omega[k]
%
% La accion D usa el error de velocidad: no se deriva numericamente theta.
% Integrador_Discreto es una funcion sin memoria propia: recibe el valor
% anterior y la entrada anterior, y devuelve el acumulado actual.
% La memoria se guarda una sola vez en la funcion principal.
%
% Este ejemplo muestra SOLO la regla de Tustin, fuera del controlador:
Ts_ejemplo_ls = p_ls.Ts;
entrada_actual_ls = 0.02;     % error de posicion actual [rad]
entrada_previa_ls = 0.01;     % error de posicion anterior [rad]
integral_previa_ls = 0;      % integral anterior [rad s]
integral_actual_ls = integral_previa_ls + ...
    (Ts_ejemplo_ls/2)*(entrada_actual_ls+entrada_previa_ls);
fprintf('Ejemplo de integral actual: %.9g rad s\n', integral_actual_ls);

%% 6. Observador y dependencia instantanea con el PID
% El observador mecanico recibe posicion medida y torque de movimiento:
%
%   d(omega_hat)/dt = T_m*/J_eq + K_ew*(theta-theta_hat)
%   d(theta_hat)/dt = omega_hat + K_et*(theta-theta_hat)
%
% No recibe el torque de carga desconocido. Sus polos describen la dinamica
% homogenea del error; no garantizan error nulo ante cualquier perturbacion.
%
% Tustin depende de la entrada ACTUAL. Por eso omega_hat[k] depende de T_m*[k]
% y el PID, a su vez, depende de omega_hat[k]. Llamar primero al observador
% con T_m*[k-1] introduciria un retardo que no existe en el modelo original.
%
% Para resolver la dependencia simultanea se define h = Ts/2 y:
%
%   Tbase = Kp_mov*e_theta + Ki_mov*xi + Kd_mov*omega_ref
%   T_m* = Tbase - Kd_mov*omega_hat
%   a = 1 + h*K_et
%   c = (theta_hat_previa + h*(K_et*theta + dtheta_previa))/a
%
%   omega_hat = (omega_previa
%               + h*(Tbase/J_eq + K_ew*(theta-c) + domega_previa))
%               / (1 + h*Kd_mov/J_eq + h^2*K_ew/a)
%   theta_hat = c + (h/a)*omega_hat
%
% El codigo evalua estas expresiones y obtiene despues T_m* y las derivadas
% actuales. No introduce un retardo ni necesita iterar para resolver el lazo.

%% 7. Transformada directa de Park y resistencia
% La corriente medida [Ia;Ib;Ic] se transforma a [Id;Iq;I0] usando la posicion
% MEDIDA. El angulo electrico es theta_e = Pp*theta y los angulos de fase:
%
%   ang = [theta_e; theta_e-2*pi/3; theta_e+2*pi/3]
%   Id = (2/3)*sum(sin(ang).*iabc)
%   Iq = (2/3)*sum(cos(ang).*iabc)
%   I0 = (Ia+Ib+Ic)/3
%
% Corresponde a Q-axis y PowerInvariant=off en el modelo: d asociado al seno,
% q al coseno y normalizacion de amplitud invariante.
%
% Para el desacoplamiento resistivo se elige la temperatura:
%   si resistencia_dinamica > p_control.umbral_Rs: usar temperatura medida;
%   en otro caso: usar temperatura_ref.
%
%   Rs = R_sREF*(1 + alpha_Cu*(temperatura_usada-T_sREF))
%
% En el archivo inspeccionado umbral_Rs=0; con entradas 0 y 1, 0 selecciona
% compensacion fija y 1 selecciona compensacion dinamica. No se cambia por
% ello la resistencia fisica de la planta, que sigue su propio modelo termico.

%% 8. Modulador de torque y lazos de corriente
% La funcion llamada PID_de_Torque reproduce el subsistema original de
% conversion torque/corriente y compensacion mecanica. NO contiene un PID
% de torque independiente ni agrega otro integrador.
%
%   T_comp = T_m* + b_eq*omega_hat + (k_l*g/r)*sin(theta/r)
%   Kt_actual = (3/2)*Pp*(lambda + (L_d-L_q)*Id)
%   Iq_ref = T_comp/Kt_actual
%   Id_ref = 0; I0_ref = 0
%
% Los lazos P de corriente calculan las tensiones virtuales:
%   Vd_virtual = Rd*(Id_ref-Id)
%   Vq_virtual = Rq*(Iq_ref-Iq)
%   V0_virtual = R0*(I0_ref-I0)
%
% No se incorpora una accion integral de corriente ni limitadores nuevos.
% La division por Kt_actual conserva el dominio de validez del modelo:
% no debe asumirse que es admisible operar con Kt_actual cercano a cero.

%% 9. Modulador de tension y Park inversa: de lo virtual a la actuacion
% Con omega_e = Pp*omega_hat se agregan las compensaciones electricas:
%
%   Vd = Vd_virtual + Rs*Id - omega_e*L_q*Iq
%   Vq = Vq_virtual + Rs*Iq + omega_e*(L_d*Id+lambda)
%   V0 = V0_virtual + Rs*I0
%
% El vector vdq0 = [Vd;Vq;V0] ya contiene las compensaciones, pero aun esta
% expresado en el sistema rotante. Park inversa calcula la orden trifasica:
%
%   vabc = sin(ang)*Vd + cos(ang)*Vq + [1;1;1]*V0
%
% Esta es la UNICA accion enviada al inversor. La retencion conserva la orden
% entre muestras. El inversor aplica su filtro y saturacion, y entrega a la
% planta una tension que puede diferir de la orden vabc.
% No conectar vdq0 y vabc simultaneamente como dos acciones de control.

%% 10. Almacenamiento de informacion y reinicio
% La funcion principal guarda seis valores en una variable persistent:
%
%   memoria(1) = xi[k-1]                 integral previa [rad s]
%   memoria(2) = e_theta[k-1]            error previo [rad]
%   memoria(3) = omega_hat[k-1]          velocidad previa [rad/s]
%   memoria(4) = domega_hat[k-1]         derivada previa [rad/s^2]
%   memoria(5) = theta_hat[k-1]          posicion previa [rad]
%   memoria(6) = dtheta_hat[k-1]         derivada previa [rad/s]
%
% Al comenzar una llamada se hace una copia de estas memorias. Los calculos
% usan esa copia y las entradas actuales. Al finalizar se escriben los seis
% valores correspondientes a k, que estaran disponibles en la llamada k+1.
%
% Las seis memorias iniciales son cero, como en los Unit Delay originales.
% Tustin se evalua tambien en la primera llamada: con entrada inicial no nula,
% la salida del integrador puede ser no nula en esa primera muestra.
%
% reset=0: funcionamiento normal.
% reset~=0: borrar las seis memorias ANTES de calcular la muestra actual.
% Para reiniciar una sola vez, aplicar un pulso de una muestra. Mantener reset
% activo impide acumular estados entre llamadas.
%
% En MATLAB, "clear controlador_digital" borra las memorias de la funcion
% ejecutada directamente. No es el mecanismo de reinicio de un bloque
% compilado en Simulink: para ese bloque se utiliza la entrada reset.

%% 11. Ejemplo de una llamada con UNA sola salida
% Estas muestras sinteticas ilustran la interfaz, no simulan una trayectoria
% ni demuestran seguimiento o cumplimiento de limites fisicos.
% reset=1 hace que este ejemplo no dependa de llamadas anteriores en MATLAB.
theta_ref_ls = 0.001;        % [rad motor]
omega_ref_ls = 0;            % [rad/s motor]
theta_ls = 0;                % [rad motor], medicion
iabc_ls = zeros(3,1);        % [A], mediciones
temperatura_ls = 20;         % [grados Celsius], medicion
resistencia_dinamica_ls = 1;
temperatura_ref_ls = 20;     % [grados Celsius]
reset_ls = 1;

% Al pedir solo el primer resultado, MATLAB devuelve exclusivamente vabc.
vabc_ls = controlador_digital(theta_ref_ls, omega_ref_ls, theta_ls, ...
    iabc_ls, temperatura_ls, resistencia_dinamica_ls, temperatura_ref_ls, ...
    reset_ls, p_ls);
disp(table(["Va*";"Vb*";"Vc*"],vabc_ls, ...
    'VariableNames',{'Consigna','Valor_V'}));

%% 12. Diagnosticos: observar sin agregar acciones sobre la planta
% Se repite LA MISMA muestra con reset=1 para obtener sus diagnosticos sin
% avanzar accidentalmente otro periodo respecto del ejemplo anterior.
[vabc_diag_ls, vdq0_ls, torque_mov_ls, omega_hat_ls, theta_hat_ls, ...
    idq0_ls, iq_ref_ls, Rs_ls] = controlador_digital( ...
    theta_ref_ls, omega_ref_ls, theta_ls, iabc_ls, temperatura_ls, ...
    resistencia_dinamica_ls, temperatura_ref_ls, 1, p_ls);
assert(isequal(vabc_ls,vabc_diag_ls), 'Las ordenes del mismo ejemplo deben coincidir.');
diagnosticos_ls = struct('vdq0',vdq0_ls,'torque_mov',torque_mov_ls, ...
    'omega_hat',omega_hat_ls,'theta_hat',theta_hat_ls,'idq0',idq0_ls, ...
    'iq_ref',iq_ref_ls,'Rs',Rs_ls);
disp(diagnosticos_ls);
clear controlador_digital
% Este clear deja limpia la instancia usada por los ejemplos de MATLAB.

%% 13. Interfaz de Simulink con un solo puerto de salida
% Si se desea mostrar SOLO el puerto vabc en un MATLAB Function, se puede
% utilizar la siguiente funcion envolvente. Es un ejemplo de codigo para
% pegar en el bloque; se deja comentado para no crear otra implementacion
% ni alterar los modelos existentes desde este script explicativo.
%
% function vabc = fcn(theta_ref,omega_ref,theta,iabc,temperatura, ...
%     resistencia_dinamica,temperatura_ref,reset,p_control)
% %#codegen
% vabc = controlador_digital(theta_ref,omega_ref,theta,iabc,temperatura, ...
%     resistencia_dinamica,temperatura_ref,reset,p_control);
% end
%
% Configuracion del bloque:
% - p_control: Scope = Parameter (estructura, no puerto de senal).
% - Update method = Discrete; Sample time = Ts.
% - iabc: dimension [3 1]. vabc: dimension [3 1].
% - controlador_digital.m y sus utilidades deben estar en el path.
% - Ejecutar exactamente una vez por Ts, con entradas de sensores muestreadas.
% - Conectar vabc al inversor; convertir a bus Vabc solo si esa interfaz lo exige.
%
% En el modelo ya generado se conservan puertos de diagnostico para poder
% validar. Estan terminados o destinados al registro; no actuan sobre la planta.
% Este ejemplo de envolvente oculta esos puertos sin cambiar las ecuaciones.

%% 14. Orden completo de ejecucion de una muestra
% 1. Leer las muestras de referencias, posicion, corrientes y temperatura.
% 2. Copiar las memorias previas; reiniciarlas si corresponde.
% 3. Actualizar la integral del error de posicion por Tustin.
% 4. Resolver simultaneamente observador y PID de movimiento.
% 5. Transformar las corrientes medidas mediante Park directa.
% 6. Seleccionar la temperatura de compensacion y calcular Rs.
% 7. Convertir torque a Iq_ref, agregando friccion y gravedad.
% 8. Evaluar los tres reguladores P de corriente.
% 9. Agregar las compensaciones electricas no lineales.
% 10. Aplicar Park inversa y entregar vabc al inversor.
% 11. Guardar las seis memorias actuales para la siguiente muestra.
%
% No se guardan muestras en las subfunciones: la persistencia se centraliza
% en la funcion principal para evitar dobles actualizaciones o mezclar k y k-1.

%% 15. Evidencia de validacion disponible y sus limites
% Este apartado LEE los resultados existentes; no ejecuta otra simulacion.
% El banco de equivalencia aplica las mismas entradas al codigo y a los tres
% subsistemas originales. Tambien verifica reset, funcion MATLAB vs bloque
% compilado y una ejecucion integrada corta con planta, sensores e inversor.
archivo_resultados_ls = fullfile(carpeta_ls,'resultados', ...
    'validacion_controlador_digital.json');
if isfile(archivo_resultados_ls)
    validacion_ls = jsondecode(fileread(archivo_resultados_ls));
    disp(validacion_ls.comparaciones);
    fprintf('Ts de la validacion guardada: %.9g s; muestras: %d\n', ...
        validacion_ls.Ts, validacion_ls.numero_muestras);
    fprintf('Duracion integrada guardada: %.9g s\n', validacion_ls.integracion.tiempo_final);
    if abs(validacion_ls.Ts-p_ls.Ts)>eps(max(validacion_ls.Ts,p_ls.Ts))
        warning('El Ts actual difiere del usado en la validacion guardada.');
    end
else
    disp('No hay resultados guardados. Para generarlos: validar_controlador_digital');
end
% Los resultados guardados no se actualizan al cambiar codigo o parametros.
% Para repetir el banco de forma explicita:
%     resultados = validar_controlador_digital;
%
% La equivalencia numerica del controlador no demuestra por si sola que el
% accionamiento cumpla limites de corriente, tension, torque o temperatura.
% Esas verificaciones requieren los ensayos de la cascada completa.
