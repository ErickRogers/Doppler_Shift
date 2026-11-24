function fin = calc_fin_vector(fob, U)

%% Wed Dec  3 12:53:16 PM CST 2025
%% purpose: compute instrinsic frequency fin
%% method : quadratic equation
%% Updated Nov 2026, to vectorize the script (via genai.mil)

%% assumptions: 
%% 1) deep water
%% 2) U and waves are aligned
%% 3) U>=0
%% 4) U<Cg

%% Convention:
%% positive U : waves and U are in same direction
%% negative U : waves and U are in opposite direction

%% U is not the U of the medium (Lagrangian current)
%% U is the U of the instrument relative to the medium

%% There are up to 3 roots
%% 1) U<Cg (shown in green in Doppler_solution_v2.pptx)
%% 2) Cg<U<C (shown in red in Doppler_solution_v2.pptx)
%% 3) C<U (negative frequencies: observer is overtaking the crests)

%% We only consider (1) in this script.
%% This is the "close" root, meaning that this is the intrinsic frequency that is closest to the drifter frequency.

  grav = 9.81;

  %% U may be scalar; fob may be a vector.
  A    = 2*pi*U / grav;
  TERM = 1 - 4*A .* fob;

  %% Initialize invalid cases as NaN.
  fin = NaN(size(fob));

  %% A real quadratic solution exists where the discriminant is nonnegative.
  valid = (TERM >= 0);

  %% Stable quadratic-root expression.
  %% It also gives fin = fob exactly when U = 0.
  fin(valid) = 2 .* fob(valid) ./ (1 + sqrt(TERM(valid)));

end

%% If you want extra protection at the numerical boundary:
%% tol = 100 * eps;
%% TERM(TERM < 0 & TERM > -tol) = 0;
%% valid = (TERM >= 0);
