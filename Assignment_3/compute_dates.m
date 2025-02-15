function [intermediate_dates] = compute_dates(initial_date,final_date)
%   Auxiliar function to retrieve dates when the floating leg
%   is paid with a 3 months step
%
%   INPUT
%   initial date: starting date of the interval
%   final date: ending date of the interval
%
%   OUTPUT
%   intermediate_dates: complete structure of intermediate dates
%% Computation
% Built-in function to calculate dates with a 3 months step 
intermediate_dates = datenum(initial_date:calmonths(3):final_date); 
% Payment dates 
intermediate_dates = intermediate_dates(2:end); 
end