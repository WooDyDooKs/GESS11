%   The acutal simulation of the train entrance.
%   
%   First runs the setup script which loads the data needed by the
%   simulation to run, then runs the simulation for a given time.
%
%   Variables that need to be defined are:
%
%   Variable                |   Description
%   ----------------------------------------------------------------------
%   Map                     |   Map, holding information about walls and
%                           |   special zones.
%   Layers                  |   Contains the initial information of the k 
%                           |   Layers loaded in the setup phase.
%   Vectorfields            |   Contains the k vectorfields used to bring
%                           |   passengers on their shortest path.
%   m                       |   The height of the map.
%   n                       |   The width of the map.
%   Lambda                  |   This scalar factor influences how much the
%                           |   angle between the movement vector of a 
%                           |   passenger a and the normalized vector between 
%                           |   a and another passenger b.
%   nGroups                 |   The number of groups.
%   T                       |   The duration of the simulation.
%   dt                      |   A timestep in the simulation.
%   pInfArea                |   The physical influence area for passengers.
%   wInfArea                |   The wall influence area.
%   sInfArea                |   The social influence area for passengers.
%   nPassengers             |   The number of passengers in each group.
%   nTotalPassengers        |   The total number of passengers.
%   eps                     |   The predefined epsilon value.
%   Passengers              |   Structure holding information about every
%                           |   passenger. The detailed structure is
%                           |   explained in Setup.m.
%   Groups                  |   Structure holding information about every
%                           |   group.
%   Walls                   |   Structure holding information about every 
%                           |   wall element.

run Setup;

%   Our simulation will run the specified time with a specified frequency.
for t = 1:dt:T,
    
    %   Calculate forces for every passenger.
    for pNo = 1:nTotalPassengers,
        
        %   Check, if the passenger has started.
        if Passengers(pNo).Started == 0,
            %   Check if there is a free slot for him to start.
            Spawns = getSpawns(Passengers, Groups, Walls);
            nStarts = length(Spawns(Passengers(pNo).Group).Starts);
            for sNo = 1:nStarts,
                if Spawns(Passengers(pNo).Group).Starts(sNo) > Passengers(pNo).Radius,
                    %   The passenger can start at this position.
                    Passengers(pNo).Position = Groups(Passengers(pNo).Group).Starts(sNo).Position;
                    Passengers(pNo).OldPosition = Passengers(pNo).Position + [eps; 0];
                    Passengers(pNo).Started = 1;
                    break;
                end
            end
            
            clear nStarts Spawns sNo;
        end
        
        %   Now re-check, if the passenger has started or not finished. If not, stop here.
        if Passsengers(pNo).Started == 0 || Passengers(pNo).Finished == 1,
            continue;
        end
        
        %   From this point on, we can assume the passenger has started and
        %   not finished.
        
        %***************************************************************%
        %                           FORCES                              %                                     
        %***************************************************************%          
        
        %   First, reset forces.
        Passengers(pNo).WallForce   = [0; 0];
        Passengers(pNo).SocialForce = [0; 0];
        Passengers(pNo).FieldForce  = [0; 0];
        Passengers(pNo).RejectForce = [0; 0];
        
        %   1.  Vectorfield force
        %   
        %   This force is used to let the passenger follow its shortest
        %   path. How much the passenger will be pushed towards its
        %   shortest path, depends on the aggression level of the
        %   passenger.
        row = int16(Passenger(pNo).Position(2));
        col = int16(Passenger(pNo).Position(1));
        
        Passengers(pNo).FieldForce = Vectorfields(row, col, Passengers(pNo).Group) * Passsengers(pNo).Aggression;
        
        clear row col;
        
        %   2.  Wall force.
        %   
        %   The Wall force is the force applied to a passenger by a wall
        %   element in his range. The range is determined by 'wInfArea'. 
        %   The force is stronger, the nearer the passenger gets to the
        %   wall.
        for wNo = 1:nWalls,
            Distance = norm(Passengers(pNo).Position - Walls(wNo).Position);
            %   Check if the wall element is in the influence area of the
            %   passenger.
            if Distance < Passengers(pNo).Radius + wInfArea,
                WallIntStrength = Passengers(pNo).Interactionstrength.Wall;
                WallIntRange    = Passengers(pNo).Interactionrange.Wall;
                %   Now we need the direction of the passenger to be
                %   pushed.
                Direction = Passenger(pNo).Position - Walls(wNo).Position;
                if Direction(1) > Direction(2),
                    Direction(2) = 0;
                elseif Direction(2) > Direction(1),
                    Direction(1) = 0;
                end
                %   Normalize direction vector.
                Driection = Direction ./ norm(Direction);
                %   Now we need the weight of the force.
                Weight = WallIntStrength * exp( -Distance/WallIntRange );
                Passengers(pNo).WallForce = Passengers(pNo).Wallforce + Weight * Direction;
            end
        end
        clear Direction Distance Weight WallIntStrength WallIntRange;
        
        %   3.  Passenger physical force.
        %
        %   The passenger physical force is the force which prevents
        %   passengers from running through each other. The range is
        %   determined by 'pInfArea'. The force is stronger, the nearer
        %   passengers get to each other. Additionally, aggressive
        %   passengers push less aggressive passengers away far stronger.
        %
        %   4.  Passenger social force.
        %
        %   The passenger social force is the force which influences the
        %   behaviour of a passenger. 
        for opNo = 1:nTotalPassengers,
            %   We don't want to influence ourselves. This would end in
            %   anarchy. Chaos. Total destruction. We just don't want that.
            %   Also we don't want to check with inactive passengers.
            if opNo == pNo || Passengers(opNo).Started == 0 || Passengers(opNo).Finished == 1, continue; end
            
            Distance = norm(Passengers(pNo).Position - Passenger(opNo).Position);
            if Distance < pInfArea + Passengers(pNo).Radius + Passengers(opNo).Radius,

                %   Now calculate the physical force.
                RadiusA = Passengers(pNo).Radius;
                RadiusB = Passengers(opNo).Radius;
                AggressionB = Passengers(opNo).Aggression;
                ForceStrength = Passengers(pNo).Interactionstrength.Physical;
                ForceRange = Passengers(pNo).Interactionrange.Physical;
                Direction = (Passengers(pNo).Position - Passengers(opNo).Position)./Distance;
                
                Passengers(pNo).RejectForce = Passenger(pNo).RejectForce + (AggressionB + ForceStrength)*exp((RadiusA + RadiusB - Distance)/ForceRange) * Direction;
            end
        end
        
        
        
    end
    
end