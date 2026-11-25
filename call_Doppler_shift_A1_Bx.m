function call_Doppler_shift_A1_Bx(buoytype,U10wanted,test_freq,ISKIP,Bmethod)

%% Mon Feb 23 01:30:02 PM CST 2026
%% Purpose: Loop over Spotter spectra within a U10 bin and call Doppler_shift_A1_Bx.m

%% call_Doppler_shift_one_Spotter.m
%% octave code by Erick Rogers, NRL 7322, Feb. 2026
%% updated Oct. 2026.
%% updated again Nov 2026: vectorized by genai.mil and inputs are broken out into .mat files
%% Octave bin file is no longer used, so either octave or matlab can be used for this now (matlab is faster).

%% Test settings are given below.
%% If you want to run as a standalone script, uncomment these lines and comment the function line above.
%% clear
%% buoytype=2; % buoy type is 1 or 2
%% U10wanted=2; % This is the 10-m wind speed bin
%% test_freq=0.4;
%% ISKIP=1; % Set to ISKIP=1 to process all your data. Set to a larger number if you want to sub-sample your data (e.g., using one of every 3 records), to speed things up: this is probably not necessary unless you are using octave (slower) and impatient.
%% Bmethod=1; % indicates if Method 1 (wind-based estimate of drift) or Method 2 (position-based estimate of drift) is used

%% The function arguments above are only the settings.
%% The data is pulled in by loading a .mat file below. 
%% For a different dataset, you will need a different set of .mat files
%% Here are the contents of the .mat files:
%%  * the frequency bins of the drifter spectra
%%  * spectral density from the drifter
%%      (as a cell array, one spectrum per cell index)
%%  * the buoy drift speed, projected along the axis of the wind
%%      (this is only used for Method B2)
%%  * the 10-m neutral wind speed from ERA5, co-located with the buoy position
%%      (you can use another source for 10-m wind speed, of course)

%% Here is how they look in octave:
%%   Attr   Name              Size                     Bytes  Class
%%   ====   ====              ====                     =====  ===== 
%%          fd                1x471                     3768  double
%%          Ef_parcel         1x85988              324002784  cell
%%          PROJs_parcel      1x85988                 687904  double
%%          U10_parcel        1x85988                 687904  double

disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
disp('INPUTS are.....')
disp(['buoytype = ' num2str(buoytype)]) % There are 2 Spotter buoy types, with different fmax and df
disp(['U10wanted = ' num2str(U10wanted)]) % This script runs for a single U10 bin
disp(['test_freq = ' num2str(test_freq)]) 
disp(['ISKIP = ' num2str(ISKIP)]) % For U10 bins with many data points, we have the option to process only a fraction, e.g., IKSIP=5 means that we process 1 data point out of 5. For U10 bins with fewer data points, this setting is disregarded.

%% Some settings are hardwired, but can be changed to function arguments as the user prefers
iprint=0;
drmax=3.5; % maximum drift permitted
myformat=['%7.3f']; % used in prints

%% Old approach: for every U10 bins, load entire dataset and down-select on U10 that I want. (this takes 10 to 17 sec)
%% New approach: In a preliminary step, I split up the big files into smaller files that already have the U10 down-select,
%%    and just load the smaller file.
tic
disp('loading small file')
%% Load a file that contains 4 variables: Ef_rep, U10_rep, PROJs_rep, and fd (their meaning is explained below)
inmatfile=['../parceled_data/Ef.0.2Hz.0.67Hz_drmax' num2str(drmax) '_9months.buoy' num2str(buoytype) '.U10_' sprintf('%2.2d',U10wanted) '.mat'];
if exist(inmatfile)==2
  disp([inmatfile ' found.'])
else
  error([inmatfile ' not found.'])
end
str=['load ' inmatfile ' U10_parcel Ef_parcel fd'];disp(str);eval(str)
%% Method A1 B2 : previously pulled from giant bin file:  fnew U10x U10y Ef_save fmax_spotter PROJs'];disp(str);eval(str)
toc

%%          Efd         spectral density reported by the drifter, E(f) in m2/Hz
%%          PROJs       buoy drift speed along the axis of the wind direction, in m/s
%%          U10         10-m wind speed in m/s. (I use the 10-m neutral wind speed.)
%%          fd          frequency as perceived from the drifter frame of reference

if length(U10_parcel)==0
  disp(['length(U10_parcel) = ' num2str(length(U10_parcel))])
  disp(['no data found. returning'])
  return
end

%% fd denotes drifter frequency
%% rename the other two variables
U10=U10_parcel; clear U10_parcel %% U10 is magnitude of wind speed
Ef_save=Ef_parcel ; clear Ef_parcel

disp(['size(U10) = ' num2str(size(U10))])
disp(['size(Ef_save) = ' num2str(size(Ef_save))])

if Bmethod==2
  str=['load ' inmatfile ' PROJs_parcel'];disp(str);eval(str)
  PROJs=PROJs_parcel ; clear PROJs_parcel
  disp(['size(PROJs) = ' num2str(size(PROJs))])
end

%% find frequency bin that matches my test frequency. This will give an error if the test frequency is not in the grid.
df=abs(fd-test_freq); 
is=find(df==min(df));
is=is(1);

%% For smaller datasets, we don't follow the ISKIP instruction, but skip enough to get the dataset down to 20k points
%% If the U10 bin already contains few points, then ISKIP=1, so the entire dataset is used.
%% The short version of this is: ISKIP=min([ISKIP round(length(U10)/20e+3)]);
%% 20k takes ~10 minutes, which is OK
BB=round(length(U10)/20e+3);
BB=max([1 BB]); % don't let it be zero
if BB<ISKIP
  ISKIP=BB;
  disp(['using ISKIP = ' num2str(ISKIP) ' instead.']);
end

%% Now that we have ISKIP, we know the output file name.

%% If the output file already exists, return without doing anything
outmatfile=['EfDSTF.buoy' num2str(buoytype) '.U10_' sprintf('%2.2d',U10wanted) '.freq_' num2str(test_freq) '.ISKIP_' num2str(ISKIP) '.Method_' num2str(Bmethod) '.mat'];
if exist(outmatfile)==2
  disp([outmatfile ' already exists. returning'])
  return
end

%% In prior versions of the script, I aborted calcs for cases where the population is less than a specified cutoff (n=45)
%% However, since we are keeping track of population in bins, we can defer this operation.
tic
%% pre-allocate
irec_list = 1:ISKIP:numel(U10);
nmax = numel(irec_list);
nf = numel(fd);
U10_save    = NaN(nmax, 1);
EfaEfd_save = NaN(nmax, nf);
EfaEfdTF    = NaN(nmax, 1);
EfTF        = NaN(nmax, 1);
EfDSTF      = NaN(nmax, 1);
icount=0;
%% This is the primary loop: call "Doppler_shift_one_Spotter.m"
for irec=1:ISKIP:length(U10)
  %% Notice that we don't pass Bmethod to Doppler_shift_one_Spotter_A1_Bx.m.
  %% Doppler_shift_one_Spotter_A1_Bx.m knows which method to use, based on the number of arguments provided to it.
  %% Thus, if you want to use Method 1, DO NOT provide PROJs(irec).
  if Bmethod==1
    EfaEfd=Doppler_shift_one_Spotter_A1_Bx(fd,Ef_save{irec},U10(irec),test_freq);
  elseif Bmethod==2
    EfaEfd=Doppler_shift_one_Spotter_A1_Bx(fd,Ef_save{irec},U10(irec),test_freq,PROJs(irec),buoytype);
  end
  if isnan(EfaEfd(is))==0 % We use "icount" counter to omit cases for which the script returns Efa/Efd=NaN.
    icount=icount+1;
    if mod(icount,100)==0
      disp(['icount = ' num2str(icount) ' ; irec = ' num2str(irec) ' out of ' num2str(length(U10)) ' ; EfaEfd at fd=' num2str(test_freq) ' Hz is ' sprintf(myformat,EfaEfd(is))])
    end
    %% Save some arrays for storage in .mat file
    U10_save(icount)=U10(irec);
    EfaEfd_save(icount,:)=EfaEfd; % Full array of Efa/Efd
    EfaEfdTF(icount)=EfaEfd(is); % Efa/Efd just at the test frequency
    EfTF(icount)=Ef_save{irec}(is); % Ef at the test frequency "TF" = test frequency
    EfDSTF(icount)=Ef_save{irec}(is)*EfaEfd(is); % Efa at the test frequency. "DSTF" = Doppler-shifted test frequency
    %% NB: saving EfaEfdTF, EfTF, and EfDSTF is redudant, since EfaEfdTF=EfDSTF/Ef_save
  end
end
toc
%% Method B1, non-optimized, U10=10, ISKIP=3, 3172 sec in octave
%% Method B1, optimized,     U10=10, ISKIP=3, 190 sec in octave
%%   "           "               "            22 sec in matlab
%% Method B2     "               "            22 sec in matlab

%% If no valid data, don't proceed.
if icount==0
  disp(['icount = ' num2str(icount)])
  disp(['no data found. returning'])
  return
end

%% Remove unused preallocated rows before statistics and saving.
%% This avoids repeated memory reallocations/copies, especially for EfaEfd_save, which stores a complete spectrum for every accepted record.
U10_save    = U10_save(1:icount);
EfaEfd_save = EfaEfd_save(1:icount,:);
EfaEfdTF    = EfaEfdTF(1:icount);
EfTF        = EfTF(1:icount);
EfDSTF      = EfDSTF(1:icount);

disp(['EfaEfd at ' num2str(test_freq) ' Hz, after removing NaNs: '])
disp(['mean : ' num2str(mean(EfaEfdTF))])
disp(['median : ' num2str(median(EfaEfdTF))])

%% For reference, running this script made w/ the original methods gives arrays shaped like size=[1 n]
if size(U10_save)==size(EfTF)
  isok=1;
else
  error('size(U10_save).ne.size(EfTF)')
end
if size(U10_save)==size(EfDSTF)
  isok=1;
else
  error('size(U10_save).ne.size(EfDSTF)')
end

%% Note that filename indicates test frequency, but EfaEfd_save is available and valid for other frequencies
%%   ....with the caveat that we only did the NaN check for the test freq
str=['save -v7 ' outmatfile ' fd U10_save EfaEfd_save EfTF EfDSTF'];disp(str);eval(str)
