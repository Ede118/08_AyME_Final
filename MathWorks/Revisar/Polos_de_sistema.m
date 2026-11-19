clear s1 s2 z;
i=1;

% 1. Tu bucle original de simulación
for T=20:20:140
    R(i,1)=R_sREF*(1+alpha_Cu*(T-T_sREF));
    a=2*(19.78*10^(-6))*L_q;% usando Jeq=19,78*10^-6 con Jl minimo=0.0833
    b=2*((19.78*10^(-6))*R(i,1)+b_eq*L_q);% usando Jeq=19,78*10^-6 con Jl minimo=0.0833
    c=2*b_eq*R(i,1)+3*(Pp*lambda)^2;
    
    s1(i,1)=(-b+sqrt(b^2-4*a*c))/(2*a)
    s2(i,1)=(-b-sqrt(b^2-4*a*c))/(2*a)
    z(i,1)=-R(i,1)/L_q;
    i=i+1;
end
s3=0;
s1
s2
z
R
%% --- SECCIÓN DE GRÁFICO ---
figure;

% Graficar los puntos originales (Polos y Ceros)
plot(real(s1), imag(s1), 'bx', 'MarkerSize', 10, 'LineWidth', 2); hold on;
plot(real(s2), imag(s2), 'rx', 'MarkerSize', 10, 'LineWidth', 2);
plot(real(z), imag(z), 'go', 'MarkerSize', 10, 'LineWidth', 2);
plot(real(s3), imag(s3), 'k*', 'MarkerSize', 12, 'LineWidth', 2);

%% --- AÑADIR FLECHAS DE DIRECCIÓN (De menor T a mayor T) ---

% Calculamos la dirección (derivada/diferencia entre puntos consecutivos)
% Usamos [1:end-1] porque el último punto no tiene un "siguiente" hacia el cual apuntar.
u_s1 = diff(real(s1)); v_s1 = diff(imag(s1));
u_s2 = diff(real(s2)); v_s2 = diff(imag(s2));
u_z  = diff(real(z));  v_z  = diff(imag(z));

% Dibujamos las flechas con quiver (se escalan a 0 para mantener su tamaño real)
quiver(real(s1(1:end-1)), imag(s1(1:end-1)), u_s1, v_s1, 0, 'b', 'LineWidth', 1.5, 'MaxHeadSize', 0.5);
quiver(real(s2(1:end-1)), imag(s2(1:end-1)), u_s2, v_s2, 0, 'r', 'LineWidth', 1.5, 'MaxHeadSize', 0.5);
quiver(real(z(1:end-1)),  imag(z(1:end-1)),  u_z,  v_z,  0, 'g', 'LineWidth', 1.5, 'MaxHeadSize', 0.5);

%% --- NOTAS EN TEXTO PARA ACLARAR ---
% Coloca un texto indicando dónde arranca y termina la temperatura
text(real(s1(1)), imag(s1(1))+5, 'T=20°', 'Color', 'b', 'FontWeight', 'bold');
text(real(s1(end)), imag(s1(end))+5, 'T=140°', 'Color', 'b', 'FontWeight', 'bold');

%% --- ESTILO DEL GRÁFICO ---
grid on;
ax = gca; 
ax.XAxisLocation = 'origin'; 
ax.YAxisLocation = 'origin'; 

xlabel('Eje Real (\sigma)', 'FontSize', 12);
ylabel('Eje Imaginario (j\omega)', 'FontSize', 12);
title('Lugar de Raíces y Polos (Evolución con la Temperatura)', 'FontSize', 14);
legend('Polos s1', 'Polos s2', 'Raíces z', 's3 (Origen)', 'Dirección T\uparrow', 'Location', 'best');