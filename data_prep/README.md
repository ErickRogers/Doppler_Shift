Contents:
* ./one_HF_spectrum_one_spotter.m : processes one spotter file that has already been converted to .mat format
* ./call_one_HF_spectrum_one_spotter.m : wrapper for one_HF_spectrum_one_spotter.m : loops over available files.
* ./process_many_json_files.m : wrapper for ./read_one_json.m
* ./read_one_json.m : processes json spotter file to .mat format
* ./wind_and_drift_projection_scalar.m : ancillary function for use in one_HF_spectrum_one_spotter.m : computes drift in wind direction

Work that you need to do before running any of these scripts: You need a .mat file that contains the winds that have already been co-located with the Spotter x/y/t . The script one_HF_spectrum_one_spotter.m uses this .mat file:

Also, the scripts with "json" in the filename are, of course, specifically for the case where you are provided with Sofar json files. If your Sofar files are in another format, you'll obviously need to make adjustments.

I was not given permission to redistribute the Sofar dataset used in the paper.
Sofar suggests that you instead use this dataset: https://registry.opendata.aws/sofar-spotter-archive/



