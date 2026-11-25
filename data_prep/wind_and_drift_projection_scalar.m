function [PROJ]=wind_and_drift_projection_scalar(windx,windy,driftx,drifty,verbose)

%% Purpose: find the scalar component of drift that is in the wind direction
  %% Notes: Here, we compute one records at a time.
  %% This is easily done as a matrix operation instead, but if you take that route, be careful with the shapes of arrays, etc.
windvector=[windx windy];
driftvector=[driftx drifty];

DP=dot(windvector,driftvector); % dot product of the two
MAG=sqrt(windx^2+windy^2); % magnitude of windvector, i.e., wind speed
PROJ=DP/MAG; % projection as a scalar

if verbose==1
  disp(['DP= ' sprintf('%5.1f',DP) ' ; MAG= ' sprintf('%5.1f',MAG) ' ; PROJ= ' sprintf('%5.1f',PROJ)])
end
