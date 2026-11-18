# Controlador digital en un bloque MATLAB Function

Esta implementacion toma como referencia **el archivo en disco**
`MathWorks/Modelo_Lazo_Cerrado_Discretizado.slx` y conserva sus ganancias,
transformadas, memorias iniciales y conexiones. El controlador contiene el PID
de movimiento, el estimador mecanico y el modulador de torque equivalente.
La planta, sensores, filtro del inversor, saturacion de tension y ZOH permanecen
fuera del codigo, en el modelo de Simulink.

## Uso

Desde la carpeta `MathWorks` de MATLAB:

```matlab
addpath('Controlador_Digital');
p_control = inicializar_controlador_digital;
archivo = crear_modelo_controlador_digital;
open_system(archivo);
open_system('Banco_Controlador_MATLAB_Function');
resultados = validar_controlador_digital;
```

`inicializar_controlador_digital` ejecuta solo la seccion de parametros de
`coeficientes.m`, anterior a las graficas. Si ya se cargaron y ajustaron los
parametros del workspace y se desean conservar esos ajustes, omitir esa llamada:

```matlab
p_control = parametros_controlador_digital;
crear_modelo_controlador_digital;
```

El generador guarda `Modelo_Lazo_Cerrado_MATLAB_Function.slx` en esta carpeta.
No sobrescribe el modelo de referencia. Para regenerar el modelo nuevo, primero
cerrarlo: la funcion rechaza regenerar una copia cargada para proteger ediciones
que puedan existir en memoria.

El archivo de referencia es un **diagrama de subsistema** de Simulink; su copia
conserva ese tipo. Puede usarse en un bloque Subsystem Reference del banco de
comparacion existente, cambiando la referencia de la rama destinada al codigo.
Ademas se genera `Banco_Controlador_MATLAB_Function.slx`, un modelo normal con
los siete puertos de entrada/salida que envuelve el subsistema y permite
compilarlo y simularlo. Sus entradas superiores deben recibir las mismas
senales que el banco de bloques; los valores por defecto no representan
automaticamente el ensayo trapezoidal del informe.

El bloque contiene el texto completo de `controlador_digital.m`, incluidas sus
subfunciones. No usa `evalin`, `coder.extrinsic` ni objetos de Simulink durante
el calculo del control. Las utilidades de inicializacion y construccion si usan
la API de MATLAB/Simulink, pero no forman parte del algoritmo embebido.

## Interfaz del bloque

| Entrada | Significado |
|---|---|
| `theta_ref` | Posicion de referencia en eje motor, rad |
| `omega_ref` | Velocidad de referencia en eje motor, rad/s |
| `theta` | Posicion medida y muestreada en eje motor, rad |
| `iabc` | Vector columna 3x1 de corrientes medidas `[Ia; Ib; Ic]`, A |
| `temperatura` | Temperatura medida del estator, grados Celsius |
| `resistencia_dinamica` | Selector original: usa temperatura medida si es mayor que el umbral del Switch |
| `temperatura_ref` | Temperatura usada para la compensacion fija de resistencia |
| `reset` | Cero en operacion; distinto de cero borra las memorias antes de calcular la muestra actual |

`p_control` es una estructura de **parametro**, no un puerto de senal. Se crea
con los valores actuales de `coeficientes.m` en el workspace. El callback
`InitFcn` del banco generado la actualiza antes de la simulacion usando esos
valores, sin volver a ejecutar ni recalcular las ganancias del script.
Si se instancia solo el subsistema en otro banco, ejecutar
`p_control = parametros_controlador_digital;` al cambiar parametros, o agregar
ese mismo callback al modelo contenedor.
El bloque se configura con actualizacion `Discrete` y `SampleTime = Ts`.
El archivo actual utiliza **Ts = 1e-5 s (10 microsegundos)**; se respeta ese
valor, aunque el texto previo del informe habia propuesto otro candidato.

| Salida | Significado |
|---|---|
| `vabc` | Orden de tension `[Va; Vb; Vc]` antes de filtro/saturacion del inversor |
| `vdq0` | Tension con compensacion NL `[Vd; Vq; V0]`, antes de Park inversa |
| `torque_mov` | Salida del PID de movimiento, N m en eje motor |
| `omega_hat` | Velocidad estimada, rad/s |
| `theta_hat` | Posicion estimada, rad |
| `idq0` | Corrientes medidas transformadas `[Id; Iq; I0]` |
| `iq_ref` | Consigna de corriente q despues de compensaciones mecanicas |
| `Rs` | Resistencia utilizada en la compensacion electrica, ohm |

Las seis ultimas salidas son diagnosticos y terminan en bloques Terminator
en la copia integrada. Se pueden conectar a Scope o registrar para el informe.
Los puertos externos Vabc y Vdq0 conservan sus buses tipados, con campos
Va/Vb/Vc y Vd/Vq/V0, mediante adaptadores. Dentro del bloque de codigo,
ambas salidas son vectores columna de tres componentes.

## Correspondencia con subsistemas

| Subfuncion | Referencia |
|---|---|
| `PID_de_Movimiento` | SID 525, PID Movimiento |
| `Estimador_de_Estado_de_Orden_Reducido` | SID 355; integradores SID 737 y 745 |
| `Modulador_de_Torque_Equivalente` | SID 368 |
| `PID_de_Torque` | SID 483, Modulador y Compensacion de Torque |
| `Lazo_de_Corriente` | SID 382, reguladores P de los ejes d/q/0 |
| `Modulador_de_Tension` | SID 412, compensacion NL electrica |
| `Transformada_Directa_de_Park` | Park Q-axis, PowerInvariant off |
| `Transformada_Inversa_de_Park` | Inverse Park Q-axis, PowerInvariant off |
| `Integrador_Discreto` | SID 690 y misma regla de los otros dos integradores |
| `Calculo_de_Resistencia` | Compensacion termica y Switch SID 522 |

**El modelo no tiene un PID de torque independiente.** La subfuncion
`PID_de_Torque` conserva el nombre solicitado, pero implementa la conversion
algebraica torque/corriente con compensaciones viscosa y gravitatoria del
subsistema original. No agrega ganancias P/I/D ni estados inexistentes.
De igual modo, los lazos de corriente siguen siendo P y no se incorpora
saturacion integral ni limitacion nueva de corriente.

Park usa angulo electrico `Pp*theta`, eje d asociado al seno, eje q al coseno
y componente cero igual al promedio de las tres fases. Es una transformacion
de amplitud invariante: no se utiliza la normalizacion de potencia invariante.

## Memorias y resolucion del lazo PID-observador

Una sola variable persistente almacena seis numeros:

```text
[integral_error; error_posicion_previo;
 omega_previa; derivada_omega_previa;
 theta_estimada_previa; derivada_theta_previa]
```

Los seis valores se inicializan a cero, como los Unit Delay inspeccionados.
La primera muestra tambien se calcula con Tustin: si la entrada inicial es
no nula, el resultado de la integral no se fuerza artificialmente a cero.
Las subfunciones no escriben persistentes: las seis memorias se actualizan
una unica vez, al finalizar cada llamada principal. Mantener reset activado
en varias muestras reinicia antes de CADA una de ellas; para reiniciar una vez,
aplicar un pulso de una muestra.

Hay una realimentacion instantanea entre el PID y el observador porque los
integradores de Tustin dependen de la entrada actual. No basta con llamar
primero al observador usando el torque anterior: eso cambiaria el modelo.
El codigo resuelve conjuntamente las ecuaciones de la muestra actual.

Con `h=Ts/2`, `Tbase=Kp*e+Ki*integral(e)+Kd*omega_ref` y `T=Tbase-Kd*omega_hat`:

```text
a = 1 + h*K_et
c = (theta_hat_previa + h*(K_et*theta + derivada_theta_previa))/a

omega_hat = (omega_previa
             + h*(Tbase/J_eq + K_ew*(theta-c) + derivada_omega_previa))
            / (1 + h*Kd/J_eq + h^2*K_ew/a)

theta_hat = c + h*omega_hat/a
```

Despues se calculan el torque actual y las dos derivadas a almacenar. Esta
resolucion conserva las realimentaciones simultaneas y evita introducir
retardos o un solver algebraico iterativo dentro del bloque MATLAB Function.

## Validacion reproducible

`validar_controlador_digital` construye un banco temporal que copia los tres
subsistemas originales desde el archivo de referencia y les aplica las mismas
2001 muestras que al MATLAB Function. Compara vabc, vdq0, torque, velocidad
estimada y posicion estimada. El banco incluye entrada inicial no nula,
cambio de posicion, componentes de corriente no equilibradas, secuencia cero,
temperatura variable y conmutacion de resistencia fija/dinamica.

Tambien compara la funcion ejecutada directamente en MATLAB con el bloque
compilado y verifica el reinicio de las memorias. Los resultados se escriben
en `resultados/validacion_controlador_digital.json` y `.mat`.

Finalmente ejecuta una prueba corta de 500 periodos con la planta, sensores e
inversor, usando una referencia suave de pequena amplitud y verificando que
la simulacion termine con salidas finitas. Con Ts=1e-5 s, esta prueba dura
0,005 s simulados; no representa el ensayo trapezoidal completo del informe.

Esta prueba comprueba la equivalencia del controlador con los subsistemas
de bloques para entradas identicas. No certifica cumplimiento de limites
fisicos, rechazo de carga, robustez ni equivalencia de cualquier simulacion
cerrada de larga duracion. El modelo integrado conserva las no idealidades
y permite realizar esos ensayos con los mismos estimulos del banco original.

Resultado obtenido con MATLAB/Simulink R2026b y Ts=1e-5 s:

| Magnitud | Diferencia absoluta maxima codigo/bloques |
|---|---:|
| Orden de tension abc | 2,43e-7 V |
| Tension dq0 | 2,68e-7 V |
| Torque de movimiento | 6,67e-10 N m |
| Velocidad estimada | 7,27e-9 rad/s |
| Posicion estimada | 2,35e-12 rad |

La funcion MATLAB y el MATLAB Function devolvieron resultados identicos en
el banco; el reinicio paso la prueba. La simulacion integrada termino sus
0,005 s con salidas finitas. El banco de bloques original aviso de un lazo
algebraico, coherente con la realimentacion simultanea PID-observador; el
codigo resuelve ese lazo analiticamente. Las pequenas diferencias numericas
son compatibles con la distinta resolucion de ese sistema algebraico y el
redondeo; no se afirma identidad bit a bit con el solver de bloques.

Referencias de la API usada: [MATLAB Function](https://www.mathworks.com/help/simulink/slref/matlabfunction.html),
[variables persistentes](https://www.mathworks.com/help/stateflow/ug/initialize-persistent-variables.html)
y [Stateflow.EMChart](https://www.mathworks.com/help/stateflow/api/stateflow.emchart.html).
