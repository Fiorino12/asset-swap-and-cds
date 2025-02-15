function [datesCDS, survProbs, intensities] = bootstrapCDS(datesDF, discounts, datesCDS, spreadsCDS, flag, recovery)
%   Given discounts term structure from vanilla option, it derives survival
%   probabilities and intensities. Moreover, it returns the complete set
%   of coupon payment dates 
%
%   INPUT
%   datesDF: structure with discount factor dates 
%   discounts: bootstraped discount factors term structure
%   datesCDS: given annual bond payments dates structure
%   spreadsCDS: complete set of CDS 
%   flag: auxiliar variable to select the computation method 
%
%   flags legenda:
%   flag == 1, approximated technique
%   flag == 2, exact technique
%   flag == 3, JT technique
%
%   recovery: recovery rate value 
%
%   OUTPUT
%   datesCDS:  complete annual bond payments dates structure
%   survProbs:  calculated survival probabilities 
%   intensities:  intensities calculated via the selected technique 
%% Calculations

% Time conventions
Eur360 = 6;
Act365 = 3; 

% Survival probabilities intitialization
survProbs = 1;

% Payment dates 
dates_swap=[datesCDS(1), datesDF(12:17)];

% first discount interpolation
discountfirstswap = inter_first_disc(datesDF,discounts, dates_swap, datesDF(1));

% Adding settlement date 
dates_swap = [datesDF(1), dates_swap];
discount_swap = [discountfirstswap; discounts(12:17)]; 
year_frac = yearfrac(dates_swap(1:end-1),dates_swap(2:end),Eur360);

% Selecting the desired technique 

if (flag == 1 ) % APPROXIMATED 

   % Compute survival probabilities solving a linear equation
   for i=1:7
       coeff(1) = spreadsCDS(i)*year_frac(i)*discount_swap(i)+(1-recovery)*discount_swap(i);
       coeff(2) = sum(spreadsCDS(i)*year_frac(1:i-1).*discount_swap(1:i-1)'.*survProbs(2:end))-(1-recovery)*sum(discount_swap(1:i-1)'.*(survProbs(1:i-1)-survProbs(2:i)))-discount_swap(i)*survProbs(end)*(1-recovery);
       coeff = [coeff(1), coeff(2)]; 
       survProbs = [survProbs, roots(coeff)];
   end
   
   % Intensities derivation
   year_frac_ = yearfrac(dates_swap(1:end-1),dates_swap(2:end),Act365);
   intensities = - log(survProbs(2:end)./survProbs(1:end-1))./year_frac_; 
end 

if (flag == 2 ) % EXACT

    % Compute survival probabilities solving a linear equation
   for i=1:7
       coeff(1) = spreadsCDS(i)*year_frac(i)*discount_swap(i)+(1-recovery)*discount_swap(i)-year_frac(i)/2*discount_swap(i)*spreadsCDS(i);
       coeff(2) = sum(spreadsCDS(i)*year_frac(1:i-1).*discount_swap(1:i-1)'.*survProbs(2:end))-(1-recovery)*sum(discount_swap(1:i-1)'.*(survProbs(1:i-1)-survProbs(2:i)))-discount_swap(i)*survProbs(end)*(1-recovery)+year_frac(i)/2*discount_swap(i)*survProbs(i)*spreadsCDS(i)+spreadsCDS(i)*sum(discount_swap(1:i-1)'.*(survProbs(1:i-1)-survProbs(2:i)));
       coeff = [coeff(1), coeff(2)]; 
       survProbs = [survProbs, roots(coeff)];
   end
   
   % Intensities derivation
   year_frac_ = yearfrac(dates_swap(1:end-1),dates_swap(2:end),Act365);
   intensities = - log(survProbs(2:end)./survProbs(1:end-1))./year_frac_; 
end 

if (flag==3) % JARROW-TURNBALL

    % JT Relationship 
    intensities = spreadsCDS./(1-recovery);

    % Retrieve probabilities from intensities
    for i=1:7
        survProbs = [survProbs, exp(-intensities(1:i)*year_frac(1:i)')];
    end

end
end % Return results relative to the selected methodology