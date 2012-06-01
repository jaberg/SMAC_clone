function handle=errorbarloglog(x,y,errl,errh,linestyle,marker, colour);
%function handle=errorbarloglog(x,y,errl,errh);
%
%plots error bars in 2D loglog-plot correctly, solving the problem with
%Matlab errorbar function.
%
%IN:
%x: x-axis data vector
%y: y-axis data vector
%errl: vector containing errors. If only 3 input arguments are given, this
%is half the height of the error bar. If four input arguments are given,
%this is the lower bound error vector
%errh: upper boud error vector (optional)
%
%OUT: axes handle
%
%Copyright Erik Benkler, Physikalisch-Technische Bundesanstalt
%Section 4.53: Microoptics Measuring Technologies
%D-38116 Braunschweig, GERMANY
%
%Version 0.2, November 30 2005, checked with Matlab R14SP2 (7.0.4.365)

if nargin == 3
    errh=y+errl;
    errl=y-errl;
end

handle=gca;
set(gca,'xscale','log');  %make loglog axes
set(gca,'yscale','log');

if nargin<=6
    colour=[0 0 1];
end
if nargin<=5
    marker='none';
end
if nargin<=4
    linestyle='-';
end
    

hd=line(x,y);                 %plot the data
set(hd,'Marker', marker,'LineStyle',linestyle,'MarkerFaceColor',colour, 'Color', colour); 

ax=log(axis);               %determine axis limits
%This sets the with of the errorbar heads to 2% of the x-axis width
%AS IT WILL APPEAR IN THE LOGLOG-PLOT: (modified as suggested by Phill Jones
lx=log(x);
werrbh=abs(0.02*(lx(1)-lx(end)));
xul=[[exp(lx+werrbh)]' [exp(lx-werrbh)]'];

for i=1:length(x)
    line([x(i) x(i)],[errl(i) errh(i)], 'Color', colour); %plot errorbars
    line(xul(i,:), [errl(i) errl(i)], 'Color', colour);   %plot lower errorbar heads
    line(xul(i,:), [errh(i) errh(i)], 'Color', colour);   %plot upper errorbar heads
end

order=get(gca,'Children');

set(gca,'Children',[hd;setdiff(order,hd)])