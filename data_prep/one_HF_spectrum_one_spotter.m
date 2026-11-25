function one_HF_spectrum_one_spotter(spotterfile,f1,f2,drift_cutoff,verbose,iplot)

%% Note that spotterfile is the .mat file not the json file

%% Potential improvement: also co-locate with local water depth and save that


if exist(spotterfile)~=2
  error([spotterfile ' not found.'])
end

basename=strrep(spotterfile,'.mat','');

iwarn1=0;
iwarn2=0;

outfile=[basename '.Ef.' num2str(f1) '_' num2str(f2) '_drmax' num2str(drift_cutoff) '.mat'];

%% Optional code to skip files:
%% if exist(outfile)==2
%%   disp([outfile ' already exists. returning.'])
%%   return
%% end

%% load spotterfile
load(spotterfile,'lat','lon','spotter_time','Ef','a1','b1','df','freq','spotter_id');
fcell=freq; clear freq
Efcell=Ef; clear Ef;
a1cell=a1; clear a1;
b1cell=b1; clear b1;
dfcell=df; clear df;

down_select=0; % default : no need to down-select the buoy data
if max(isnan(lon))>0
  down_select=1;
  disp('NaNs in lon...we will down-select the data')
end
% check for repeating time stamp...we want to avoid this because we use delta_t later.
give_warning=1;
for irec=2:length(lat)
  if strcmp(spotter_time{irec},spotter_time{irec-1})
    down_select=1;
    if give_warning==1
      disp('repetition of time stamps...we will down-select the data')
      give_warning=0; % stop giving the warning
    end
  end
end

if down_select==1 % then we need to down-select the buoy data
  disp(['down_select==1 for ' spotterfile])
  irec2=0;
  for irec=1:length(lat)
    timeisok=1;
    if irec>1 % then check for repeating time stamp...we want to avoid this
      if strcmp(spotter_time{irec},spotter_time{irec-1})
        timeisok=0;
      end
    end
    if isnan(lon(irec))==0 && timeisok==1
      irec2=irec2+1;
      Efcell2{irec2}=Efcell{irec};
      a1cell2{irec2}=a1cell{irec};
      b1cell2{irec2}=b1cell{irec};
      dfcell2{irec2}=dfcell{irec};
      fcell2{irec2}=fcell{irec};
      spotter_time2{irec2}=spotter_time{irec};
      spotter_id2{irec2}=spotter_id{irec};
      lat2(irec2)=lat(irec);
      lon2(irec2)=lon(irec);
    end
  end
  disp(['We downselected from ' num2str(length(lat)) ' to ' num2str(irec2)])

  Efcell=Efcell2; clear Efcell2
  a1cell=a1cell2; clear a1cell2
  b1cell=b1cell2; clear b1cell2
  dfcell=dfcell2; clear dfcell2
  fcell=fcell2; clear fcell2
  spotter_time=spotter_time2; clear spotter_time2
  spotter_id=spotter_id2; clear spotter_id2
  lat=lat2; clear lat2
  lon=lon2; clear lon2

  %%        Efcell            1x433                   135096  cell
  %%        fcell             1x433                   135096  cell
  %%        spotter_time      1x433                    10392  cell
  %%        lat               1x433                     3464  double
  %%        lon               1x433                     3464  double
  
end

load /net/chosin/export/data/rogers/ERA5/ERA5_windvec_at_Spotter_locs.mat
%%  Attr   Name             Size                     Bytes  Class
%%  ====   ====             ====                     =====  ===== 
%%         t_obs            1x3271820             26174560  double
%%         u10x_at_obs      1x3271820             13087280  single
%%         u10y_at_obs      1x3271820             13087280  single
%%         x_obs            1x3271820             26174560  double
%%         y_obs            1x3271820             26174560  double

%% down-select ERA5 on our lat range to speed things up (e.g. 14.6 sec ==> 2.6 sec)
ii=find(y_obs>=min(lat) & y_obs<=max(lat));
u10x_at_obs=u10x_at_obs(ii);
u10y_at_obs=u10y_at_obs(ii);
t_obs=t_obs(ii);
x_obs=x_obs(ii);
y_obs=y_obs(ii);

%% define fnew
%% median df of Spotter is 0.01, so we use 1/10 of that
dfnew=0.001;
fnew=f1:dfnew:f2;

%% constants and settings
%% Rm=6371e+3; % radius in meters
verbose=0;
grav=9.81;
stokesfac=16*(pi^3)/grav;

nrec=length(lat);

tic
for irec=1:nrec
  
  if mod(irec,100)==0
    disp(['irec = ' num2str(irec) ' out of ' num2str(nrec)])
  end

  % convert time string to matlab time
  sptime=spotter_time{irec};
  yyyy=sptime(1:4);
  mm=sptime(6:7);
  dd=sptime(9:10);
  HH=sptime(12:13);
  MM=sptime(15:16);
  SS=sptime(18:19);
  time(irec)=datenum(str2num(yyyy),str2num(mm),str2num(dd),str2num(HH),str2num(MM),str2num(SS));
  % begin error checking
  if strcmp(sptime(11),'T')~=1
    error('uh oh...T')
  end
  if strcmp(sptime(20:24),'.000Z')~=1
    error('uh oh... 000Z')
  end
  timecheck=datestr(time(irec),'yyyy-mm-ddTHH:MM:SS');
  if strcmp(sptime(1:length(timecheck)),timecheck)~=1
    disp(['datenum: ' timecheck])
    error('uh oh ...timecheck')
  end
  % end error checking
  
  clear sptime yyyy mm dd HH MM SS timecheck
  
  % set E(f) for this time
  freq=fcell{irec};
  Ef=Efcell{irec};
  a1=a1cell{irec};
  b1=b1cell{irec};
  df=dfcell{irec};
  
  % save some info that could be useful to have in the aggregate files
  nf_spotter(irec)=length(freq);
  fmax_spotter(irec)=max(freq);

  %% check limits : update 12/17/2025 : allow this to go through. interp1 will just provide us with NaNs as appropriate.
  if min(freq)>f1 &&  iwarn1==0
    disp('WARNING: f1<min(freq)')
    iwarn1=1; % stop future warnings
  end
  if max(freq)<f2 &&  iwarn2==0
    disp('WARNING: f2>max(freq)')
    iwarn2=1; % stop future warnings
  end

  %% compute surface stokes drift
  m3c=Ef.*(freq.^3); % m3 contribution at each frequency
  m3xc=m3c.*a1; % m3x contribution at each frequency (trick suggested in Wang et al., no need for directional estimator)
  m3yc=m3c.*b1; % m3y  "
  m3x=sum(m3xc.*df); % integral of m3xc
  m3y=sum(m3yc.*df); % integral of m3yc
%% recall that USS=m3*16*(pi^3)/g (see notes in docx)
  ussx(irec)=m3x.*stokesfac;
  ussy(irec)=m3y.*stokesfac;
  clear m3c m3xc m3yc m3x m3y
  
  %% set floor on Ef, since we want to use log(Ef)
  is=find(Ef<1e-20);
  Ef(is)=1e-20;
  clear is

  %% interpolate to fine grid
  log10Efnew=interp1(log10(freq),log10(Ef),log10(fnew));
  Efnew=10.^log10Efnew;
  clear log10Efnew

  if iplot==1
    figure(1),clf,hold off
    loglog(freq,Ef,'ko-',fnew,Efnew,'r.')
    grid on
    axis([f1-0.1 f2+0.2 1e-3 100])
    pause(1)

    figure(2),clf,hold off
    plot(freq,Ef,'ko-',fnew,Efnew,'r.')
    grid on
    axis([0.5 0.7 0.004 0.012])
    pause(1)

    disp('pausing (iplot=1)');pause
  end
  clear freq Ef a1 b1 df

%% Optional code to compute Hm0B
%% Edf=Efnew.*dfnew;
%% Etot=sum(Edf);
%% Hm0B(irec)=4*sqrt(Etot);
%% clear Efnew Edf Etot

  Efnew_save{irec}=Efnew;
  clear Efnew

%% include wind speed from ERA5
  ii=find(t_obs==time(irec) & x_obs==lon(irec) & y_obs==lat(irec) );
  if length(ii)==0
    error(['length(ii) = ' num2str(length(ii))])
  end
  U10x(irec)=u10x_at_obs(ii(1));
  U10y(irec)=u10y_at_obs(ii(1));
  clear ii

end
toc

U10s=sqrt(U10x.^2 + U10y.^2);

if nrec>1
  %% compute speed of drifter. this is done in a separate loop, because otherwise time(irec+1) is not available yet.
  %% determine indices
  for irec=1:nrec

    if irec==1
      i1=irec;
      i2=irec+1;
    elseif irec==nrec
      i1=irec-1;
      i2=irec;
    else
      i1=irec-1;
      i2=irec+1;
    end
    %% compute time difference in days
    dt_days=time(i2)-time(i1);
      
    %% compute drift vector (+ speed, optional)
    
    %% Old method: call calc_distance_rhumb.m  works fine but is over-complicated if you just need dx dy. See rhumb_test_calcs.m.

    %% Begin new method
    %% New method (as of 11/25/2026, not tested, but it should work)
    y1=lat(i1);y2=lat(i2);x1=lon(i1);x2=lon(i2);
    dx=(x2-x1)*(pi/180)*6371e+3*cos(mean([y1 y2])*pi/180);
    dy=(y2-y1)*111.12e+3;
    %% compute time difference in seconds
    dt_sec=dt_days*3600*24;
    %% compute vector in m/s
    drift_x(irec)=dx/dt_sec;
    drift_y(irec)=dy/dt_sec
    %% compute speed in m/s (NB: we could simplify things by computing drift_speed later in the script, where it is req'd)
    drift_speed(irec)=sqrt(drift_x(irec)^2+drift_y(irec)^2);
    if isnan(drift_speed(irec))
      error('uh oh... drift_speed')
    end
    clear x1 y1 x2 y2 dx dy dt_sec
    %% End new method
    
    %% compute projection of drift velocity along the axis of the wind
    PROJs(irec)=wind_and_drift_projection_scalar(U10x(irec),U10y(irec),drift_x(irec),drift_y(irec),verbose);

    PERC1(irec)=100*drift_speed(irec)/U10s(irec);
    PERC2(irec)=100*PROJs(irec)/U10s(irec);
    if mod(irec,100)==0 && verbose==1
      disp(['irec = ' num2str(irec) ' out of ' num2str(nrec) ' ; U10s = ' sprintf('%5.2f',U10s(irec)) ' ; drift speed = ' sprintf('%5.2f',drift_speed(irec)) ' ; ratio = ' num2str(round(PERC1(irec))) ' % ; drift proj. = ' sprintf('%5.2f',PROJs(irec)) ' ; ratio = ' num2str(round(PERC2(irec))) ' %'])
    end

    if isnan(PERC1(irec)) || isnan(PERC2(irec))
      error('uh oh PERC1 PERC2')
    end

  end %  for irec=1:nrec

else % nrec=1, so no computation is possible
  disp(['WARNING. nrec = ' num2str(nrec) ' , so we are setting some variables to NaN'])
  drift_speed(irec)=NaN;
  drift_x(irec)=NaN;
  drift_y(irec)=NaN;
  PROJs(irec)=NaN;
  PERC1(irec)=NaN;
  PERC2(irec)=NaN;
end

%% QC, 1 of 4
%% added 3/5/2026: Don't trust the drift calc if Ef(0.4) at this record or nearby records is small, because that might be an indication that the buoy was on a ship
is04=find(fnew==0.4);
if length(is04)~=1
  error('uh oh...is04')
end
for irec=1:nrec
  Ef04=Efnew_save{irec}(is04);
  if Ef04<1e-5
    i1=max([1 irec-1]);
    i2=min([nrec irec+1]);
    drift_speed(i1:i2)=NaN;
    drift_x(i1:i2)=NaN;
    drift_y(i1:i2)=NaN;
    PROJs(i1:i2)=NaN;
    PERC1(i1:i2)=NaN;
    PERC2(i1:i2)=NaN;
  end
end

%% added 3/6/2026 : QC above does not catch some cases...looks like buoys sometimes report E(0.4 Hz) even when on ship. More detail at "3/6/2026" in notes.txt. So here's what I'll do next: if buoy time series starts or stops far from the beginning of the month, cut out some records. This won't catch the cases of deployment near the beginning/end of month.
%% Calculate the first day of the current month and first day of next month
%% Get info about year and month
[Y, M, D, H, MI, S] = datevec(time(1));
first_day_of_month = datenum(Y, M, 1);
[Y, M, D, H, MI, S] = datevec(time(end));
%% Normally, we would use this: first_day_of_next_month = datenum(Y, M + 1, 1);
%% ...but Sofar omitted the last day of every month from the dataset, so we have to use this:
first_day_of_next_month = datenum(Y, M + 1, 1)-1;

clear Y M D H MI S
%% QC, 2 of 4
%% First look for case where it starts far from the beginning of the month.
cutoff_days=0.5;
XX=4;
if abs(time(1)-first_day_of_month)>cutoff_days % then the buoy was likely deployed at time(1), so if we want to mark 4 records as unusable, XX=4 and 1:XX are marked
  i1=1;    i2=min([nrec XX]);
  drift_speed(i1:i2)=NaN;
  drift_x(i1:i2)=NaN;
  drift_y(i1:i2)=NaN;
  PROJs(i1:i2)=NaN;
  PERC1(i1:i2)=NaN;
  PERC2(i1:i2)=NaN;
end
%% QC, 3 of 4
%% Next, look for case where it ends far from the end of the month.
if abs(time(nrec)-first_day_of_next_month)>cutoff_days % then the buoy was likely deployed at time(1), so mark end-3:end as unusable, e.g. with XX=4, we want to mark 4 records as unusable, so it is (nrec-3) to nrec, i.e., nrec-XX+1 to nrec
  i1=max([(nrec-(XX-1)) 1]);  i2=nrec;
  drift_speed(i1:i2)=NaN;
  drift_x(i1:i2)=NaN;
  drift_y(i1:i2)=NaN;
  PROJs(i1:i2)=NaN;
  PERC1(i1:i2)=NaN;
  PERC2(i1:i2)=NaN;
end

%% QC, 4 of 4
%% added 3/9/2026 : QC above does not catch some cases, like ./nov_2021/2021-11-01_2021-11-30_SPOT-0650.Ef.0.2.0.67.mat
%%  Here, the problem is Nov 19, which is 3 days prior to the end of the time series Nov 22
%%  So, instead we will look for cases with drift_speed>drift_cutoff and mark all within +/- 2 records as invalid
%%  In principle, I could just keep everything, and down-select on drift later, but then it would be more difficult to mark a range of records as invalid, since the buoys are mixed together in the big file
for irec=1:nrec
  if drift_speed(irec)>drift_cutoff
    i1=max([(irec-2) 1]);  i2=min([(irec+2) nrec]);
    drift_speed(i1:i2)=NaN;
    drift_x(i1:i2)=NaN;
    drift_y(i1:i2)=NaN;
    PROJs(i1:i2)=NaN;
    PERC1(i1:i2)=NaN;
    PERC2(i1:i2)=NaN;
  end
end

disp(['fmax_spotter(1) = ' num2str(fmax_spotter(1))])

if max(drift_speed)>drift_cutoff
  error('uh oh...max(drift_speed)>drift_cutoff')
end

clear irec fcell Efcell spotter_time 

Efnew=Efnew_save; clear Efnew_save

str=['save -v7 ' outfile ' time lat lon Efnew U10x U10y ussx ussy fnew nf_spotter fmax_spotter spotter_id drift_x drift_y PROJs'];disp(str);eval(str)

%% omitted:
%%         Efcell            1x720                   737280  cell
%%         PERC1             1x720                     2880  single
%%         PERC2             1x720                     2880  single
%%         U10s              1x720                     2880  single
%%         a1cell            1x720                   737280  cell
%%         b1cell            1x720                   737280  cell
%%         dfcell            1x720                   737280  cell
%%         drift_speed       1x720                     5760  double
%%         fcell             1x720                   737280  cell
%%         spotter_time      1x720                    17280  cell

if verbose==1
  %% Diagnostics
  MU=median(U10s)
  disp(['median(U10s)=' sprintf('%5.2f',MU)])
  IT=[0:5 MU];
  for jj=1:length(IT)
    ii=find(U10s>IT(jj) & isnan(PERC1)==0);
    if length(ii)>10
      PERC1M=median(PERC1(ii));
      PERC2M=median(PERC2(ii));
      disp(['For U10s> ' num2str(IT(jj)) ', we have speed ratio = ' sprintf('%5.2f',PERC1M) '% and projected speed ratio = ' sprintf('%5.2f',PERC2M) '%'])
    end
  end
end
