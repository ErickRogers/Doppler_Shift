
%% Method_A1_B2_demo.m
%% Purpose : demonstrate application of Method_A1_B2 (denoted "Method 2" in the paper) for a single spectrum

clear

buoytype=2;
%% Load a file that contains 4 variables: Ef_rep, U10_rep, PROJs_rep, and fd (their meaning is explained below)
infile=['./sample_data/Ef.0.2Hz.0.67Hz_drmax3.5.buoy' num2str(buoytype) '.U10_10.rep18219.mat'];
if exist(infile)==2
  disp([infile ' found.'])
else
  error([infile ' not found.'])
end
load(infile,'Ef_rep','U10_rep','PROJs_rep','fd')

%% We keep the nomencalture "fd"
%% Rename the other three variables, for clarity
Efd=Ef_rep; clear Ef_rep
U10=U10_rep ; clear U10_rep
PROJs=PROJs_rep; clear PROJs_rep

%% Now we have 4 parameters:
%%   Attr   Name        Size                     Bytes  Class
%%   ====   ====        ====                     =====  ===== 
%%          Efd         1x471                     3768  double
%%          PROJs       1x1                          8  double
%%          U10         1x1                          8  double
%%          fd          1x471                     3768  double

%%          Efd         spectral density reported by the drifter, E(f) in m2/Hz
%%          PROJs       buoy drift speed along the axis of the wind direction, in m/s
%%          U10         10-m wind speed in m/s. (I use the 10-m neutral wind speed.)
%%          fd          frequency as perceived from the drifter frame of reference

%% In practice, you only need to call one or the other. For the demo, I call both

test_freq=0.4;

disp('Calling merged script')
[EfaEfd1]=Doppler_shift_one_Spotter_A1_Bx(fd, Efd, U10, test_freq, PROJs, buoytype);

disp('plotting')

env = detect_matlab_or_octave();
if env.isOctave
  is_octave=1;
  SOFTWARE='octave';
else
  is_octave=0;
  SOFTWARE='matlab';
end

%% We didn't receive the new fa grid computed in Doppler_shift_one_Spotter_A1_B2.m
%% We received the ratio Efa(freq)/Efd(freq), where freq is on the original discretization
%% that we used for fd. 
%% In other words, frequency is not context-dependent.
%% Thus, to avoid confusion, we rename it now.
freq=fd; clear fd

%% Use ratio to compute Efa(freq)
Efa=EfaEfd1.*Efd;

%% Plot as subplots
figure(1),clf,hold off

pause(0.5)
set(gcf,'position',[1300 300 700 1000])
pause(0.5)

subplot(3,1,1)
plot(freq,EfaEfd1,'k-','linewidth',3)
grid on
xlabel('freq (Hz)')
ylabel('ratio Efa(freq)/Efd(freq)')
set(gca,'ylim',[0.8 1.8])
title(['Spotter spectrum; U10 = ' sprintf('%5.2f',U10) ' m/s, PROJs = ' sprintf('%5.2f',PROJs) ' m/s'])

subplot(3,1,2)
if is_octave==1
  plot(freq,Efd,'b-','linewidth',3,freq,Efa,'r--','linewidth',3)
else
  plot(freq,Efd,'b-',freq,Efa,'r--','linewidth',3)
end
grid on
xlabel('freq (Hz)')
ylabel('E(f) (m2/Hz)')
legend('Efd(fd)','Efa(fa)')
title(['linear plot'])

subplot(3,1,3)
if is_octave==1
  loglog(freq,Efd,'b-','linewidth',3,freq,Efa,'r--','linewidth',3)
else
  loglog(freq,Efd,'b-',freq,Efa,'r--','linewidth',3)
end

grid on
xlabel('freq (Hz)')
ylabel('E(f) (m2/Hz)')
title(['log plot'])
pause(0.5)
str=['print -dpng Method_2_demo.Spotter.' SOFTWARE '.png'];disp(str);eval(str)
pause(0.5)

%% Now, we'll do the same thing, but we'll use a parametric spectrum this time
%% Treat this as Efd(fd)
ft_method=1;    verbose=0;    iplot=0;  
grav=9.81;
fp=0.13*grav/U10; % PM
Efdpar=Holthuijsen_Forristall_spectrum(U10,freq,fp,ft_method,verbose,iplot);
disp('Calling merged script')
[EfaEfd3]=Doppler_shift_one_Spotter_A1_Bx(freq, Efdpar, U10, test_freq, PROJs, buoytype);

%% Use ratio to compute Efa(freq)
Efapar=EfaEfd3.*Efdpar;

%% Plot as subplots
figure(2),clf,hold off

pause(0.5)
set(gcf,'position',[2000 300 700 1000])
pause(0.5)

subplot(3,1,1)
plot(freq,EfaEfd3,'k-','linewidth',3)
grid on
xlabel('freq (Hz)')
ylabel('ratio Efa(freq)/Efd(freq)')
set(gca,'ylim',[0.8 1.8])
title(['parametric spectrum; U10 = ' sprintf('%5.2f',U10) ' m/s, PROJs = ' sprintf('%5.2f',PROJs) ' m/s'])

subplot(3,1,2)
if is_octave==1
  plot(freq,Efdpar,'b-','linewidth',3,freq,Efapar,'r--','linewidth',3)
else
  plot(freq,Efdpar,'b-',freq,Efapar,'r--','linewidth',3)
end

grid on
xlabel('freq (Hz)')
ylabel('E(f) (m2/Hz)')
legend('Efd(fd)','Efa(fa)')
title(['linear plot'])

subplot(3,1,3)
if is_octave==1
  loglog(freq,Efdpar,'b-','linewidth',3,freq,Efapar,'r--','linewidth',3)
else
  loglog(freq,Efdpar,'b-',freq,Efapar,'r--','linewidth',3)
end

grid on
xlabel('freq (Hz)')
ylabel('E(f) (m2/Hz)')
title(['log plot'])

str=['print -dpng Method_2_demo.parametric.' SOFTWARE '.png'];disp(str);eval(str)
