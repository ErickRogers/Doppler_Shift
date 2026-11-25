
clear

f1=0.20; f2=0.67; iplot=0; verbose=0;

listfile='HF_spectrum_listfile.txt';

%% NB: We are just using the list of json files to have a full list of expected .mat files. We are not processing the json files here.

str=['find . -name ''*_frequency_data.json'' > ' listfile];disp(str);system(str)

fid = fopen(listfile,'r');

drift_cutoff=3.5;

ignore_warning=0;
for ifile=1:999999
  
  disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
  disp(['At the top of ifile=' num2str(ifile)])

  nextline=fgets(fid);
  if nextline == -1
    disp(['reached end of ' listfile])    
    break
  end  
  
  jsonfile=nextline(1:end-1); % to avoid newline character
  
  if exist(jsonfile)==2
    disp([jsonfile ' found.'])
  else
    error([jsonfile ' not found.'])
  end

  matfile=strrep(jsonfile,'_frequency_data.json','.mat');
  if exist(matfile)==2
    disp([matfile ' found.'])
  else
    error([matfile ' not found.'])
  end
  
  one_HF_spectrum_one_spotter(matfile,f1,f2,drift_cutoff,verbose,iplot)
  
end

fclose(fid);
