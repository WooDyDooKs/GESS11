function [Vectorfields] = preprocessSituation(Map, Layers)
%preprocessSituation:   Takes a map and k layers and computes the
%                       corresponding vectorfields. Then plots the results.
%
%   The input is a matrix, containing the map, and a three dimensional
%   matrix, containing information about the k layers.
%
%   The output is a four dimensional cell array containing the vector fields
%   for every layer.
[m, n, k] = size(Layers);

Walls = find(Map == 0);
Vectorfields = cell(k, 1);
%For every Layer, compute the vector field and store it in a cell array.
for i = 1:k,
    %Insert the walls into every layer.
    Layer = Layers(:,:,i);
    Layer(Walls) = 0;
    [VFX, VFY] = computeVF(Layer, sprintf('Layer%d.jpg', i));
    VF = zeros(m, n, 2);
    VF(:,:,1) = VFX;
    VF(:,:,2) = VFY;
    Vectorfields{i} = VF;
end


end

