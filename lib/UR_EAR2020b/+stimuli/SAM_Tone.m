function stim = SAM_Tone(dur,rampdur,carrier_freq,mod_freq,mod_depth,stimdB,Fs)
%   Sinusoidally modulated Tone 

N = floor(dur*Fs);
t = (0:N-1)/Fs; % time array 
ramp = tukeywin(N,2*rampdur/dur); % ramping function
if mod_depth > -99
    m = 10.^(mod_depth/20); % convert from dB into a linear scalar for modulation depth
else 
    m = 0; % unmodulated case
end
stim = (1 + m*sin(2*pi*mod_freq*t))/2 .* sin(2*pi*carrier_freq*t);
stim = ramp' .* stim;
desired_rms = 20e-6 * 10.^(stimdB/20);
stim = stim.*(desired_rms/rms(stim)); % scale to pascals
