function [dates, discounts]=bootstrap(datesSet, ratesSet)
%   Given depos, futures and swaps rate and their respective dates, this
%   function gives back dates and discounts as vector in output
%
%   INPUT
%   datesSet: structure with dates such as settlement and expiry of each
%   contract
%   ratesSet: structure with all rates (bid and ask) of each instrument
%
%   OUTPUT
%   dates:  vector with all the expiries
%   discounts:  vector with all the discounts of our contract for each
%   expiry

    discounts=zeros(60);
    %bootstrap of depo rates till 19 March 08, date of the first future
    % create the MID rates of the depos
    MIDdepos=(ratesSet.depos(1:3,1) + ratesSet.depos(1:3,2))/2;
    %the first discount is 1 to the settlement date
    dates(1)=datesSet.settlement;
    discounts(1)=1;
    dates(2:4)=datesSet.depos(1:3);
    discounts(2:4)=1./(1+yearfrac(datesSet.settlement,datesSet.depos(1:3),2).*MIDdepos(1:3));
   
    %%future
    MIDfuture=(ratesSet.futures(1:7,1) + ratesSet.futures(1:7,2))/2;
    fwddiscount = 1./(1+yearfrac(datesSet.futures(1,1),datesSet.futures(1,2),2).*MIDfuture(1));
    discounts(5) = discounts(4)*fwddiscount;
    dates(5:11) = datesSet.futures(1:7,2);
    for i=2:7
        fwddiscount = 1./(1+yearfrac(datesSet.futures(i,1),datesSet.futures(i,2),2).*MIDfuture(i));
        if (datesSet.futures(i-1,2) == datesSet.futures(i,1))
            discounts(i+4) = discounts(i+3) * fwddiscount;
        elseif (datesSet.futures(i-1,2) > datesSet.futures(i,1))
            %zerorate = - log(discounts((i+2):(i+3)))./yearfrac(datesSet.settlement, datesSet.futures(i-1,1:2),3);
            zerorate = zeroRates(datesSet.futures(i-1,1:2), discounts(i+2:i+3))./100;
            %zerorateinterpl = zerorate(1) + (zerorate(2)-zerorate(1))*(datesSet.futures(i,1)-datesSet.futures(i-1,1))/(datesSet.futures(i-1,2)-datesSet.futures(i-1,1));
            zerorateinterpl = interp1([datesSet.futures(i-1,1), datesSet.futures(i-1,2)], [zerorate(1), zerorate(2)], datesSet.futures(i,1), 'linear');
            discountinterpl = exp(-yearfrac(datesSet.settlement, datesSet.futures(i,1),3)*zerorateinterpl);
            discounts(i+4) = fwddiscount * discountinterpl;
        else
            %zerorate = - log(discounts((i+2):(i+3)))./yearfrac(datesSet.settlement, datesSet.futures(i-1,1:2),3);
            zerorate = zeroRates(datesSet.futures(i-1,1:2), discounts(i+2:i+3))./100;
            zerorateextrapl = interp1([datesSet.futures(i-1,1), datesSet.futures(i-1,2)], [zerorate(1), zerorate(2)], datesSet.futures(i,1), 'linear', 'extrap');
            discountextrapl = exp(-yearfrac(datesSet.settlement, datesSet.futures(i,1),3)*zerorateextrapl);
            discounts(i+4) = fwddiscount * discountextrapl;
        end
    end

    %%swap
    %zerorate = - log(discounts(7:8,1))./yearfrac(datesSet.settlement, datesSet.futures(4,1:2),3);
    zerorate = zeroRates(datesSet.futures(4,1:2),discounts(7:8,1))./100;
    zeroratefirstswap = interp1(datesSet.futures(4,1:2), [zerorate(1), zerorate(2)], datesSet.swaps(1), 'linear');
    discountfirstswap = exp(-yearfrac(datesSet.settlement, datesSet.swaps(1),3)*zeroratefirstswap);
    MIDswap = (ratesSet.swaps(1:50,1)+ratesSet.swaps(1:50,2))./2;
    delta = [];
    delta(1) = yearfrac(datesSet.settlement, datesSet.swaps(1),6);
    delta(2:50) = yearfrac(datesSet.swaps(1:49),datesSet.swaps(2:50), 6);
    dates(12:60) = datesSet.swaps(2:50);
    for i = 2:50
        discounts(i+10,1) = (1-MIDswap(i).*(delta(1)*discountfirstswap + ((i-1)>=2)*delta(2:i-1) * discounts(12:(i+9),1)))./(1+delta(i)*MIDswap(i));
    end
    discounts = discounts(:,1);
end