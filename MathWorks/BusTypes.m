function BusTypes() 
% BUSTYPES initializes a set of bus objects in the MATLAB base workspace 

% Bus object: Vdq0 
clear elems;
elems(1) = Simulink.BusElement;
elems(1).Name = 'Vd';
elems(1).Dimensions = 1;
elems(1).DimensionsMode = 'Fixed';
elems(1).DataType = 'double';
elems(1).Complexity = 'real';
elems(1).Min = [];
elems(1).Max = [];
elems(1).DocUnits = sprintf('V');
elems(1).Description = '';

elems(2) = Simulink.BusElement;
elems(2).Name = 'Vq';
elems(2).Dimensions = 1;
elems(2).DimensionsMode = 'Fixed';
elems(2).DataType = 'double';
elems(2).Complexity = 'real';
elems(2).Min = [];
elems(2).Max = [];
elems(2).DocUnits = sprintf('V');
elems(2).Description = '';

elems(3) = Simulink.BusElement;
elems(3).Name = 'V0';
elems(3).Dimensions = 1;
elems(3).DimensionsMode = 'Fixed';
elems(3).DataType = 'double';
elems(3).Complexity = 'real';
elems(3).Min = [];
elems(3).Max = [];
elems(3).DocUnits = sprintf('V');
elems(3).Description = '';

Vdq0 = Simulink.Bus;
Vdq0.HeaderFile = '';
Vdq0.Description = '';
Vdq0.DataScope = 'Auto';
Vdq0.Alignment = -1;
Vdq0.PreserveElementDimensions = 0;
Vdq0.Elements = elems;
clear elems;
assignin('base','Vdq0', Vdq0);

% Bus object: Vabc 
clear elems;
elems(1) = Simulink.BusElement;
elems(1).Name = 'Va';
elems(1).Dimensions = 1;
elems(1).DimensionsMode = 'Fixed';
elems(1).DataType = 'double';
elems(1).Complexity = 'real';
elems(1).Min = [];
elems(1).Max = [];
elems(1).DocUnits = sprintf('V');
elems(1).Description = '';

elems(2) = Simulink.BusElement;
elems(2).Name = 'Vb';
elems(2).Dimensions = 1;
elems(2).DimensionsMode = 'Fixed';
elems(2).DataType = 'double';
elems(2).Complexity = 'real';
elems(2).Min = [];
elems(2).Max = [];
elems(2).DocUnits = sprintf('V');
elems(2).Description = '';

elems(3) = Simulink.BusElement;
elems(3).Name = 'Vc';
elems(3).Dimensions = 1;
elems(3).DimensionsMode = 'Fixed';
elems(3).DataType = 'double';
elems(3).Complexity = 'real';
elems(3).Min = [];
elems(3).Max = [];
elems(3).DocUnits = sprintf('V');
elems(3).Description = '';

Vabc = Simulink.Bus;
Vabc.HeaderFile = '';
Vabc.Description = '';
Vabc.DataScope = 'Auto';
Vabc.Alignment = -1;
Vabc.PreserveElementDimensions = 0;
Vabc.Elements = elems;
clear elems;
assignin('base','Vabc', Vabc);

% Bus object: Iabc 
clear elems;
elems(1) = Simulink.BusElement;
elems(1).Name = 'Ia';
elems(1).Dimensions = 1;
elems(1).DimensionsMode = 'Fixed';
elems(1).DataType = 'double';
elems(1).Complexity = 'real';
elems(1).Min = [];
elems(1).Max = [];
elems(1).DocUnits = sprintf('A');
elems(1).Description = '';

elems(2) = Simulink.BusElement;
elems(2).Name = 'Ib';
elems(2).Dimensions = 1;
elems(2).DimensionsMode = 'Fixed';
elems(2).DataType = 'double';
elems(2).Complexity = 'real';
elems(2).Min = [];
elems(2).Max = [];
elems(2).DocUnits = sprintf('A');
elems(2).Description = '';

elems(3) = Simulink.BusElement;
elems(3).Name = 'Ic';
elems(3).Dimensions = 1;
elems(3).DimensionsMode = 'Fixed';
elems(3).DataType = 'double';
elems(3).Complexity = 'real';
elems(3).Min = [];
elems(3).Max = [];
elems(3).DocUnits = sprintf('A');
elems(3).Description = '';

Iabc = Simulink.Bus;
Iabc.HeaderFile = '';
Iabc.Description = '';
Iabc.DataScope = 'Auto';
Iabc.Alignment = -1;
Iabc.PreserveElementDimensions = 0;
Iabc.Elements = elems;
clear elems;
assignin('base','Iabc', Iabc);

% Bus object: Idq0 
clear elems;
elems(1) = Simulink.BusElement;
elems(1).Name = 'Id';
elems(1).Dimensions = 1;
elems(1).DimensionsMode = 'Fixed';
elems(1).DataType = 'double';
elems(1).Complexity = 'real';
elems(1).Min = [];
elems(1).Max = [];
elems(1).DocUnits = sprintf('A');
elems(1).Description = '';

elems(2) = Simulink.BusElement;
elems(2).Name = 'Iq';
elems(2).Dimensions = 1;
elems(2).DimensionsMode = 'Fixed';
elems(2).DataType = 'double';
elems(2).Complexity = 'real';
elems(2).Min = [];
elems(2).Max = [];
elems(2).DocUnits = sprintf('A');
elems(2).Description = '';

elems(3) = Simulink.BusElement;
elems(3).Name = 'I0';
elems(3).Dimensions = 1;
elems(3).DimensionsMode = 'Fixed';
elems(3).DataType = 'double';
elems(3).Complexity = 'real';
elems(3).Min = [];
elems(3).Max = [];
elems(3).DocUnits = sprintf('A');
elems(3).Description = '';

Idq0 = Simulink.Bus;
Idq0.HeaderFile = '';
Idq0.Description = '';
Idq0.DataScope = 'Auto';
Idq0.Alignment = -1;
Idq0.PreserveElementDimensions = 0;
Idq0.Elements = elems;
clear elems;
assignin('base','Idq0', Idq0);

