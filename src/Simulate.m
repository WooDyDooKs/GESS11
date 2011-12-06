%   The acutal simulation of the train entrance.
%   
%   First runs the setup script which loads the data needed by the
%   simulation to run, then runs the simulation for a given time.
%
%   Variables that need to be defined are:
%
%   Variable                |   Description
%   ----------------------------------------------------------------------
%   T                       |   The duration of the simulation.
%   dt                      |   A timestep in the simulation.
%   pInfArea                |   The physical influence area for passengers.
%   sInfArea                |   The social influence area for passengers.
%   nPassengers             |   The number of passengers in each group.
%   nGroups                 |   The number of groups.
%   passengerData           |   Matrix holding data about every passenger.
%   Map                     |   Map, holding information about walls and
%                           |   special zones.
%   Layers                  |   Contains the k vectorfields used to bring
%                           |   passengers on their shortest path.
