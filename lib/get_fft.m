function [mX,freq,amps,z,zMeterRel,zMeterUnrel] = get_fft(x, fs, frex, idx_meterRel, varargin)

if iscolumn(x)
    x = x'; 
end

N = length(x); 

% parse varargin 
maxfreqlim = fs/2; 
if any(strcmpi(varargin,'maxfreqlim'))
    maxfreqlim = varargin{find(strcmpi(varargin,'maxfreqlim'))+1}; 
end

snr_bins = []; 
if any(strcmpi(varargin,'snr_bins'))
    snr_bins = varargin{find(strcmpi(varargin,'snr_bins'))+1}; 
end

maxfreqidx = round(maxfreqlim/fs*N)+1; 
freq = [0:maxfreqidx-1]/N*fs; 

mX = abs(fft(x))/N*fs; 

mX(1) = 0; 

mX = mX(1:maxfreqidx); 

if ~isempty(snr_bins)
    mX = SNR(mX, snr_bins(1), snr_bins(2)); 
end

if ~isempty(frex)
    frex_idx = round(frex/fs*N)+1; 
    if ~isempty(idx_meterRel)
        idx_meterUnrel = setdiff([1:length(frex)], idx_meterRel); 
    else
        idx_meterUnrel = []; 
    end
else
    frex_idx = []; 
    idx_meterUnrel = []; 
end

amps = mX(:,frex_idx);
z = zscore(amps,[],2); 
zMeterRel = mean(z(:,idx_meterRel),2); 
zMeterUnrel = mean(z(:,idx_meterUnrel),2); 

