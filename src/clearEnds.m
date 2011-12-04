function [Cleared] = clearEnds(Layers, Which)
%clearStars:    Clear out all the ends in the given layer.
%               ends have the code 3, which will be replaces by the free
%               space code, 1.
%              
%   If no layer is specified, the ends in all layers will be cleared out.
if nargin == 1,
    %Clear all layer starts.
    ends = find(Layers == 3);
    Layers(ends) = 1;
else
    %only clear the ones in the specified layer.
    Layer = Layers(:,:,Which);
    ends = find(Layer == 3);
    Layer(ends) = 1;
    Layers(:,:,Which) = Layer;
end

Cleared = Layers;

end



