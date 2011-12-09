function Spawns = getSpawns(Passengers, Groups, Walls)
%getSpawns:     Returns a structure array of Spawn - entries.
%               A spawn entry consists of the group index, the starting
%               point index and the radius which is available for spawn.
%
%   Inputs are three structure arrays, one containing information about the
%   passengers, the second one containing information about the groups and
%   the last one containing information about the wall elements.
nGroups     = length(Groups);
nWalls      = length(Walls);
nPassengers = length(Passengers);

Spawns(nGroups).Starts      = 0;

%   Check every group.
for i = 1:nGroups,
    %   Check every start of every group.
    l = length(Groups(i).Starts);
    Spawns(i).Starts(l) = 0;
    for j = 1:l,
        
        %   If every passenger position is [0; 0], don't check against
        %   passengers. It would return awkward results.
        checkPassengers = 0;
        if [Passengers.Position] ~= zeros(2, nPassengers),
            checkPassengers = 1;
        end

        %   Check against every passenger.
        Pos = [Passengers.Position] - repmat(Groups(i).Starts(j).Position, 1, nPassengers);
        radius = norm(Pos(:, 1));
        for k = 2:nPassengers,
            t = norm(Pos(:, k));
            if t < radius,
                radius = t;
            end
        end

        %   Check against walls.
        Pos = [Walls.Position] - repmat(Groups(i).Starts(j).Position, 1, nWalls);
        startIndex = 1;
        if checkPassengers,
            radius = norm(Pos(:,1));
            startIndex = 2;
        end
        for k = startIndex:nWalls,
            t = norm(Pos(:, k));
            if t < radius,
                radius = t;
            end
        end
        
        Spawns(i).Starts(j) = radius;
    end
end

end

