function [Entries] = findColor(Image, R, G, B)
%findColor: Finds all entries in an image of the specified RGB color.
[m,n,t] = size(Image);
if R > 255 | R < 0 | G > 255 | G < 0 | B > 255 | B < 0 | t ~= 3,
    error('Input error in function findColor');
end

search_px = [R;G;B];

Entries = [];
for i = 1:m,
    for j = 1:n,
        px = [Image(i,j,1); Image(i,j,2); Image(i,j,3)];
        if px == search_px,
            Entries = [Entries; i + j*m];
        end
    end
end
end

