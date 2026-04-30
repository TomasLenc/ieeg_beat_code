function c = get_lut_color(roi_label)
c = [1, 0, 0]; 

lut = load('lut.mat');

idx = find(strcmp(lut.label, roi_label));

if ~isempty(idx)
   c = lut.color(idx, :) / 255;   
else
    return
end

