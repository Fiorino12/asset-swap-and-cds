function zRates = zeroRates(dates, discounts)
%   Custom function to compute zero rates from discounts
%
%   INPUT
%   dates: dates' vector of expiries of the instrument of interest
%   discounts: discounts' vector with respect to each corresponding expiry
%
%   OUTPUT
%   zRates = rates' vector resulting from the given discounts
    
    % manually insert settlement date to ensure its presence
    settlement = 733457;
    % computing year fractions
    delta = yearfrac(settlement, dates(1:length(discounts)),3);
    % zero rate computation
    zRates = (-log(discounts)./delta).*100;
end % return zRates