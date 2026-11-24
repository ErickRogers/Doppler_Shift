function [ft_Forristall,ft_Kahma,ft_Lenain]=compute_transition_frequency(U10,Ustar,verbose)
%% We need to estimate ft. This can be for one of two purposes:
%% 1) limit the validity of spectrum, e.g. to stop at ft  OR
%% 2) attach an f-5 tail at ft. (see Vincent paper, top of page 3, B5=ft*B4)
%% At time of writing:
%% In this case of Battjes_spectrum.m, and Resio_spectrum.m, our purpose is (1)
%% In the case of Forristall_spectrum.m, Vincent_spectrum.m, our purpose is (2)
%% We have both U10 and Ustar as input arguments, since different scripts use different methods of computing Ustar

grav=9.81;

%%   I will use the Forristall 1981 formula, but I compute using 2 other methods for testing purposes.
%% ft_Forristall=0.29/Ustar; %  where did I get 0.29? see my pptx file...in Forristall paper page 8079, he says ftilde>0.03
ft_Forristall=0.27/Ustar; %   in Forristall paper, page 8082, ftildex = 0.0275, which is 0.27/ustar
ft_Kahma=5*grav/(2*pi*U10); % Kahma and Calkoen "in the neighborhood of omegatilde=5." Thus ~7.8/U10. More about this in my notes in buoy_eval_Aug_to_Nov_2025_CUI.pptx...for U10=28*Ustar, this is 0.28/Ustar

%% Lenain and Melville (JPO 2017) : k*ustar^2/grav is 1 to 2 e-3...
%% But this looks like a typo. On page 2133, they refer to values from 0.01 to 0.025. See also their Fig 13. We can use 0.02
%% Also, Vincent et al. cite Lenain and Melville with k_i*ustar^2/g=0.015.
ft_Lenain=sqrt(0.015)*grav/(2*pi*Ustar); % this is ~0.22/Ustar

%ktmp=2e-2*grav/Ustar^2;
%ft_Lenain_alt=sqrt(ktmp)/2

if verbose==1
  disp(['(input) U10 = ' num2str(U10)])
  disp(['(input) Ustar = ' num2str(Ustar)])
  disp(['ft_Forristall = ' num2str(ft_Forristall)])
  disp(['ft_Kahma = ' num2str(ft_Kahma)])
  disp(['ft_Lenain = ' num2str(ft_Lenain)])
end

%% Here's another way to figure out the Forristall ft.
%% He gives alpha4 and alpha5 in his table
%% at ft, Ef4(f)=Ef5(f), so ft=alpha5*grav/(alpha4*ustar)
%% alpha4=4.43e-4;
%% alpha5=12.2e-6;
%% grav=9.81;
%% FF=alpha5*grav/alpha4; % FF = 0.2702
