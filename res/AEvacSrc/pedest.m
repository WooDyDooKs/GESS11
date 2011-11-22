%Lecture with Computer Exercises
%Modelling and Simulating Social Systems
%Projects: Pedestrian Dynamics
%Lukas Bühler Heer Philipp
%file: pedest.m
%run matrix description
run init
mov1 = avifile('planeS_1new.avi');

%time loop
for t=0:dt:T
	%reset seen phy_, obi_& soc_forces
	pasMat(1:NrOfpassenger,8:11)=0;
	pasMat(1:NrOfpassenger,17:20)=0;
	%passenger loop
	for i=1:NrOfpassenger
		if pasMat(i,3)==1
			%calculation integer matrix indices
			xint=real(int16(pasMat(i,1)));
			yint=real(int16(pasMat(i,2)));
			%errorcatcher
			if xint<=0 || xint >= n || yint <=0 || yint >=m
			pasMat(i,3)=0;
			end
		end
		if pasMat(i,3)==1
			%passenger in exit-area
			if f(yint,xint)==Inf || f(yint+1,xint)==Inf ||f(yint-1,xint)==Inf || f(yint+2,xint)==Inf ||f(yint-2,xint)==Inf
			pasMat(i,3)=0;
			pasMat=sortrows(pasMat,3);
			passengerfleed=passengerfleed+1;
			end
			%passenger in "about to leave the plane"-area
			if f(yint,xint)==3 && crewflee==0
			pasMat(i,12)=FX(yint,xint)*fear_force_factor;
			pasMat(i,13)=FY(yint,xint)*fear_force_factor;
			%passenger in flightattendant-area
			elseif f(yint,xint)==6 && crewflee==0
			pasMat(i,12)=FX(yint,xint)*flee_force_factor;
			pasMat(i,13)=FY(yint,xint)*flee_force_factor;
			%passenger in no special area
			else
			pasMat(i,12)=FX(yint,xint)*force_factor;
			pasMat(i,13)=FY(yint,xint)*force_factor;
			end
			e_a=pasMat(i,12:13)/norm(pasMat(i,12:13)+[epsilon 0]);
			%influence of other passenger
			for j=1:NrOfpassenger
				if i~=j && pasMat(j,3)==1
					fv=[pasMat(i,1)-pasMat(j,1);pasMat(i,2)-pasMat(j,2)];
					if norm(fv)<pas_soc_influence_area
						n_ab=(pasMat(i,1:2)-pasMat(j,1:2))./norm(pasMat(j,1:2)-pasMat(i,1:2));
						%calculation f_phy
						if norm(fv)<pas_phy_influence_area
							pasMat(i,8:9)=pasMat(i,8:9)+A_phy*exp((1-norm(pasMat(i,1:2)-pasMat(j,1:2)))/B_phy).*n_ab;
						end
						%calculation f_soc
						%phi_alphabeta = angle between passenger i and j
						phi_alphabeta=acos(dot(e_a,n_ab));
						pasMat(i,10:11)=pasMat(i,10:11)+((lamda+(1-lamda)*(1+cos(phi_alphabeta))/2))*A_soc*exp(1-norm
						(pasMat(i,1:2)-pasMat(j,1:2))/B_soc).*n_ab;
					end
				end
			end
			%influence of wall_objects
			for j=1:NrOfObi
				%fv=vector between pas and wallelement
				fv=[pasMat(i,1)-obiMat(j,1);pasMat(i,2)-obiMat(j,2)];
				if norm(fv)<wall_influence_area
					wall_force=A_wall*exp(-norm(fv)/B_wall);
					if abs(obiMat(j,19))< abs(obiMat(j,20)) % wall in y-direction
						if obiMat(j,20)==[2.2] %only a wallelem above
							if pasMat(i,2)< obiMat(j,2)
								pasMat(i,12)=pasMat(i,12)+3*FX(yint-1,xint)*force_factor;
							else
								pasMat(i,17)=pasMat(i,17)+1.5*sign(fv(1))*wall_force;
							end
						pasMat(i,18)=-100;
						elseif obiMat(j,20)==[-3.3] %only a wallelem below
							if pasMat(i,2) > obiMat(j,2)
								pasMat(i,12)=pasMat(i,12)+3*FX(yint+1,xint)*force_factor;
							else
								pasMat(i,17)=pasMat(i,17)+1.5*sign(fv(1))*wall_force;
							end
							pasMat(i,18)=100;
						else
							pasMat(i,17)=pasMat(i,17)+1.5*sign(fv(1))*wall_force;
						end
					else % wall in x-direction
						if obiMat(j,19)==[2.2] %only a wallelem on the rigth
							if pasMat(i,1)< obiMat(j,1)
								pasMat(i,13)=pasMat(i,13)+3*FY(yint,xint-1)*force_factor;
							else
								pasMat(i,18)=pasMat(i,18)+1.5*sign(fv(2))*wall_force;
							end
							pasMat(i,17)=-100;
						elseif obiMat(j,19)==[-3.3] %only a wallelem on the left
							if pasMat(i,1) > obiMat(j,1)
								pasMat(i,13)=pasMat(i,13)+3*FY(yint,xint+1)*force_factor;
							else
								pasMat(i,18)=pasMat(i,18)+1.5*sign(fv(2))*wall_force;
							end
							pasMat(i,17)=100;
						else
							pasMat(i,18)=pasMat(i,18)+1.5*sign(fv(2))*wall_force;
						end
					end
					break;%only look at one wall-obj
				end
			end
		else
			pasMat(i,8:15)=0;
			pasMat(i,4:5)=0;
		end
	end
	%calculate f_tot
	pasMat(1:NrOfpassenger,14:15)=(pasMat(1:NrOfpassenger,8:9)+pasMat(1:NrOfpassenger,10:11)+...
	pasMat(1:NrOfpassenger,12:13)+pasMat(1:NrOfpassenger,17:18)+pasMat(1:NrOfpassenger,19:20));
	%calculate x'' and x'
	pasMat(1:NrOfpassenger,4:5)=dt.*pasMat(1:NrOfpassenger,14:15)./[pasMat(1:NrOfpassenger,16) pasMat(1:
	NrOfpassenger,16)];
	%calculate x
	pasMat(1:NrOfpassenger,6:7)=pasMat(1:NrOfpassenger,1:2);
	pasMat(1:NrOfpassenger,7)=pasMat(1:NrOfpassenger,7)+epsilon;
	pasMat(1:NrOfpassenger,1:2)=dt.*pasMat(1:NrOfpassenger,4:5)+pasMat(1:NrOfpassenger,1:2);
	pasMat(1:NrOfpassenger,4)=pasMat(1:NrOfpassenger,4)+epsilon;
	allMat=[pasMat;obiMat2];
	%newplot
	plot(allMat(NrOfpassenger+1:NrOfpassenger+NrOfObi2,1),allMat(NrOfpassenger+1:NrOfpassenger+NrOfObi2,
	2),'.k','MarkerSize', 20);
	hold on
	plot(exiMat(:,1),exiMat(:,2),'.r','MarkerSize', 20);
	plot(allMat(1+passengerfleed:NrOfpassenger,1),allMat(1+passengerfleed:NrOfpassenger,2),'.bl','MarkerSize', 30);
	xlim([000 n]);
	ylim([0 m]);
	%handle movie
	FF1 = getframe(gca);
	mov1=addframe(mov1,FF1);
	clf('reset')
	%if all passengers are gone -> allow crew to flee
	if sum(pasMat(1:NrOfpassenger,3))==0
		break;
	end
end
%end movie
mov1=close(mov1);