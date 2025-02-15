% runAssignment3
% Group 7, AY2023-2024
%
% Assignment 3: Credit 
% Ferrari Irene, Fioravanti Mattia, Frigerio Emanuele, Patacca Federico
clear all;
close all;
clc;
%% Settings
formatData='dd/mm/yyyy'; 
%% Read market data
% We consider the interbank market on the 15th of Feb 2008 at 10:45 CET
[datesSet, ratesSet] = readExcelData('MktData_CurveBootstrap', formatData);
%% Bootstrap
% The following function realizes the bootstrap for the Discount Factors'
% curve. The function includes the settlement date in the output dates
% and returns the computed discounts
[dates, discounts] = bootstrap(datesSet,ratesSet);
%% Asset swap 
% Compute the Asset Swap Spread Over Euribor3m given the discounting curve
% vs Euribor 3m and a 3y bond price

% Time conventions
Eur360 = 6;                                                                % 30/360  Convention
Act360 = 2;                                                                % Act/360 Convention
Act365 = 3;                                                                % Act/365 Convention

% Bond parameters
setDate = datesSet.settlement;                                             % issue date 
price_bond = 1.01;                                                         % 101 per cent face value
c = 0.039;                                                                 % coupon rate
couponPaymentDates = datesSet.swaps(1:3);                                  % annual coupon payment dates

% Discounts computation relatively to swaps dates
discountfirstswap = inter_first_disc(dates,discounts, ...
    couponPaymentDates,setDate);
idx = find(dates == couponPaymentDates(end));
discountswap(1) = discountfirstswap;
discountswap(2:length(couponPaymentDates)) = ...
    discounts(idx-length(couponPaymentDates)+2:idx);

% adding settlement date
couponPaymentDates = [setDate; couponPaymentDates]; 

% Price a IB bond 
price_ibond = c*sum(discountswap'.* yearfrac(couponPaymentDates(1:end-1),...
    couponPaymentDates(2:end),6))+discountswap(end); 

% BPV computation:
% Retrieve floating leg payment dates
initial_date = datetime('19-Feb-2008');
final_date = datetime('21-Feb-2011');
intermediate_dates = compute_dates(initial_date,final_date);

% Interpolate rates and compute relative discounts
zRates = zeroRates(dates(2:60)', discounts(2:60));
zero_interp = interp1(dates(2:60),zRates,intermediate_dates)/100; 
disc = exp(-zero_interp.*yearfrac(setDate,intermediate_dates,Act360));
intermediate_dates = [setDate, intermediate_dates];

% BPV
BPV = sum(disc.*yearfrac(intermediate_dates(1:end-1),intermediate_dates(2:end),Act360));

% Obtaining ASW spread from previous prices
spread = (price_ibond-price_bond)/BPV; 

%Printing
disp("RESULTING ASW SPREAD:  ")
spread
%% Case Study: CDS Bootstrap
% Comparing approximated, exact and JT intensitites calculation given the 
% discounts on aforementioned bootstraped curve.
% The obligor is ISP with given recovery and CDS spreads to be interpolated


% Annual bond dates structure
dates_swap = datesSet.swaps(1:7);

% Build a complete set of CDS via a spline interpolation on the spreads

% Given CDS spreads values and recovery for ISP
datesCDS_ = [dates_swap(1:5); dates_swap(end)];
spreadsCDS=[29 32 35 39 40 41]*1e-4;
recovery=0.4;

% interpolation spread 6y 
cdsspread_int=interp1(datesCDS_(4:end),spreadsCDS(4:end)',dates_swap(6),'spline'); %interpretation trade-off
spreadsCDS = [spreadsCDS(1:5), cdsspread_int, spreadsCDS(end)]; 
datesCDS = dates_swap;

% Different calculation methods

disp("Computing via APPROXIMATED TECHNIQUE...")
[datesCDS__, survProbs, intensities1] = bootstrapCDS(dates, discounts, datesCDS, spreadsCDS, 1, recovery);
disp(" ")

disp("Computing via EXACT TECHNIQUE...")
[datesCDS__, survProbs1, intensities2] = bootstrapCDS(dates, discounts, datesCDS, spreadsCDS, 2, recovery);
disp(" ")

disp("Computing via JARROW-TURNBULL TECHNIQUE...")
[datesCDS__, survProbs2, intensities3] = bootstrapCDS(dates, discounts, datesCDS, spreadsCDS, 3, recovery);
disp(" ")

% inserting the settlement date
datesCDS__=[datesSet.settlement; datesCDS__];

% plots survival probabilities and intensities of the three methods
disp("PLOTTING...")
figure;
plot(datesCDS__,survProbs,'b.-', 'LineWidth',0.5);
hold on
plot(datesCDS__,survProbs1,'ko-','LineWidth',0.5);
hold on
plot(datesCDS__,survProbs2,'rx-','LineWidth',1);
title ('Survival Probabilities Comparison');
ylabel('Survival Probabilities')
xlabel('Dates')
legend ('Approximated','Exact', 'Jarrow-Turnbull')
grid on
hold on

figure;
stairs(datesCDS__(2:end),intensities1,'b.-', 'LineWidth',0.5);
hold on
stairs(datesCDS__(2:end),intensities2,'ko-','LineWidth',0.5);
hold on
stairs(datesCDS__(2:end),intensities3,'rx-','LineWidth',1);
title ('Intensities Comparison');
ylabel('Intensities ')
xlabel('Dates')
legend ('Approximated','Exact', 'Jarrow-Turnbull')
grid on
hold on

%% Price First to Default 
% Given values of boostraped discounts, two obligors are considered with
% respective data: ISP and UCG. Finally, the price of a FtD is computed and
% plotted with respect to different values of correlation

% Number of simulations
N = 10000;

% ISP data
recovery_ISP = 0.4;
spreadsCDS_ISP = spreadsCDS;

% UCG interpolation spread 6y 
recovery_UCG = 0.45;
spreadsCDS_UCG = [34 39 45 46 47 47]*1e-4;
%interpolation
cdsspread_int=interp1(datesCDS_(4:end),spreadsCDS_UCG(4:end)',dates_swap(6),'spline'); 
spreadsCDS_UCG = [spreadsCDS_UCG(1:5), cdsspread_int, spreadsCDS_UCG(end)];

% Necessary discount rates 
discountswap = [1, discountswap, discounts(idx+1)]; 

%initializing vector for plotting
s_signed_mean = [];
axis_X = [0:0.1:0.9 , 0.9999];

% Cycling over different values of rho
for rho = axis_X
    s_signed_mean = [s_signed_mean; FtD_Pricing(dates, setDate, discounts, discountswap, datesCDS, spreadsCDS_ISP, recovery_ISP, spreadsCDS_UCG, recovery_UCG, rho, N)];
end

% Price for a specified correlation
disp("FtD Price with rho = 0.2")
s_signed_mean(3)

% Plotting 
figure()                    
plot(axis_X, s_signed_mean'*1e4, 'rx-', 'LineWidth', 1)
title('Plot of spread wrt correlation \rho')
xlabel('Correlations (\rho)')
ylabel('Spread in bp')
grid on