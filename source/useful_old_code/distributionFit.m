function [pdffit,offset,A,B,resnorm,mode,medpdf,h] = distributionfit(data,distribution,nbins,figureWH)
%function [pdffit,offset,A,B,resnorm,mode,medpdf,ndata,h] = distributionfit(data,distribution,nbins,figureWH)
%PURPOSE                                                             jdc rev. 23-Mar-06
%   Fit one of three probability distributions (normal, lognormal, weibull)
%   to input data vector. If the distribution is specified as 'best' the dis-
%   tribution that best fits the data is selected automatically.
%INPUT
%   If nargin==1, "distribution" is prompted for and entered interactively
%
%   data         - n x 1 or 1 x n  input data vector 
%   distribution - probability distribution to fit to "data". Can
%                          be 'normal', 'lognormal', 'weibull', or 'best' ... default: 'best'
%   nbins        - number of bar-chart bins ................................... default: sqrt(length(data))
%   figureWH - figure size [width height]  (inches)  …………... default: [4 3]
%OUTPUT
%   pdffit       - fitted probability density function - n x 2 matrix with column 1 the
%                  x-values, column 2 the y values
%   offset       - amount by which the data was offset for lognormal and weibull fits 
%                  (to satisfy the positive-definite requirements for these distributions).
%                  Note: this is approximately equivalent to fitting a 3- rather than a 2-parameter
%                  distribution.
%   A,B          - distribution parameters - mu and sigma for normal and lognormal distributions,
%                  scale and shape parameters for weibull distribution
%   resnorm   - measure of goodness of fit: sum of squares of point-by-point differences
%                        between experimental and best-fit cumulative distribution function 
%   mode         - 2-element vector: [distribution mode   density at mode]
%   medpdf       - 2-element vector: [data median   pdf density at median]
%   h            - handles to the bar chart and probability density curve
%
%TYPICAL FUNCTION CALLS (using random number vectors for input data)
%  distributionfit(randn(10000,1));
%  distributionfit(wblrnd(2,3,10000,1));
%  distributionfit(wblrnd(2,3,10000,1),'weibull');
%  distributionfit(lognrnd(1.5,.5,10000,1),'lognormal');
%  distributionfit(lognrnd(1.5,.5,10000,1),'best');
%REFERENCE
%  Statistics Toolbox Version 3.0.2, function HISTFIT.M 
%REVISIONS
%  09jun05 Revised pdf plot to reflect input rather than zero-shifted data 
%     "    Fixed some problems with lognormal distribution related to 
%          logarithms and exponents of very small numbers
%  10jun05 Added mode and median to arguments out
%  23mar06 Set xlim(2) to max(data)  
%     "    Decreased text fontsize & fixed text placement problem

warning('off','all');
data = data(~isnan(data));
data = data(:);
ndata = length(data);
if nargin<4 | isempty(figureWH), figureWH = [4 3]; end
if nargin<3 | isempty(nbins),               nbins = ceil(sqrt(ndata)); end
if nargin==1,
   distID = menu('Choose a Distribution','Normal','Lognormal','Weibull','best');
else
   if     strfind(lower(distribution),'lognormal'), distID = 2;
   elseif strfind(lower(distribution),'normal'   ), distID = 1;
   elseif strfind(lower(distribution),'weibull'  ), distID = 3;
   elseif strfind(lower(distribution),'best'     ), distID = 4;
   elseif isempty(distribution),                    distID = 4;
   end
end   
switch distID
   case 1, distribution = 'Normal';
   case 2, distribution = 'Lognormal';
   case 3, distribution = 'Weibull';
   case 4
      data = sort(data);
      cdfe = (1:ndata)'/ndata;                      % experimental cdf
      %------------------------------------  normal
      phat = mle(data,'distribution','Normal');
      A = phat(1);   % for normal & lognormal, phat = [mu std], for weibull, = [A B]
      B = phat(2);
      cdft = cdf('Normal',data,A,B);             % best-fit cdf
      residuals = cdfe-cdft;
      resnormNormal = residuals'*residuals;
      %-------------------------------------  lognormal
      offset =-min(data)+0.001*range(data);
      offsetdata = data+offset; % zero-shift data for lognormal and weibull fits so smallest value is positive definite
      if min(offsetdata<=0),
         offset = offset+100*eps;
         offsetdata = data+offset;
      end   
      phat = mle(offsetdata,'distribution','Lognormal');
      A = phat(1);   % for normal & lognormal, phat = [mu std], for weibull, = [A B]
      B = phat(2);
      cdft = cdf('Lognormal',offsetdata,A,B);             % best-fit cdf
      residuals = cdfe-cdft;
      resnormLognormal = residuals'*residuals;
      %-------------------------------------  weibull
      phat = mle(offsetdata,'distribution','Weibull');
      A = phat(1);   % for normal & lognormal, phat = [mu std], for weibull, = [A B]
      B = phat(2);
      cdft = cdf('Weibull',offsetdata,A,B);             % best-fit cdf
      residuals = cdfe-cdft;
      resnormWeibull = residuals'*residuals;
      %-------------------------------------    
      resnorms = [resnormNormal resnormLognormal resnormWeibull];
      distID = find(resnorms==min(resnorms));
      switch distID
         case 1, distribution = 'Normal';
         case 2, distribution = 'Lognormal';
         case 3, distribution = 'Weibull';
      end      
end 
if distID==2 | distID==3, 
   offset = -min(data)+0.001*range(data);
   offsetdata = data+offset; % zero-shift data for lognormal and weibull fits so smallest value is positive definite
   if min(offsetdata<=0),
      offset = offset+100*eps;
      offsetdata = data+offset;
   end   
else
   offset = 0;
   offsetdata = data;
end   
%----------------------------------------------------------------------
figure
[n,xbin]=hist(data,nbins);
hh = bar(xbin,n,1); % get number of counts per bin and bin width
xd = get(hh,'Xdata'); % retrieve the x-coordinates of the bins.
rangex = max(xd(:)) - min(xd(:)); % find the bin range
binwidth = rangex/nbins;    % find the width of each bin.
close(gcf);   % close figure (will replot on probability scale)
%----------------------------------------------------------------------
figure
set(0,'Units','inches');
ss = get(0,'ScreenSize');
set(0,'Units','pixels');
edge = 0;
if ss(3)<16.6,   % for small screens, size figure to fit 3 figures to screen width
   figureWH(1) = ss(3)/3;
   figureWH(2) = 0.75*figureWH(1);  % maintain the 3/4 aspect ratio
end   
set(gcf,'Units','inches','Position',[ss(3)-figureWH(1)-edge ss(4)-figureWH(2)-edge figureWH],...
        'Color',[.8 .8 .8],'InvertHardCopy','off','PaperPosition',[1 1 figureWH]);
nscaled = n/(ndata*binwidth);   % convert bin counts to probabilities
hh = bar(xbin,nscaled,1);       % draw the probability-scaled bars
set(hh,'EdgeColor',[.6 .6 .6],'FaceColor',[.9 .9 .9]);
set(gca,'FontSize',7);
xlabel('Data');
ylabel('Probability Density');
%----------------------------------------------------------------------
phat = mle(offsetdata,'distribution',distribution); % probability distribution parameter estimation
A = phat(1);   % for normal & lognormal, phat = [mu std], for weibull, = [A B]
B = phat(2);
switch distID  % get limits for plotting the best-fit pdf curve
   case 1,
      lolim = norminv(0.0001,A,B);
      hilim = norminv(0.9999,A,B); 
   case 2,
      lolim = logninv(0.0001,A,B);
      hilim = logninv(0.9999,A,B);
      hilim = ceil(max(data));
   case 3,
      lolim = wblinv(0.0001,A,B);
      hilim = wblinv(0.9999,A,B);
      hilim = ceil(max(data));
end      
xpdf = (lolim:(hilim-lolim)/1000:hilim); % construct the x-vector for the pdf curve
ypdf = pdf(distribution,xpdf,A,B);    
pdffit = [xpdf(:)-offset ypdf(:)];
hh1 = line(pdffit(:,1),pdffit(:,2),'Color','r','LineWidth',2); % overplot the histogram with the best-fit pdf curve
%----------------------------------------------------------------------
offsetdata = sort(offsetdata);              % compute resnorm
cdfe = (1:ndata)'/ndata;                      % experimental cdf
cdft = cdf(distribution,offsetdata,A,B);             % best-fit cdf
residuals = cdfe-cdft;
resnorm = residuals'*residuals;
%---------------------------------------------- find the mode & median
I = find(pdffit(:,2)==max(pdffit(:,2)));
mode = pdffit(I,:);
meddata = median(data);
I = find(abs(pdffit(:,1)-meddata)==min(abs(pdffit(:,1)-meddata)));
medpdf = pdffit(I,:);
%----------------------------------------------------------------------
xlim = get(gca,'Xlim');
ylim = get(gca,'Ylim');
xlim = [xlim(1) max(data)];
set(gca,'xlim',xlim);
trd = text(xlim(2),ylim(2),distribution,'FontSize',7,'HorizontalAlignment','right','VerticalAlignment','bottom'); 
ext = extent(trd);
%tld = text(ext(1),ylim(2),'Distribution: ',       'FontSize',7,'HorizontalAlignment','right','VerticalAlignment','bottom');
%------------------------------------------------------------------------------------------------------------------------------------
trr = text(xlim(2),ylim(2)-ext(4),sprintf('%8.1e  ',resnorm),'FontSize',7,'HorizontalAlignment','right','VerticalAlignment','middle');
ext = extent(trr);
tll = text(ext(1),ylim(2)-ext(4),'Resnorm: ','FontSize',7,'HorizontalAlignment','right','VerticalAlignment','middle');
%------------------------------------------------------------------------------------------------------------------------------------
%tt =    text(xlim(2),ylim(2)-ext(4),sprintf('%4.2f   ',A),'FontSize',7,'HorizontalAlignment','right','Visible','off');
%ext = extent(tt);

i = 1;
switch distID
   case {1,2}          % normal, lognormal
      if distID==2,
         tr(i) = text(ext(1),ylim(2)-(i+1)*ext(4),sprintf('%+5.2f  ',offset));
%         ext = extent(tr(i));
         tl(i) = text(ext(1),ylim(2)-(i+1)*ext(4),'Zero Shift: ');
         i = i+1;
      end   
      tl(i) =    text(ext(1),ylim(2)-(i+1)*ext(4),'Sigma: ');
      tr(i) =    text(ext(1),ylim(2)-(i+1)*ext(4),sprintf('%4.2f',B));
      i = i+1;
      tl(i) =    text(ext(1),ylim(2)-(i+1)*ext(4),'Mu: ');
      tr(i) =    text(ext(1),ylim(2)-(i+1)*ext(4),sprintf('%4.2f',A));
   case 3   
      tr(i) =    text(ext(1),ylim(2)-(i+1)*ext(4),sprintf('%+5.2f  ',offset));
%      ext = extent(tr(i));
      tl(i) =    text(ext(1),ylim(2)-(i+1)*ext(4),'Zero Shift: ');
      i = i+1;
      tl(i) =    text(ext(1),ylim(2)-(i+1)*ext(4),'Scale: ');
      tr(i) =    text(ext(1),ylim(2)-(i+1)*ext(4),sprintf('%4.2f',A));
      i = i+1;
      tl(i) =    text(ext(1),ylim(2)-(i+1)*ext(4),'Shape: ');
      tr(i) =    text(ext(1),ylim(2)-(i+1)*ext(4),sprintf('%4.2f',B));
end
i = i+1;
tl(i) =          text(ext(1),ylim(2)-(i+1)*ext(4),'Mode: ');
tr(i) =          text(ext(1),ylim(2)-(i+1)*ext(4),sprintf('%+5.2f',mode(1)));
i = i+1;
tl(i) =          text(ext(1),ylim(2)-(i+1)*ext(4),'Median: ');
tr(i) =          text(ext(1),ylim(2)-(i+1)*ext(4),sprintf('%+5.2f',medpdf(1)));

set(tl,'Color','k','FontSize',7,'HorizontalAlignment','right','VerticalAlignment','middle'); 
set(tr,'Color','k','FontSize',7,'HorizontalAlignment','left', 'VerticalAlignment','middle'); 
%----------------------------------------------------------------------
h = [hh; hh1];
warning('on','all');
