clear

remove_dependency

buoytype=1;
Bmethod=1;
test_freq=0.4;
ISKIP=1; 

for U10=1:30
  call_Doppler_shift_A1_Bx(buoytype,U10,test_freq,ISKIP,Bmethod)
end
