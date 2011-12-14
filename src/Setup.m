%Modelling and Simulating Social Systems
%Project: Pedestrian Dynamics, 
%Train Jamming by Marcel Marti, Thomas Meier, Katja Briner
%
%file Setup.m

%************************************************************************%
%   About the Positioning problem:                                       %
%                                                                        %
%   First, the y axis start at the top with index 1 and is directed      %
%   downwards with increasing inidces.                                   %
%                                                                        %
%   y                                                                    %
%   |                                                                    %
%   |                                                                    %
%   |                                                                    %
%   |                                                                    %
%   v                                                                    %
%   --------------------------------------> x                            %
%                                                                        %
%   This results in the following problems:                              %
%                                                                        %
%   1.  Map Matrices must be accessed like this: Map(y, x).              %
%   2.  Positions must be accessed like this Position(1) = x,            %
%       Position(2) = y.                                                 %
%************************************************************************%

clear all;
clc

%   Load a situation
[Map, Layers]       =   loadSituation;
Vectorfields        =   preprocessSituation(Map, Layers);
[m, n, nGroups]     =   size(Layers);

%   Define variables neede for the simulation.
T                   =   200;
dt                  =   0.1;
Lambda              =   0.5;
ExitRadius          =   1;
pInfArea            =   1.5;
sInfArea            =   15;
wInfArea            =   1;
nPassengers         =   40;
nTotalPassengers    =   nPassengers * nGroups;
fField              =   20;
fForceStretch       =   5;
spawnSecurityFactor =   1.5;

%************************************************************************%
%   Default Values:                                                      %
%                                                                        %       
%   Change these values to adjust default behaviour.                     %
%************************************************************************%
Defaults.Interactionstrength.Physical   =   20;
Defaults.Interactionstrength.Social     =   40;
Defaults.Interactionstrength.Wall       =   60;
Defaults.Interactionrange.Physical      =   pInfArea;
Defaults.Interactionrange.Social        =   sInfArea;
Defaults.Interactionrange.Wall          =   wInfArea;
Defaults.Weight.Minimum                 =   50;
Defaults.Weight.Maximum                 =   120;
Defaults.Weight.Heavy                   =   1e10;
Defaults.Radius.Minimum                 =   1;
Defaults.Radius.Maximum                 =   4;
%************************************************************************%
%   Explanation:                                                         %
%                                                                        %
%   The interactionstrength is a factor which influences the forces      %
%   directly. A bigger interactionstrength means, that the specific      %
%   force will be increased by that factor.                              %
%                                                                        %
%   The interactionrange is in the divisor of the exponential quotient   %
%   in the specified forces. A bigger interactionrange flattens the      %
%   increase of the resulting force. In the same distance, the resulting %
%   is smaller the higher the interactionrange.                          %
%************************************************************************%

%   Description of the group array format:
%   =====================================================================
%   
%   Field Name  |   Description
%   ---------------------------------------------------------------------
%   Starts      |   Stores every starting point of the group.
%   Ends        |   Stores every target point of the group.
%   isFinished  |   'true', if every passenger of that group has reached
%               |   a target point, 'false' else.
%   nSpawned    |   The number of passengers of that group that have
%               |   allready started walking.
%   pIndex      |   Index in the passenger array where the group starts.
Groups(:).isFinished    =   0;
Groups(:).nSpawned      =   0;

%   Extract every start and end from the k layers.
Groups(nGroups).Starts(1).Position  = [0; 0];
Groups(nGroups).Ends(1).Position    = [0; 0];

%   Count exits and spawns.
nSpawns = 0;
nExits = 0;

for i = 1:nGroups,
    Layer = Layers(:,:,i);
    [StartRow,  StartCol,   V] = find(Layer == 2);
    [EndRow,    EndCol,     V] = find(Layer == Inf);
    nStarts = length(StartRow);
    nSpawns = nSpawns + nStarts;
    nEnds   = length(EndRow);
    nExits = nExits + nEnds;
    Groups(i).Starts(nStarts).Position       = [0; 0];
    Groups(i).Ends(nEnds).Position           = [0; 0];
    %   Convert Matrix to structure array.
    for j = 1:nStarts,
        Groups(i).Starts(j).Position = [StartCol(j); StartRow(j)];
    end
    for j = 1:nEnds,
        Groups(i).Ends(j).Position   = [EndCol(j); EndRow(j)];
    end
    %   Set starting index.
    Groups(i).pIndex = (i - 1)*nPassengers + 1;
end

%   Description of the wall array format:
%   =====================================================================
%
%   Field Name  |   Description
%   ---------------------------------------------------------------------
%   Position    |   The position of the wall element.
%   Weight      |   The weight of the wall element.
%   Unneeded    |   'true' if the wall element is unneeded, 'false' else.
[WallRow, WallCol, V] = find(Map == 0);
nWalls = length(WallRow);

Walls(nWalls).Position      =   [0;     0];
Walls(nWalls).Weight        =   Defaults.Weight.Heavy;
Walls(nWalls).Unneeded      =   0;

for i = 1:nWalls,
    Walls(i).Position       =   [WallCol(i); WallRow(i)];
    Walls(i).Weight         =   Defaults.Weight.Heavy;
    Walls(i).Unneeded       =   0;
end

%   Extract unneeded walls:
%
%   We can be sure, that this case can be extracted:
%   x W x
%   W t W
%   x W x
%   
%   Where an 'x' means that it does not matter if there is a wall or not, 
%   'W' indicates a wall element, and 't' is the target wall element we
%   need to extract.
%
%   Yes, I know I could've extracted the walls in the upper loop, but this
%   way it looks cleaner for the eye. Also, since we are in the setup
%   phase, performance is not THAT important. You can cut the contents of
%   this loop into the upper loop if you want.
for i = 1:nWalls,
    x = Walls(i).Position(1);
    y = Walls(i).Position(2);
    if y == 1 || x == 1 || y == m || x == n,
        continue;
    end
    if Map(y - 1, x) == 0 && Map(y + 1, x) == 0 && Map(y, x - 1) == 0 && Map(y, x + 1) == 0,
        Walls(i).Unneeded = 1;
    end 
end
%   The unneeded marker is used, because we would not extract every
%   unneeded wall correctly if we deleted a unneeded wall directly.

[t, order] = sort([Walls.Unneeded], 'descend');
Walls = Walls(order);
Walls = Walls(find([Walls.Unneeded] == 0));
nWalls = length(Walls);

%   Description of the passenger array format:
%   =====================================================================
%
%   Field Name  |   Description
%   ---------------------------------------------------------------------
%   Position    |   2x1 - Vector containing the actual position.
%   OldPosition |   2x1 - Vector containing the previous position.
%   Weight      |   Positive scalar value indicating the passenger's
%               |   weight.
%   Aggression  |   The aggression is a scalar value indicating how much
%               |   passenger will insist on following his shortest path.
%   Finished    |   Either 'true', if the passenger has reached its target,
%               |   or 'false', if not.
%   Started     |   Either 'true', if the passenger is walking or 'false',
%               |   if the passenger is still waiting.
%   FieldForce  |   2x1 - Vector indicating the force applied to the 
%               |   passenger by its force field.
%   SocialForce |   2x1 - Vector indicating the social force applied to the
%               |   passenger.
%   RejectForce |   2x1 - Vector indicating the force applied to the
%               |   passenger by other passengers.
%   WallForce   |   2x1 - Vector indicating the force applied to the 
%               |   passenger by wall elements.
%   TotalForce  |   2y1 - Vector indicating the total force applied to the
%               |   passenger.
%   Group       |   Scalar value, 0 < Group <= k, indicating the group to 
%               |   which the passengers belongs.
%
%   Additionally the passenger contains information about force strengths
%   and ranges:
%
%   'Interactionstrength' is a structure containing:
%       -   Physical
%       -   Social
%       -   Wall
%       -   Aggression
%   'Interactionrange' is a structure containing:
%       -   Physical
%       -   Social
%       -   Wall
%       -   Aggression
%
%   Additional explanation to the aggression level:
%
%   The higher the aggression level of a passenger, the more he pushes
%   other passengers away from himself.

%   Initialize last passenger.
Passengers(nTotalPassengers).Position     =   [0;     0];
Passengers(nTotalPassengers).OldPosition  =   [eps;   0];
Passengers(nTotalPassengers).Finished     =   0;
Passengers(nTotalPassengers).Started      =   0;
Passengers(nTotalPassengers).Weight       =   0;
Passengers(nTotalPassengers).FieldForce   =   [0;     0];
Passengers(nTotalPassengers).SocialForce  =   [0;     0];
Passengers(nTotalPassengers).RejectForce  =   [0;     0];
Passengers(nTotalPassengers).WallForce    =   [0;     0];
Passengers(nTotalPassengers).TotalForce   =   [0;     0];
Passengers(nTotalPassengers).Group        =   0;
Passengers(nTotalPassengers).Radius       =   0;
Passengers(nTotalPassengers).Aggression   =   0;

for i = 1:nTotalPassengers,
    %   Create random weight for every passenger.
    Passengers(i).Weight    =   unidrnd(Defaults.Weight.Maximum - Defaults.Weight.Minimum) + Defaults.Weight.Minimum;
    %   Determine group for every passenger.
    Passengers(i).Group     =   mod(i, nGroups) + 1;
    %   Determine random Radius
    Passengers(i).Radius    =   unidrnd(Defaults.Radius.Maximum - Defaults.Radius.Minimum) + Defaults.Radius.Minimum;
    %   Determine random aggression for every passenger.
    Passengers(i).Aggression   =    unidrnd(30);
    %   Initialize every field.
    Passengers(i).Position     =   [0;     0];
    Passengers(i).OldPosition  =   [eps;   0];
    Passengers(i).Finished     =   0;
    Passengers(i).Started      =   0;
    Passengers(i).FieldForce   =   [0;     0];
    Passengers(i).SocialForce  =   [0;     0];
    Passengers(i).RejectForce  =   [0;     0];
    Passengers(i).WallForce    =   [0;     0];
    Passengers(i).TotalForce   =   [0;     0];

    Passengers(i).Interactionstrength.Physical     =   Defaults.Interactionstrength.Physical;
    Passengers(i).Interactionstrength.Social       =   Defaults.Interactionstrength.Social;
    Passengers(i).Interactionstrength.Wall         =   Defaults.Interactionstrength.Wall;
    Passengers(i).Interactionrange.Physical        =   Defaults.Interactionrange.Physical;
    Passengers(i).Interactionrange.Social          =   Defaults.Interactionrange.Social;
    Passengers(i).Interactionrange.Wall            =   Defaults.Interactionrange.Wall;
end

%   Find the maximum radius for every group.
Spawns = getSpawns(Passengers, Groups, Walls);
for i = 1:nGroups,
    Starts = Spawns(i).Starts;
    MaxRadius = max(Starts);
    if MaxRadius > Defaults.Radius.Maximum,
        MaxRadius = Defaults.Radius.Maximum;
    end
    Groups(i).MaxRadius = MaxRadius;
    if Groups(i).MaxRadius <= Defaults.Radius.Minimum,
        clear all;
        error('Maximum Radius is smaller then default minimum radius. Change map please.');
    end
end

%   Give every passenger a valid radius.
for i = 1:nTotalPassengers,
    Passengers(i).Radius = unidrnd(Groups(Passengers(i).Group).MaxRadius - Defaults.Radius.Minimum) + Defaults.Radius.Minimum;
end

%   Sort accordng to group index.
[t, order] = sort([Passengers.Group]);
Passengers = Passengers(order);

%   Clear out trash.
clear V Layer x y t nStarts nEnds order Defaults StartRow StartCol EndRow EndCol WallCol WallRow i j Starts MaxRadius Spawns;