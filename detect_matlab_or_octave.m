
function env = detect_matlab_or_octave()
%% detect_matlab_or_octave Detect whether code is running in MATLAB or GNU Octave.
%%
%% Created by ChatGPT (OpenAI)
%%
%% Output:
%%   env - Structure with fields:
%%       name      : 'MATLAB' or 'GNU Octave'
%%       isMatlab  : true when running in MATLAB
%%       isOctave  : true when running in GNU Octave
%%       version   : version string reported by the active environment

%% Example 1:
%%   env = detect_matlab_or_octave();
%%   if env.isOctave
%%       disp('Running under GNU Octave.');
%%   elseif env.isMatlab
%%       disp('Running under MATLAB.');
%%   end

%% Example 2:
%%   env = detect_matlab_or_octave();
%%   if env.isOctave
%%     is_octave=1;
%%     SOFTWARE='octave';
%%   else
%%     is_octave=0;
%%     SOFTWARE='matlab';
%%   end

    %% OCTAVE_VERSION is a GNU Octave built-in that MATLAB does not provide.
    isOctave = (exist('OCTAVE_VERSION', 'builtin') ~= 0);

    if isOctave
        env = struct( ...
            'name', 'GNU Octave', ...
            'isMatlab', false, ...
            'isOctave', true, ...
            'version', OCTAVE_VERSION);
    else
        %% If the code is not executing in GNU Octave, treat it as MATLAB.
        env = struct( ...
            'name', 'MATLAB', ...
            'isMatlab', true, ...
            'isOctave', false, ...
            'version', version);
    end
end

