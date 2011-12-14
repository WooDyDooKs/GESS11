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
%   fField                  |   The factor applied to the field force.
%   fForceStretch           |   The factor applied to the total force.
%   SpawnSecurityFactor     |   The additional radius for the spawn area.
%   nExits                  |   The number of exits.
%   nSpawns                 |   The number of spawn points.
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

close all;

Movie = avifile('Output.avi', 'compression', 'None');
clf('reset');

%   Our simulation will run the specified time with a specified frequency.
for t = 1:dt:T,
    
    %   Display actual time.
    disp(['dt is ' num2str(t)]);
    
    for pNo = 1:nTotalPassengers,
        %   Check, if the passenger has started.
        if Passengers(pNo).Started == 0,
            %   Check if there is a free slot for him to start.
            Spawns = getSpawns(Passengers, Groups, Walls);
            nStarts = length(Spawns(Passengers(pNo).Group).Starts);
            for sNo = 1:nStarts,
                if Spawns(Passengers(pNo).Group).Starts(sNo) > Passengers(pNo).Radius + spawnSecurityFactor,
                    %   The passenger can start at this position.
                    Passengers(pNo).Position = Groups(Passengers(pNo).Group).Starts(sNo).Position;
                    Position = Passengers(pNo).Position;
                    Passengers(pNo).OldPosition = Passengers(pNo).Position + [(unidrnd(2*1e3)-1e3)/1e6; (unidrnd(2*1e3)-1e3)/1e6];
                    Passengers(pNo).Started = 1;
                    disp('A new passenger has spawned!');
                    break;
                end
            end
            
            clear nStarts Spawns sNo;
        end
    end
    
    %   Calculate forces for every passenger.
    for pNo = 1:nTotalPassengers,
        
        %   Check, if the passenger has started or not finished. If not, stop here.
        if Passengers(pNo).Started == 0 || Passengers(pNo).Finished == 1,
            continue;
        end
         
        %   Check if the passenger has finished.
        Group   = Passengers(pNo).Group;
        Ends    = [Groups(Group).Ends.Position];
        nEnds   = length(Ends(1,:));
        for i = 1:nEnds,
            Direction   = (Passengers(pNo).Position - Ends(:,i));
            Distance    = norm(Direction);
            Direction   = Direction./Distance;

            if Distance < ExitRadius + Passengers(pNo).Radius,
                Passengers(pNo).Finished = 1;
                disp('A passenger has reached its target.');
            end
        end
        
        
        %   Now re-check, if the passenger has started or not finished. If not, stop here.
        if Passengers(pNo).Started == 0 || Passengers(pNo).Finished == 1,
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
        Position = Passengers(pNo).Position;
        row = int16(Position(2));
        col = int16(Position(1));
        
        if row <= 0 || col <= 0 || row > m || col > n,
            error('Passenger walked to an invalid position.');
        end
        
        Field = Vectorfields{Passengers(pNo).Group};
        Passengers(pNo).FieldForce = [Field(row, col, 1); Field(row, col, 2)] * (Passengers(pNo).Aggression + fField);
        
        clear row col Position;
        
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
                Direction = Passengers(pNo).Position - Walls(wNo).Position;
                if Direction(1) > Direction(2),
                    Direction(2) = 0;
                elseif Direction(2) > Direction(1),
                    Direction(1) = 0;
                end
                %   Normalize direction vector.
                Driection = Direction ./ norm(Direction);
                %   Now we need the weight of the force.
                Weight = WallIntStrength * exp( -Distance/WallIntRange );
                Passengers(pNo).WallForce = Passengers(pNo).WallForce + Weight * Direction;
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
            
            Distance = norm(Passengers(pNo).Position - Passengers(opNo).Position);
            if Distance < pInfArea + Passengers(pNo).Radius + Passengers(opNo).Radius,

                %   Now calculate the physical force.
                RadiusA = Passengers(pNo).Radius;
                RadiusB = Passengers(opNo).Radius;
                AggressionA = Passengers(pNo).Aggression;
                AggressionB = Passengers(opNo).Aggression;
                AggressionSummand = AggressionB - AggressionA;
                if AggressionSummand < 0, AggressionSummand = 0; end
                ForceStrength = Passengers(pNo).Interactionstrength.Physical;
                ForceRange = Passengers(pNo).Interactionrange.Physical;
                Direction = (Passengers(pNo).Position - Passengers(opNo).Position)./Distance;
                
                Passengers(pNo).RejectForce = Passengers(pNo).RejectForce...
                    + (AggressionSummand + ForceStrength)...
                    *exp((RadiusA + RadiusB - Distance)/ForceRange) * Direction;
                %   Clear trash.
                clear RadiusA RadiusB AggressionB ForceStrength ForceRange Direction;
            end
            
            
            if Distance < sInfArea + Passengers(pNo).Radius + Passengers(opNo).Radius;
                
                %   Debug Stuff
                Position = Passengers(pNo).Position;
                OldPosition = Passengers(pNo).OldPosition;
                
                %   Now calculate the social force
                Direction = (Passengers(pNo).Position - Passengers(opNo).Position)./Distance;
                Move = (Passengers(pNo).Position - Passengers(pNo).OldPosition);
                MoveNorm = norm(Move);
                Move = Move./MoveNorm;
                Phi = acos(dot(Direction, Move));
                
                Passengers(pNo).SocialForce = Passengers(pNo).SocialForce...
                    + ((Lambda + (1 - Lambda)*(1 + cos(Phi)))/2)...
                    *Passengers(pNo).Interactionstrength.Social...
                    *exp(1 - Distance/Passengers(pNo).Interactionrange.Social)*Direction;
                
                %   Clear trash.
                clear Direction Move MoveNorm Move Phi;
            end
        end
        
        %   Acculmulate forces
        SocialForce         =   Passengers(pNo).SocialForce;
        WallForce           =   Passengers(pNo).WallForce;
        RejectForce         =   Passengers(pNo).RejectForce;
        FieldForce          =   Passengers(pNo).FieldForce;
        Passengers(pNo).TotalForce          =   WallForce + FieldForce + SocialForce + RejectForce;
        Passengers(pNo).TotalForce          =   Passengers(pNo).TotalForce.*fForceStretch;
        
        %   Clear trash.
        clear SocialForce WallForce RejectForce FieldForce Direction Distance nEnds Ends Group;
    end
    
    %   Calculate new Position
    for pNo = 1:nTotalPassengers,
         %   If the passenger has not started or finished, stop here.
        if Passengers(pNo).Started == 0 || Passengers(pNo).Finished == 1,
            continue;
        end
        
        %   Else, calculate new Position.
        
        %   F = m*a => a = F/m
        Weight              =   Passengers(pNo).Weight;
        Acceleration        =   Passengers(pNo).TotalForce/Weight;
        
        %   Store old position.
        Passengers(pNo).OldPosition     =   Passengers(pNo).Position;
        OldPosition                     =   Passengers(pNo).OldPosition;
        
        %   Calculate new position.
        Passengers(pNo).Position        =   dt*Acceleration + OldPosition;
        Position                        =   Passengers(pNo).Position;
    end
    
    Frame = figure('Visible', 'Off', 'units', 'normalized', 'outerposition', [0 0 1 1]);
    
    %   Plot this shit.
    %   Plot walls.
    WallPositions       = [Walls.Position];
    plot(WallPositions(1, :), m - WallPositions(2, :) + 1, '.k', 'MarkerSize', 20);
    
    %   Plot Exits.
    ExitPositions       = zeros(2, nExits);
    MatrixPosition      = 1;
    for i = 1:nGroups,
        Ends = [Groups(i).Ends.Position];
        nEnds = length(Ends(1,:));
        ExitPositions(:,MatrixPosition:MatrixPosition+nEnds-1) = Ends;
        MatrixPosition = MatrixPosition + nEnds;
    end
    hold on;
    plot(ExitPositions(1, :), m - ExitPositions(2, :) + 1, '.r', 'MarkerSize', 30);
    
    %   Plot Spawn points
    SpawnPositions      = zeros(2, nSpawns);
    MatrixPosition      = 1;
    for i = 1:nGroups,
        Spawns = [Groups(i).Starts.Position];
        nStarts = length(Spawns(1, :));
        SpawnPositions(:, MatrixPosition:MatrixPosition+nStarts-1) = Spawns;
        MatrixPosition = MatrixPosition + nStarts;
    end
    plot(SpawnPositions(1,:), m - SpawnPositions(2, :) + 1, '.g', 'MarkerSize', 30);
    
    %   Plot Passengers
    for i = 1:nTotalPassengers,
        Started     = Passengers(i).Started;
        Finished    = Passengers(i).Finished;
        if Started == 1 && Finished == 0,
            plot(Passengers(i).Position(1), m - Passengers(i).Position(2) + 1, '.bl', 'MarkerSize', 20 + 3*Passengers(i).Radius);
        end
    end
    xlim([0 n+1]);
    ylim([0 m+1]);
    title(num2str(t));
    
    %   Add Frame to movie.
    Movie = addframe(Movie, Frame);
    
    %   Clear trash.
    clear WallPositions ExitPositions MatrixPosition i Ends nEnds Spawns nStarts SpawnPositions StartedMatrix FinishedMatrix Started Finished;
    if sum([Passengers.Finished]) == nTotalPassengers,
        %   Add another 25 frames without any passenger moving to fade the
        %   result out.
        for i = 1:25,
            Movie = addframe(Movie, Frame);
        end
        break;
    end
    
    %   Clear frame.
    close(Frame);
end

Movie = close(Movie);
clear all;