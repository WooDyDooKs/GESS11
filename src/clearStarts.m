function [Cleared] = clearStarts(Layers, Which)
%clearStars:    Clear out all the starts in the given layer.
%               Starts have the code 2, which will be replaces by the free
%               space code, 1.
%              
%   If no layer is specified, the starts in all layers will be cleared out.
if nargin == 1,
    %Clear all layer starts.
    starts = find(Layers == 2);
    Layers(starts) = 1;
else
    %only clear the ones in the specified layer.
    Layer = Layers(:,:,Which);
    starts = find(Layer == 2);
    Layer(starts) = 1;
    Layers(:,:,Which) = Layer;
end

Cleared = Layers;

end

