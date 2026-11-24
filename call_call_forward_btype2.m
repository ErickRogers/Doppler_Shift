clear

buoytype=2;
Bmethod=2;
test_freq=0.4;
ISKIP=1; 

for U10=1:30
  call_Doppler_shift_A1_Bx(buoytype,U10,test_freq,ISKIP,Bmethod)
end
