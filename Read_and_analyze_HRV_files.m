% Matlab script to read and analyze HRV data
% Created on 04/07/2022 by A. Coste
% Modification history : /

% Main technical features (measuring tool): Polar H10 

% Associated references:  
% HRVTool v1.07 (https://fr.mathworks.com/matlabcentral/fileexchange/52787-marcusvollmer-hrv)
% Vollmer, M. (2019, September). HRVTool?an open-source matlab toolbox for analyzing heart rate variability. In 2019 Computing in Cardiology (CinC) (pp. Page-1). IEEE.
% Vollmer, M. (2015, September). A robust, simple and reliable measure of heart rate variability using relative RR intervals. In 2015 Computing in Cardiology Conference (CinC) (pp. 609-612). IEEE.

clear all; clc; close all;

cd('') 

Files=dir('*.*');
session = 1; 
for i = 3 : numel(Files)

filename = Files(i).name;
RR = Import_HRV(filename)./1000; % RR is a vector containing RR intervals in seconds
RR= HRV.RRfilter(RR);
%RR = fillmissing(RR, 'linear');

Recording_time = 5 * 60; %(in seconds) 
Fs =  Recording_time/length(RR); % Sampling rate
Beg = round(Fs); % start of analysis
End = length(RR)- round(Fs); % end of analysis
Ann = cumsum(RR(Beg:End));
% ---------------------------------
%   Compute & plot the average heart rate
% ---------------------------------

mean_HR(session,1) = HRV.HR(RR(Beg:End)); % Mean heart rate
figure(i)
set(gcf,'color','w');
subplot(4,1,1)
plot(Ann,HRV.HR(RR(Beg:End),5,1),'r') %  5 second heart rate segments
xlim([0 length(RR(Beg:End))+5])
%xlim([0 180])
line([0 length(RR(Beg:End))],[mean_HR(session) mean_HR(session)],'Color','black','LineStyle','--')
text(50,mean_HR(session)*1.2,['mean HR : ' num2str(mean_HR(session),'%05.2f') ' bpm']);
xlabel('Time (s)')
ylabel('HR (bpm)')
title('Heart rate')

% ---------------------------------
%   Compute & plot RR time series
% ---------------------------------
meanRR(session,1) = mean(RR(Beg:End)); %  Mean of RR intervals
subplot(4,1,2)
plot(RR(Beg:End),'b')
xlabel('Time (s)')
ylabel('RR (s)')
xlim([0 numel(RR(Beg:End))+5])
%xlim([0 180])
line([0 length(RR(Beg:End))],[meanRR(session) meanRR(session)],'Color','black','LineStyle','--')
text(length(RR(Beg:End))/3,meanRR(session)*1.2,['mean RR : ' num2str(meanRR(session),'%5.2f') ' s'])
title('RR Time Series')

% ---------------------------------
%   Compute & plot relative RR intervals
% ---------------------------------
subplot(4,1,3)
rr = HRV.rrx(RR(Beg:End)); % rr is the difference of consecutive RR intervals weighted by their mean
plot(rr(1:end-1),rr(2:end),'Marker','o',...
    'MarkerFaceColor',1*[1 1 1],'MarkerEdgeColor',0*[1 1 1],...
    'MarkerSize',10,'Color',0.5*[1 1 1])
title('Return Map of relative RR intervals')
xlabel('RR_{i} (%)')
ylabel('RR_{i+1} (%)')


% ---------------------------------
%   Poincare plot
% ---------------------------------
subplot(4,1,4)
x1 = RR(Beg:End-1);
x2 = RR(Beg+1:End);
plot(x1,x2,'.')
[SD1,SD2,~] = HRV.returnmap_val(RR,0);
p = calculateEllipse(HRV.nanmean(x1),HRV.nanmean(x2),2*SD1,2*SD2,45);
hold on;
plot(p(:,1), p(:,2),'-')
title('Poincare plot')
xlabel('RR_{i} (s)')
ylabel('RR_{i+1} (s)')
%text(mean(x1),min(x2)-0.05,['SD1 = ' num2str(SD1*1000,'%5.2f') ' ms'])
%text(mean(x1),min(x2)-0.1,['SD2 = ' num2str(SD2*1000,'%5.2f') ' ms'])

% ---------------------------------
%   Other parameters
% ---------------------------------

RMSSD(session,1) = HRV.RMSSD(RR(Beg:End),0)*1000; % Root mean square of successive RR intervals in seconds
SDNN(session,1) = HRV.SDNN(RR(Beg:End),0)*1000; % Standard deviation of RR intervals in seconds
SDSD(session,1) = HRV.SDSD(RR(Beg:End),0); % Standard deviation of successive differences in seconds
RRHRV(session,1) = HRV.rrHRV(RR(Beg:End),0); % computes the euclidean distance to the center point of the return map of relative RR intervals of grade 1
Ppnn50(session,1) = HRV.pNN50(RR(Beg:End),0); % Percentage value of consecutive RR intervals that differ more than 50 ms
[HRV_global_tri(session,1) ,HRV_global_tinn(session,1) ] = HRV.triangular_val(RR,0); % RR triangular index : the integral of the sample density distribution of RR intervals divided by the maximum of the density distribution  / Tinn : Baseline width of the minimum square difference triangular interpolation of the maximum of the sample density distribution of RR intervals (see Vollmer, 2016)
[SD1(session,1) ,SD2(session,1) ,SD1SD2ratio(session,1) ] = HRV.returnmap_val(RR(Beg:End)); % computes standard deviations along the identity line and its perpendicular axis of the return map of RR intervals, also known as Poincare plot (SD1 = short-term HRV ; SD2 = Long-term HRV ; SD1 & SD2 are in seconds)
[HRV_global_lf(session,1) ,HRV_global_hf(session,1) ,HRV_global_lfhfratio(session,1)] = HRV.fft_val(RR,0,Fs); % Spectral analysis

session = session+1;
end

