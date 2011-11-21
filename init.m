%Lecture with Computer Exercises
%Modelling and Simulating Social Systems
%Projects: Pedestrian Dynamics
%Lukas Bühler Heer Philipp
%file: init.m
%Init
clear all;
clc

%variable definition
pas_phy_influence_area=3;
pas_soc_influence_area=10;
att_soc_influence_area=10;
A_phy=80;
A_soc=40;
A_wall=1000;
B_phy=1;
B_soc=2;
B_wall=.5;
lamda=0.2;
dt=0.3;
epsilon=1e-10;
T=200/dt;
wall_influence_area=1.2;
wallrelevance_area=10;
heavy=1e10;
fear_force_factor=20;
force_factor=40;
flee_force_factor=60;
walelem=1;
paselem=1;
exielem=1;
crewflee=0;
passengerfleed=0;
gone=0;

%allocation of matrices
pasMat=zeros(10,20);
obiMat=zeros(700,20);
obiMat2=[];

%read picture/generate forcefield
f = getFile();
[FX,FY]=computeGradientField1(f);
[m n]=size(FX);

%integration into matrices
for mm=1:m
	for nn=1:n
		%pas integration
		if f(mm,nn)==2;
			pasMat(paselem,2)=mm;
			pasMat(paselem,1)=nn;
			paselem=paselem+1;
		end
		%wall integration
		if f(mm,nn)==0;
			obiMat(walelem,2)=mm;
			obiMat(walelem,1)=nn;
			walelem=walelem+1;
		end
		%exit integration
		if f(mm,nn)==Inf;
			exiMat(exielem,2)=mm;
			exiMat(exielem,1)=nn;
			exielem=exielem+1;
		end
	end
end

%IT'S ALIVE MUAHAHAH!!
pasMat(:,3)=1;

%'previous' place
pasMat(:,6)=pasMat(:,1);
pasMat(:,7)=pasMat(:,2)+epsilon;
pasMat(:,4)=epsilon;
[NrOfpassenger entries]=size(pasMat);
[NrOfObi Obientries]=size(obiMat);

%random weigth
pasMat(:,16)=unidrnd(70,NrOfpassenger,1)+50;
obiMat(:,16)=heavy;

%set walldirection
for mn=2:NrOfObi
	%there is a wallelem above
	if f(obiMat(mn,2)+1,obiMat(mn,1))==0
		obiMat(mn,20)=[2.2];
	end
	%there is a wallelem below
	if f(obiMat(mn,2)-1,obiMat(mn,1))==0
		obiMat(mn,20)=obiMat(mn,20)-3.3;
	end
	%there is a wallelem on the rigth
	if f(obiMat(mn,2),obiMat(mn,1)+1)==0
		obiMat(mn,19)=[2.2];
	end
	%there is a wallelem on the left
	if f(obiMat(mn,2),obiMat(mn,1)-1)==0
		obiMat(mn,19)=obiMat(mn,19)-3.3;
	end
end

%simplify obiMat -> leave out useless wall elements
for j=1:exielem-1
	obiMat1=obiMat;
	[NrOfObi Obientries]=size(obiMat);
	gone=0;
	for i=1:NrOfObi
		fv=abs([obiMat1(i-gone,1)-exiMat(j,1);obiMat1(i-gone,2)-exiMat(j,2)]);
		NrOfObi=NrOfObi-gone;
		if abs(obiMat1(i-gone,19)) > abs(obiMat1(i-gone,20))
			if abs(norm(fv)) > wallrelevance_area
				obiMat1(i-gone,:)=[];
				gone=gone+1;
			end
		end
	end
	obiMat2=[obiMat2;obiMat1];
end

obiMat3=unique(obiMat2,'rows');
clear obiMat2;
[NrOfObi Obientries]=size(obiMat);
for i=1:NrOfObi
	if abs(obiMat(i,19)) > abs(obiMat(i,20))
		if obiMat(i,2) < 7 || obiMat(i,2) > m-7
		else
		obiMat3=[obiMat3;obiMat(i,:)];
		end
	end
end
obiMat2=obiMat;
obiMat=obiMat3;
clear obiMat4;
clear obiMat1;
clear obiMat3;
[NrOfObi Obientries]=size(obiMat);
[NrOfObi2 Obientries2]=size(obiMat2);