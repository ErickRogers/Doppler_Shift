function [Ustar,CD]=Ustar_fn_Hwang_mod_v2(U10)

% source Hwang, "A note on the ocean surface roughness spectrum"
% my email inbox Sep 1 2010.
% Hwang equation 10:
% C = 10- -0.0160U + 0.967U + 8.058 . (10) %  max @ U10=50.33 m/s

% Hwang eq 10  max @ U10=50.33 m/s...don't let U* drop below U* given for this U10

if length(U10)~=1
  error('length(U10)~=1')
end
if U10<0
  error('this is not for u/v vectors!')
end

CD = 1e-4*(-0.0160*U10^2 + 0.967*U10 + 8.058);

Ustar=sqrt(CD)*U10;
if U10 > 50.33             % method 2
   Ustar= 2.02558;         % method 2
   CD=(Ustar/U10)^2;
end                        % method 2



