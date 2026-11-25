
clear

% https://www.mathworks.com/help/matlab/ref/jsondecode.html
% Introduced in R2016b  
if exist('jsondecode')==0
  error('jsondecode Introduced in R2016b')
end

listfile='listfile.txt';
str=['!ls *.json > ' listfile];disp(str);eval(str)

fid = fopen(listfile,'r');

processed=0;

for ifile=1:999999
  
  nextline=fgets(fid);
  if nextline == -1
    
    break
    
  else % valid file name
    
    jsonfile=nextline(1:end-1);
    
    if exist(jsonfile)~=2
      error([jsonfile ' not found.'])
    end
    
    % identify file id
    ii=strfind(jsonfile,'_frequency_data.json');
    fileid=jsonfile(1:ii-1);
    
    % process file
    read_one_json(fileid)
    
  end
  
end

fclose(fid);
