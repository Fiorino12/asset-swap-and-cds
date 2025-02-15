function s_signed_mean = FtD_Pricing(dates, setDate, discounts, discountswap, datesCDS, spreadsCDS_ISP, recovery_ISP, spreadsCDS_UCG, recovery_UCG, rho, N)
%   Computing First to Default price via Monte Carlo simulations 
%
%   INPUT
%   dates: structure with discount factor dates 
%   discounts: bootstraped discount factors term structure
%   discountsswap: discount factors relative to fee leg payments 
%   spreadsCDS_ISP: complete set of CDS for ISP obligor
%   recovery_ISP : recovery rate related to ISP obligor
%   spreadsCDS_UCG: complete set of CDS for UCG obligor
%   recovery_UCG : recovery rate related to UCG obligor
%   rho: correlation factor
%   N: number of simulations
%
%   OUTPUT
%   s_signed_mean: mean of prices from N simulations 
%% Calculation

% fixing seed 
rng(0)

% Time conventions
Eur360 = 6;                                                                % 30/360  Convention
Act360 = 2;                                                                % Act/360 Convention
Act365 = 3;                                                                % Act/365 Convention

% ISP data
% Computing survival probabilities for IS obligor 
[datesCDS_ISP, survProbs_ISP, intensities_ISP] = bootstrapCDS(dates, discounts, datesCDS, spreadsCDS_ISP, 2, recovery_ISP);
survProbs_ISP = survProbs_ISP(1:5);

% UCG data
% Computing survival probabilities for UCG obligor 
[datesCDS_UCG, survProbs_UCG, intensities_UCG] = bootstrapCDS(dates, discounts, datesCDS, spreadsCDS_UCG, 2, recovery_UCG);
survProbs_UCG = survProbs_UCG(1:5);

% general data 
datesCDS = [setDate, datesCDS(1:4)'];
sigma = [1 rho; rho, 1];
u = [0;0];

% initialize fee leg vector
%s_signed=[];
NPV_fee = [];
NPV_cont = []; 
cont = 0;

% MC simulations 
while cont < N

    % Times to default computation: gaussian copula
    y = randn(2,1);
    mu = [0; 0]; 
    x = mu + chol(sigma,"lower")*y;
    u(1) = normcdf(x(1), mu(1), sigma(1,1));
    u(2) = normcdf(x(2), mu(2), sigma(2,2));

    % Determining in which interval the first time to default is
    %initialization to cope with no default case
    ttd_ISP=length(survProbs_ISP); 
    ttd_UCG=length(survProbs_UCG);

   % times to default of both obligors
    for i=1:4
        if (u(1) < survProbs_ISP(i)) && (u(1) > survProbs_ISP(i+1))
            ttd_ISP = i;
        end
        if (u(2) < survProbs_UCG(i)) && (u(2) > survProbs_UCG(i+1))
            ttd_UCG = i;
        end
    end

    %default between first_to_default and first_to_default+1
    first_to_default = min(ttd_ISP,ttd_UCG); 
    

    if first_to_default == length(survProbs_ISP)  % if anyone defaults
        % contingent NPV
        NPV_c = 0;
        % fee NPV
        NPV_f = sum(yearfrac(datesCDS(1:first_to_default-1), datesCDS(2:first_to_default), Eur360) .* discountswap(2:first_to_default));

    else    % at least one defaults 

        if ( first_to_default == ttd_ISP ) % ISP defaults
            % contingent NPV
            NPV_c = (1-recovery_ISP)*discountswap(first_to_default+1);

            % fee NPV
            if first_to_default == 1 % if it defaults beetween the settlement and first year 
                % just accrual
                NPV_f = (yearfrac(datesCDS(first_to_default), datesCDS(first_to_default+1), Eur360)/2) * discountswap(first_to_default+1);
            else
                % accrual + fee
                NPV_f = sum(yearfrac(datesCDS(1:first_to_default-1), datesCDS(2:first_to_default), Eur360) .* discountswap(2:first_to_default)) + (yearfrac(datesCDS(first_to_default), datesCDS(first_to_default+1), Eur360)/2) .* discountswap(first_to_default+1);
            end

        elseif ( first_to_default == ttd_UCG ) % UCG defaults
            % contingent NPV
            NPV_c = (1-recovery_UCG)*discountswap(first_to_default+1);

            %fee NPV
            if first_to_default == 1 % if it defaults beetween the settlement and first year
                % just accrual
                NPV_f = (yearfrac(datesCDS(first_to_default), datesCDS(first_to_default+1), Eur360)/2) * discountswap(first_to_default+1);
            else
                % accrual + fee
                NPV_f = sum(yearfrac(datesCDS(1:first_to_default-1), datesCDS(2:first_to_default), Eur360) .* discountswap(2:first_to_default)) + (yearfrac(datesCDS(first_to_default), datesCDS(first_to_default+1), Eur360)/2) .* discountswap(first_to_default+1);
            end
        end
    end 

    % Saving NPVs
    NPV_cont = [NPV_cont, NPV_c];
    NPV_fee = [NPV_fee, NPV_f];
    % Increment counting factor 
    cont = cont+1; 
end

% Avarage NPVs
NPV_contingent = mean(NPV_cont);
NPV_feeleg = mean(NPV_fee);
% Final spread computation 
s_signed_mean = NPV_contingent/NPV_feeleg; 

end % Returning price