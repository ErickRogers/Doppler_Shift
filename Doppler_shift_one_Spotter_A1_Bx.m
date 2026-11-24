function [EfaEfd] = Doppler_shift_one_Spotter_A1_Bx(fd, Efd_input, U10, test_freq, PROJs, buoytype)
%% Doppler_shift_one_Spotter_A1_B1_B2.m
%% octave code originally by Erick Rogers, NRL 7322, Feb. 2026
%% ChatGPT (OpenAI) vectorized the two scripts. Oct. 2026
%% ChatGPT (OpenAI) merged two scripts into a single script. Nov. 2026
%%
%% Merged version of the following methods:
%%   * Method B1 ("Method 1" in the paper): call with four inputs.
%%   * Method B2 ("Method 2" in the paper): provide optional input PROJs.
%%
%% Usage:
%%   EfaEfd = Doppler_shift_one_Spotter_A1_B1_B2(fd, Efd_input, U10, test_freq)
%%       Uses Method B1.
%%
%%   EfaEfd = Doppler_shift_one_Spotter_A1_B1_B2(fd, Efd_input, U10, test_freq, PROJs)
%%       Uses Method B2. buoytype is optional and is used only in saved
%%       diagnostics if the solution fails.
%%
%%   EfaEfd = Doppler_shift_one_Spotter_A1_B1_B2(fd, Efd_input, U10, test_freq, PROJs, buoytype)
%%       Uses Method B2 with buoytype included in any diagnostic filename.

%% Select method. The B2-only arguments are optional inputs.
if nargin < 5 || isempty(PROJs)
  method = 'B1';
  PROJs = [];
  buoytype = [];
else
  method = 'B2';
  if nargin < 6 || isempty(buoytype)
    buoytype = NaN; % used only in Method B2 diagnostic output
  end
end

%% QC setting "ESMALL" is hardwired. It can be changed to a function argument, if a user prefers.
ESMALL = 1e-10;

%% fd is drifter frequency grid
nf = length(fd);

%% find frequency bin that matches my test frequency. This will give an error if the test frequency is not in the grid.
df = abs(fd-test_freq);
is = find(df==min(df));
is = is(1);
is_fdtf = is; % save for later (index of test frequency in original drifter freq grid)

%% If QC fails, bail out and give an array with NaN
%% The original spectrum will still exist in the dataset, so it is up to the calling program to remove it.
if Efd_input(is_fdtf) < ESMALL
  disp('E(f) is small, so we will return without doing computations.')
  EfaEfd = Efd_input.*NaN;
  return
end
clear df is

%% Make a copy of the input array. Method B2 retains Efd_input for diagnostics.
Efd = Efd_input;

%% Doppler equation requires k which requires intrinsic frequency fi, so we must compute fi.

%% NB: Wu (1983) says that the 3% rule includes both Eulerian current and Stokes drift.

%% Doppler shift fd==>fi
%%  relevant U: Udrift-Uslab : Method A1: approximate this using windage=1% of U10
%%  drifter-observed frequency fd
%%  intrinsic frequency fi

if strcmp(method, 'B1')
  %% Method B1 (original Doppler_shift_one_Spotter_A1_B1.m):
  %% "A1_B1" is "Method 1" in the paper.
  %% For sake of clarity, define the velocities.
  Ufixed = 0; % it's fixed. it doesn't move
  Uslab = 0.03*U10; % assume : (1) the "3% of wind rule" says that Lagrangian = Stokes + Eulerian = 3% of U10
  Udri = 0.04*U10; % assume (1) the "3% of wind rule" says that Stokes + Eulerian is 3% of U10 and 2) windage is 1% of U10

  Ur1 = Udri-Uslab; % windage, 1% of wind speed
else
  %% Method B2 (original Doppler_shift_one_Spotter_A1_B2.m):
  %% "A1_B2" is "Method 2" in the paper.
  %% 3 components were vectorized by genai.mil
  %% Doppler_shift_one_Spotter_A1_B1.m : drift is based on "4% of wind" rule
  %% Doppler_shift_one_Spotter_A1_B2.m : drift is based on "component of buoy drift along the axis of the wind" used with the "1% of wind" rule

  %% Here is the long way to get Ur1:
  %%  Ufixed=0; % it's fixed. it doesn't move
  %%  Uslab=0.03*U10; % assume : (1) the "3% of wind rule" says that Lagrangian = Stokes + Eulerian = 3% of U10
  %%  Udri=0.04*U10; % assume (1) the "3% of wind rule" says that Stokes + Eulerian is 3% of U10 and 2) windage is 1% of U10
  %%  Ur1=Udri-Uslab; % windage, 1% of wind speed

  %% Short way to get Ur1:
  Ur1 = 0.01*U10; % this is windage=0.01*U10

  %% Here is the sign convention used in calc_fin.m:
  %% given : fin=fob+ku/(2*pi)
  %% In our present case, fob is fd
end

%% We compute fi by calling calc_fin.m
fi = calc_fin_vector(fd, Ur1);

%% compute wavenumber
grav = 9.81;
kwave = (fi.*(2*pi)).^2./grav; % deep water assumed
clear grav

%% compute absolute frequency fa
%% Note difference:
%%  * Method B1: Ur2=Uslab-Ufixed, fa(is)=fi(is)+kwave(is)*Ur2/(2*pi); % DS from intrinsic to fixed
%%  * Method B2: Ur2=Udri-Ufixed,  fa(is)=fd(is)+kwave(is)*Ur2/(2*pi); % DS from drifter to fixed
%% convention: u is positive when k and u are aligned
%%    example: a drifter is moving faster than the fixed point
%%             positive u : waves appear longer to drifter
%%                          waves appear shorter to fixed point
%%                          fa>fd
if strcmp(method, 'B1')
  %% Method B1: See also notes in Doppler_shift_Spotter_v2.m for different but equivalent calculation.
  Ur2 = Uslab-Ufixed;
  fa = fi + kwave.*(Ur2/(2*pi));

  %% With Method 1, it is a blue shift both times. Example:
  %% fd = 0.369 Hz
  %% fi = 0.400 Hz
  %% fa = 0.430 Hz
else
  %% Method B2: Doppler shift fd==>fa.
  %% Relevant U: Udrift-Ufixed=Udrift, and for this I use PROJs.
  Ur2 = PROJs; % This is Ur2=Udri-Ufixed, with Udri=PROJs and Ufixed=0
  fa = fd + kwave.*(Ur2/(2*pi));
end

%% compute df using finite differencing
dfa = [fa(2)-fa(1), ...
       (fa(3:end)-fa(1:end-2))/2, ...
       fa(end)-fa(end-1)];
dfd = [fd(2)-fd(1), ...
       (fd(3:end)-fd(1:end-2))/2, ...
       fd(end)-fd(end-1)];

if strcmp(method, 'B2')
  %% Method B2 only: When Ur2 is large and negative, e.g. -1.8 m/s,
  %%   the fa vs fd plot is non-monotonic. Energy
  %%   at two values of fd contribute to the energy at fa.
  %%   This can cause a singularity in the Jacobian which causes
  %%   my transformed spectrum to be wonky. E(fa)dfa=E(fd)dfd, where dfa approaches zero
  %%   so E(fa)=E(fd)*inf
  %%   I set the values of fa for these cases to NaN.
  for is = 1:nf
    if dfa(is) < dfd(is)*0.1
      fa(is) = NaN;
      dfa(is) = NaN;
    end
  end
end

%% Jacobian
dfddfa = dfd./dfa;

%% Now we are done with fi and kwave, so we clear them for safety
clear fi kwave

%% Compute Efa by applying Jacobian
Efa = Efd.*dfddfa;

%% Verify Jacobian
m0a = sum(Efa.*dfa);
m0d = sum(Efd.*dfd);
if abs(m0a-m0d) > 1e-5
  error('Jacobian error')
end

%% Now remap to original discretization. This isn't strictly necessary...
%% Method B2 note: ...a plot of fa vs Efa and fd vs Efd on the same axis is valid....
%% ...but remapping allows computation of ratios, etc.
X = fa;
Y = Efa;
XI = fd;

%% Bail out, if appropriate
if min(isnan(fa)) == 1
  disp('fa is just NaNs, so we will return without doing computations.')
  EfaEfd = Efd.*NaN;
  return
end
if min(isnan(Efa)) == 1
  disp('Efa is just NaNs, so we will return without doing computations.')
  EfaEfd = Efd.*NaN;
  return
end

clear fa % so that I don't accidentally use it below

if max(isnan(X)>0) %% truncate X before calling interp1...otherwise it gives NaNs
  ii = find(isnan(X)==1);
  i1 = min(ii);
  X = X(1:i1-1);
  Y = Y(1:i1-1);
end

%% call interp1
if isempty(X)
  disp('X is empty, so we will return without doing computations.')
  EfaEfd = Efd.*NaN;
  return
end
YI = interp1(X, Y, XI);
Efa_on_fd_grid = YI;
clear X Y XI YI

%% change from "NA" to "NaN"
ii = find(isnan(Efa_on_fd_grid));
Efa_on_fd_grid(ii) = NaN;
%% change from "inf" to "NaN"
ii = find(Efa_on_fd_grid>1e+10);
Efa_on_fd_grid(ii) = NaN;
clear ii

%% compute ratio
%% Prior code had a restriction on EfaEfd>2
%% I removed this 2/26/2026, since U10>20 can give very large shifts
EfaEfd = Efa_on_fd_grid ./ Efd;
ii = find(Efa_on_fd_grid<ESMALL | Efd<ESMALL);
EfaEfd(ii) = NaN;

if strcmp(method, 'B2')
  %% Method B2 only: If we failed to get a solution, save diagnostics so that we can understand the failure.
  %%   (Even if we can't prevent the failure, it is good to understand why it happens.)
  if isnan(EfaEfd(is_fdtf)) == 1
    disp(['U10 = ' num2str(U10) ' ; PROJs = ' num2str(PROJs) ' ; Ur1 = ' num2str(Ur1) ' ; Ur2 = ' num2str(Ur2) ' ; failure in Doppler_shift_one_Spotter_v2.m. saving diagnostics.'])
    %
    str = ['save -v7 failure.U10_' num2str(U10) '.PROJs_' num2str(PROJs) '.buoy' num2str(buoytype) '.mat fd Efd_input U10 PROJs']; disp(str); eval(str)
  end
end
