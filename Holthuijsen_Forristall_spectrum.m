function [Ef]=Holthuijsen_Forristall_spectrum(U10,freq,fp,ft_method,verbose,iplot)
%%  Source: Holthuijsen which references Battjes et al. 1987
%% This depends on Ustar, and we use Hwang formula.
%% We transition from f-4 to f-5 at frequency ft:
%%   a) Forristall ft using Hwang Ustar OR
%%   b) Tsagareli ft, which is the same as Kahma ft OR
%%   c) Lenain ft
%% The selection of a,b,c is hardwired.
%% Note that this does not give a full spectrum, just the equilibrium range
%% fp is an input parameter, but it is only used to define the limits of validity
%% This takes U10 and converts to Ustar internally using Hwang
%% Calibration is taken from Holthuijsen who cites Battjes. 
%% The f-4 part of this is basically the same as Battjes_spectrum.m , just using a different calibration and maybe a different Cd.

%% Note that this is not the BHP spectrum! That's a different parametric model. It uses a different ft (see report and below).

%% These four scripts are very similar:
%% Holthuijsen_spectrum.m : in plot_several_spectra_v4.m, I replaced this with BHP_spectrum.m
%% * uses Hwang Cd
%% * uses Beta=0.096
%% * applies NaN in saturation range
%% Holthuijsen_Forristall_spectrum.m : not used in plot_several_spectra_v4.m
%% * uses Hwang Cd
%% * uses Beta=0.096
%% * attaches tail in saturation range, following Vincent method
%% Forristall_spectrum.m : used in plot_several_spectra_v4.m (for higher bound)
%% * uses Hwang Cd
%% * uses alpha4=4.43e-4; equivalent to: Beta=0.11;
%% * alpha5=12.2e-6; % see report: This is like alphaP=0.019
%% BHP_spectrum.m : used in plot_several_spectra_v4.m (for lower bound)
%%  * uses Hwang Cd
%%  * uses Beta=0.096
%%  * attaches tail in saturation range, to match Phillips, alphaP=0.0081
%%
%% Holthuijsen_spectrum.m...............stops at transition frequency ft
%% Forristall_spectrum.m................stops at transition frequency ft
%% Holthuijsen_Forristall_spectrum.m....continues at transition frequency ft, using f-5
%% BHP_spectrum.m.......................continues at transition frequency ft, using alphaP

%% References
%% 1) Toba (JO 1973)
%% 2) Forristall (JGR 1981)
%% 3) Hwang (JTECH 2011)
%% 4) Holthuijsen (book 2007)
%% 5) Battjes et al. (JPO 1987)
%% 6) (if used in calling script) Pierson and Moskowitz (JGR 1964)
%% 7) Rogers et al. 2026, tech report, https://arxiv.org/abs/2610.12752

%% summary 
%% 1) equilibrium range (f-4) spectral level is based on formula of Toba (1973)
%% 2) transition to saturation range (f-5) is based on Forristall (1981)
%% 3) Forristall transition requires U*. We use Hwang (2011)
%% 4) Toba formula requires a calibration Beta. We use 0.096 from Holthuijsen book, pg 157.
%% 5) Beta value in Holthuijsen book, pg 157 is taken from and average of values given by Battjes et al. (1987)
%% 6) 1.5*fp is used to define lower limit of equilibrium range. fp might use fp_PM or some multiple of fp_PM (fp is provided as function argument, and I often use fp of PM in calling script)

%% Note that for a fixed frequency (e.g. 0.4 Hz) and high winds (e.g. 17 m/s and higher), this model predicts that spectral density is constant with wind speed. Why?
%% Another way to say this is: once the frequency gets into the saturation range, it is constant with wind speed. Why?
%% E(f)=B4*f^(-4)  E(f)=B5*f^(-4)
%% E(f)=B4*ft^(-4)  E(f)=B5*ft^(-4)
%% B5=B4*ft
%% B4=C1*Ustar % Toba uses Ustar. This is the Toba formula. C1 is a constant.
%% ft=C2/Ustar % Forristall formula for ft
%% E(f)=B5*f^(-5) % saturation range
%% E(f)=B4      *ft*f^(-5)  % saturation range
%%     =C1*Ustar*ft        *f^(-5)  % saturation range
%%     =C1*Ustar*(C2/Ustar)*f^(-5)  % saturation range
%%     =C3                 *f^(-5)  % saturation range
%% Therefore, E(f) does not depend on Ustar in the saturation range.

nf=length(freq);
grav=9.81;

if exist('verbose')~=1
  verbose=1;
end
if exist('iplot')~=1
  iplot=0;
end

%% Get ustar from Hwang formula. Note that Battjes uses Garratt formula for this.
[Ustar,CD]=Ustar_fn_Hwang_mod_v2(U10);
clear CD

%% Get ustar from Garratt formula
%% [Ustar,CD]=Ustar_fn_Garratt(U10);
%% clear CD

%% Compute E(f)
Beta=0.096; % Holthuijsen book, pg 157. He says that 0.096 is the "average of their Table 2 for field observations" Table 2 is in Battjes.
%Beta=0.11; % Use 0.11 to match the "mode" of Table 2...but if we do this, we aren't following any recommendation of Holthiujsen, so we would need to rename this script ...in any case, we already have a script for 0.11 (Forristall)

B4=Beta*grav*Ustar/((2*pi)^3); % "B4" is the notation of Vincent
for is=1:length(freq)
  Ef(is)=B4/(freq(is)^4); % Battjes eq 3
end

[ft_Forristall,ft_Kahma,ft_Lenain]=compute_transition_frequency(U10,Ustar,verbose);
if ft_method==1
  ft=ft_Forristall; % this is ~0.29/Ustar (actually 0.27/Ustar) Q: Where did I get 0.29? A: see my pptx file...in Forristall paper, he says ftilde>0.03
elseif ft_method==2
  ft=ft_Kahma;
elseif ft_method==3
  ft=ft_Lenain; % this is ~0.19/Ustar
elseif ft_method==4
  ft=mean([ft_Forristall ft_Lenain]); % this is ~0.24/Ustar
end
if verbose==1
  disp(['Holthuijsen_Forristall_spectrum.m : ft = ' num2str(ft)])
end

B5=ft*B4; % Vincent, top of page 3, based on simple algebra: B4*ft^-4 = B5*ft^-5
%%.....................................................thus: B4*ft    = B5

%% Formula is not valid in the saturation range, so we attach a f-5 spectrum at freq=ft.
isat=find(freq>ft);
for is=isat
  Ef(is)=B5/freq(is)^5; % Vincent eq 2
end
%% Not valid below the equilibrium range
feq=1.5*fp;
is=find(freq<feq);
Ef(is)=NaN;

if feq>ft % added 11/17/2026
  error('feq>ft')
end

if iplot==1
  alpha=0.0081;
  close all ; figure(1)

  [Ef_PM]=PM_spectrum_v2(U10,freq,alpha,0);
  figure(1),clf,hold off
  orient('tall')

  subplot(2,1,1)
  plot(freq,Ef_PM,'k-','linewidth',3,freq,Ef,'r--','linewidth',3)
  grid on
  set(gca,'ylim',[0 0.2])
  title(['inputs: U10 = ' num2str(U10) ' ; fp = ' num2str(fp)])
  legend('PM','Toba/Battjes/Holthuijsen+Forristall')
  xlabel('freq (Hz)')
  ylabel('E(f) (m2/Hz)')

  subplot(2,1,2)
  X1=[0.4 0.4];
  X2=[ft ft];
  YY=[1e-2 1e+2];
  loglog(freq,Ef_PM,'k-','linewidth',3,freq,Ef,'r--','linewidth',3,X1,YY,'b-','linewidth',1,X2,YY,'r-','linewidth',1)
  grid on
  axis([0.05 1.5 YY])
  title(['inputs: U10 = ' num2str(U10) ' ; fp = ' num2str(fp)])
% legend('PM','Toba/Battjes/Holthuijsen','location','south')
  xlabel('freq (Hz)')
  ylabel('E(f) (m2/Hz)')

  orient('tall')
  str=['print -dpng Holthuijsen_Forristall_spectrum_U10_eq' num2str(U10) '_fp_eq_' num2str(fp) '.png'];disp(str);eval(str)

end

