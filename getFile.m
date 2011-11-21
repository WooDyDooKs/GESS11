function [F] = getFile()
%getFile: Convertion of an bmp??image to a matrix
% This function converts a bmp??file to a matrix and returns it. There are
% only the following colors with their corresponding interpretation
% allowed:
%
% Color Hex triplet Description
% White FFFFFF Space in which the passengers can freely
% walk
% Black 000000 Walls
% Red FF0000 Emergency exit
% Blue 0000FF Every blue pixel is recognised as a
% pessanger
% Light green 00FF00 Every light green pixel is recognised as a
% flight attendant
% Dark green 009900 Zone which is influenced by the flight
% attendant
% Yellow FFFF00 Special zones, in which pessangers
% struggle to continue walking
%
% The output matrix contains the following entries:
% 0=wall, 1=space, 2=passenger, 3=hesitation area, 4=flightattendant,
% 6=flightattendantarea, Inf=emergency exit
exit=0;

while exit==0
	[FileName,PathName] = uigetfile(’*.bmp’, ’Select a Bitmap File’)
	I=imread(strcat(PathName,FileName));
	exit=1;
	if (find(I>6))
		exit=0;
		uiwait(msgbox(’Wrong file’));
	end
end

space=find(I==5);
goSlow=find(I==4);
exit=find(I==2);
passenger=find(I==1);
flightattendant=find(I==3);
flightattendantarea=find(I==6);
wall=find(I==0);
[n,m]=size(I);
F=zeros(n,m);
F(space)=1;
F(goSlow)=3
F(exit)=Inf;
F(passenger)=2;
F(flightattendant)=4;
F(wall)=0;
F(flightattendantarea)=6;
F=flipud(F)
end