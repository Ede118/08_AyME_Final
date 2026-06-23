function [d, q, zero] = park_directa(a, b, c, theta)
    % Transformación de Park Directa
    % Entradas:
    %   a, b, c: Valores trifásicos
    %   theta: Ángulo en radianes
    % Salidas:
    %   d, q, z: Coordenadas en el marco rotatorio
    
    % Constantes
    alpha = 2 * pi / 3; % Desplazamiento angular entre fases
    k = 2 / 3; % Escala para invarianza
    
    % Cálculo de coordenadas d, q, z
    d = k * (a * cos(theta) + b * cos(theta - alpha) + c * cos(theta + alpha));
    q = k * (a * sin(theta) + b * sin(theta - alpha) + c * sin(theta + alpha));
    zero = (1 / sqrt(3)) * (a + b + c); % Componente cero
end
