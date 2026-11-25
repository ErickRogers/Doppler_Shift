%% call_call_Doppler_shift_A1_Bx.m
%% Purpose: Demonstrate wrapper script to call function script(s) in a loop. 

clear

buoytype=1; % buoy type, 1 or 2, as documented in paper
Bmethod=1; % Method 1 or 2, as documented in paper
test_freq=0.4; % test frequency, in Hz
ISKIP=1; % Use value >1 to skip some files , see below
%% For example, set ISKIP=2 to process every other Spotter file. ISKIP>1 is semi-deprecated: the process runs quickly in matlab now, so this is not necessary unless you are running in octave or are impatient to see the results from a huge population of spectra (millions).

for U10=1:30
  call_Doppler_shift_A1_Bx(buoytype,U10,test_freq,ISKIP,Bmethod)
end
