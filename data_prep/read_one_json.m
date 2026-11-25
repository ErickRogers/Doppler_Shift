function read_one_json(fileid)

clear

% https://www.mathworks.com/help/matlab/ref/jsondecode.html
% Introduced in R2016b  
if exist('jsondecode')==0
  error('jsondecode Introduced in R2016b')
end
  
% set file name
jsonfile = [fileid '_frequency_data.json'];
matfile=[fileid '.mat'];

if exist(jsonfile)==2
  disp([jsonfile ' found.'])
else
  error([jsonfile ' found.'])
end

% open, read, close file
fid = fopen(jsonfile); 
raw = fread(fid,inf); 
fclose(fid); 

% convert to string
str = char(raw'); 
clear raw

% convert to structure
val = jsondecode(str);
clear str             

% convert to individual variables
nt=length(val);
isave=0;
for irec=1:nt
  
  xtmp=val(irec).longitude;
  ytmp=val(irec).latitude;
  if isempty(ytmp)==1 |  isempty(xtmp)==1
    continue % cycle without saving
  end

  % nan check added 8/4/2025
  if isnan(ytmp)==1 |  isnan(xtmp)==1
    continue % cycle without saving
  end
  
  % looks ok, so save it
  isave=isave+1;

  lon(isave)=xtmp;
  lat(isave)=ytmp;
  
  % the following does not work, since nf can vary within the file:
%  freq(:,irec)=val(irec).frequency;

  DSPR{isave}=val(irec).directionalSpread;
  Ef{isave}=val(irec).varianceDensity;
  a1{isave}=val(irec).a1;
  b1{isave}=val(irec).b1;
  a2{isave}=val(irec).a2;
  b2{isave}=val(irec).b2;
  df{isave}=val(irec).df;
  dir{isave}=val(irec).direction;
  freq{isave}=val(irec).frequency;
  
  spotter_time{isave}=val(irec).timestamp;
  spotter_id{isave}=val(irec).spotterId;
  
end
clear val irec fid ans isave

str=['save -v7 ' matfile];disp(str);eval(str)

