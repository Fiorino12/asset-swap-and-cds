function [discountfirstswap] = inter_first_disc(dates,discounts, couponPaymentDates,setDate)
%   Auxiliar function to interpolate the zero rate on the 19th
%   of February 2019 and compute the discount
%
%   INPUT
%   dates: structure with dates relative to given vanilla options 
%   discounts: discounts term structure 
%   couponPaymentDates: structure with dates when coupons are paid
%   setDate: settlement date
%
%   OUTPUT
%   discountfirstswap: discount factor relative to the 19th of Feb 2019
%% Computation
Act365 = 3; % Act/365 Convention
% Zero rate interpolation
zeroratefirstswap = interp1(dates(7:8), zeroRates(dates(7:8), discounts(7:8)')./100, couponPaymentDates(1), 'linear');
% Discount factor
discountfirstswap = exp(-zeroratefirstswap * yearfrac(setDate, couponPaymentDates(1), Act365));
end