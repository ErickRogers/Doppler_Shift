# Doppler_Shift
Code associated with paper at https://arxiv.org/abs/2607.08947 , under revision as of 11/24/2026

List of files:

Files that are always used:
* ./Doppler_shift_one_Spotter_A1_Bx.m : primary function script to Doppler shift a single Spotter spectrum.
* ./calc_fin_vector.m : function script to compute intrinsic frequency.

Files that are used in quick demo that you can run:
* ./Method2_demo.m : primary script: It is set up to use Method 2 (NB: it is trivial to change it to use Method 1 since Method 1 requires fewer input variables than Method 2.)
* ./compute_transition_frequency.m: compute frequency of transition from f-4 to f-5, used by Holthuijsen_Forristall_spectrum.m
* ./detect_matlab_or_octave.m: used by ./Method2_demo.m because there is a slight difference in syntax for plots, matlab vs. octave
* ./Holthuijsen_Forristall_spectrum.m: compute a parametric spectrum (not a full spectrum, just equilibrium and saturation range)
* ./Ustar_fn_Hwang_mod_v2.m: compute ustar, used by Holthuijsen_Forristall_spectrum.m
* ./sample_data/Ef.0.2Hz.0.67Hz_drmax3.5.buoy2.U10_10.rep18219.mat : sample Spotter spectrum, used in demo

Files that are used to process a large Spotter dataset. (NB: You need to create the large Spotter dataset before using this. The required variables are explained in the in-line comments of call_Doppler_shift_A1_Bx.m)
* ./call_call_Doppler_shift_A1_Bx.m : primary wrapper script. It is very simple. You set some parameters to describe the dataset to be processed and it looped over the U10 bins and calls call_Doppler_shift_A1_Bx.m.
* ./call_Doppler_shift_A1_Bx.m : script that loops over spectra within the U10 bin and calls Doppler_shift_A1_Bx.m

About the large Spotter dataset. I cannot share this because Sofar did not give me permission to redistribute it. They suggested that I instead point people to their data archive: https://registry.opendata.aws/sofar-spotter-archive/ . Unfortunately, this means that users will need to do the colocation of winds and computation of buoy drift on their own.
