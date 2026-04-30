function TINstruct = TIN(dur,rampdur,freq,No,Es_No,bin_mode,arg7,Fs,SNR_Calc)

%Author: Langchen Fan
%Put into a function by Braden Maxwell, 10/28/2015
% Wideband noise bandwidth modified - 7/5/16 LHC
% Ramp difference between monaural conditions corrected - 7/18/16 LF

% Starting in UR_EAR_2020a, the way the frequency range of the noise is
% specified has changed.  It used to be that there were only two choices:
% narrow- or wide-band noise.  Now, the noise frequency range is specified
% explicitly.

% Argument 7, arg7, can be either a scalar which means:
%   arg7 == 0 => 1/3-octave noise
%   arg7 == 1 => noise freq range = 100-10,000 Hz
% If arg7 has two elements, they are the lower and upper noise frequency range.

Fn = Fs/2; % Nyquist frequency
if isscalar(arg7)
	switch arg7
		case 0
			noise_freqs = freq*2.^([-1 1]/6);
		case 1
			noise_freqs = [100 10000];
	end
	lbw = noise_freqs(1);
	hbw = noise_freqs(2);
	bw = hbw - lbw;
else
	noise_freqs = arg7;
	lbw = noise_freqs(1);
	hbw = noise_freqs(2);
	if lbw == 0
		bw = hbw;
	elseif hbw >= Fn
		bw = Fn - lbw;
	else
		bw = hbw - lbw;
	end
end

npts = dur * Fs;

switch SNR_Calc
    case 0 %Assuming the function is not being used just to calculate SNR        
        %% Generate, filter, and scale noise
%         fres = 1/dur; % frequency resolution of the fft spectrum
        noise = randn(npts,1);
		if lbw == 0
			B = fir1(5000,hbw/Fn); % order of 5000
		elseif hbw >= Fn
			B = fir1(5000,lbw/Fn,'high'); % order of 5000
		else
			B = fir1(5000,[lbw,hbw]/Fn); % order of 5000
		end
        noise = conv(noise,B,'same');
        sc = 20e-6*10^((No + 10*log10(bw))/20); %Noise input as spectrum level
        noise = noise*(sc/rms(noise));  % normalize to RMS=1 and then scale to desired level in Pascals
        
        %% Switch between Binaural and Monaural Experiments, generate scaled tone, adjust noise.
        switch bin_mode
            case 1 %Monaural
                %Noise
                pin_N = noise';
                pin_N = pin_N .* (tukeywin(npts,(2*rampdur)/dur))';
                
                %Tone and Noise
                t = 0:(1/Fs):(dur-1/Fs);
                sc_s = 20e-6*10.^((Es_No + No - 10*log10(dur))/20);
                signal = sc_s*sqrt(2)*sin(2*pi*freq*t);
                pin_TIN = noise' + signal;
                pin_TIN = pin_TIN.*(tukeywin(npts,(2*rampdur)/dur))';
                
            case 2 %Binaural - generate all stimuli necessary for three binaural conditions.
                
                %Generate tone
                t = 0:1/Fs_mod:dur-1/Fs_mod;
                sc_s = 20e-6*10.^((Es_No + No - 10*log10(dur))/20);
                signal = sc_s*sqrt(2)*sin(2*pi*freq*t);
                
                %For pin_N to both ears
                pin_N = noise'; %LHC
                pin_N = pin_N .* (tukeywin(npts,(2*rampdur)/dur))';
                
                %For pin_NoSo to both ears
                pin_NoSo = noise' + signal;
                pin_NoSo = pin_NoSo.*(tukeywin(npts,(2*rampdur)/dur))';
                
                %For pin_NoSo to one ear and pin_NoSpi to opposite ears
                pin_NoSpi = noise' - signal;
                pin_NoSpi = pin_NoSpi.*(tukeywin(npts,(2*rampdur)/dur))';
        end
        
        switch bin_mode
            case 1
                TINstruct.pin_N = pin_N;
                TINstruct.pin_TIN = pin_TIN;
            case 2
                TINstruct.pin_N = pin_N;
                TINstruct.pin_NoSo = pin_NoSo;
                TINstruct.pin_NoSpi = pin_NoSpi;
        end
    case 1 % If function is just used to calculate SNR
       noise_overall_level = No + 10*log10(bw); 
       signal_level = No + Es_No - 10*log10(dur);
       TINstruct.SNR = signal_level - noise_overall_level;
end
