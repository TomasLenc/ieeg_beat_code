function res=myNum2str(in,varargin)
% 
% Input
% -----
%     in :    numeric vector 
% 
%     varargin: 
%               1st varargin argument is optional delimiter, e.g. '-'
%     
%     
% Returns
% -------
%     res :   strig where elements of in are in the form: '[x_y_z]'
%     

delim = '_'; 
if ~isempty(varargin)
    delim = varargin{1}; 
end
    


if length(in)==1
    
    res = sprintf('[%g]',in);  
    
else
    res = '['; 
    for i=1:length(in)-1
        res = [ res, sprintf('%g%s',in(i),delim) ]; 
    end
    res = [ res, sprintf('%g]',in(end)) ]; 
 
end

