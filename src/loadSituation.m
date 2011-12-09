function [Map, Layers] = loadSituation()
%loadSituation: Conversion of k + 1 bmp - images to a map - matrix and a
%               three  dimensional matrix consisting of k two dimensional
%               matrices representing the given subsequent bmp - images.
%
%   Only the following colors with their interpretations are allowed:
%
%   Color               Hex         Decsription
%   White               FFFFFF      Free space. Passengers can free walk in
%                                   white areas.
%   Black               000000      Wall.
%   Red                 FF0000      Target for a group.
%   Green               0000FF      Start for a group.
%   Yellow              FFFF00      Slow areas (stairs etc. ).
%
%   The output map - matrix contains:
%   0 => Wall, 1 => Free space, 2 => slow area
%
%   The output layer - matrices contain:
%   1 => Free space, 2 => starting point, Inf => ending point


%Open text file containing all situation files.
[filename, pathname] = uigetfile('*.txt', 'Please select input text file');
f = fopen([pathname,filename]);
%Fetch first line.
tline = fgetl(f);
%Parse every line.
S = {};
i = 1;
while ischar(tline)
    S{i, 1} = [pathname,tline];
    i = i + 1;
    tline = fgetl(f);
end
fclose(f);
nFiles = length(S);
nLayers = nFiles - 1;


%Every file path is now stored in S.
%The first file S{1,1} is considered to be the map.

%Generate map.
rawMap = imread(S{1,1});
walls = findColor(rawMap, 0, 0, 0);
space = findColor(rawMap, 255, 255, 255);
slow  = findColor(rawMap, 255, 255, 0);

[lines, columns, depth] = size(rawMap);
if (length(walls) + length(space) + length(slow)) ~= lines*columns,
    error('Invalid input map.');
end

Map = zeros(lines, columns);
Map(walls) = 0;
Map(space) = 1;
Map(slow)  = 2;

%Add a wall around the map.
Map(:, 1)       = 0;
Map(1, :)       = 0;
Map(:, columns) = 0;
Map(lines, :)   = 0;

if nLayers == 0,
    Layers = [];
else
    %Do the same for every layer.
    Layers = zeros(lines, columns, nLayers);
    for i = 2:nFiles,
        rawLayer = imread(S{i,1});
        space  = findColor(rawLayer, 255, 255, 255);
        starts = findColor(rawLayer, 0, 255, 0);
        ends   = findColor(rawLayer, 255, 0, 0);

        if length(space) + length(starts) + length(ends) ~= lines * columns,
            error(['Invalid input layer: Layer ', num2str(i-1)]);
        end

        layer  = zeros(lines, columns);
        layer(space)  = 1;
        layer(starts) = 2;
        layer(ends)   = Inf;

        Layers(:,:,i-1) = layer;
    end
end
end