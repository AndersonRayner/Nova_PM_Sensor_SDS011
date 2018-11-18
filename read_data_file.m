% Read Data File

file = './JabLab.txt';

% Load the data
fid = fopen(file,'r');
dataArray = textscan(fid, '%f,%f,%f', 'HeaderLines' ,2);
fclose(fid);

% Sort the data
t = dataArray{:,1};
PM025 = dataArray{:,2};
PM100 = dataArray{:,3};

% Plot the data
figure(1); clf; hold all; set(gcf,'name','Air Quality Data'); ...
yyaxis left; ...
    plot(t,PM025); ...
    ylabel('PM 2.5 [ - ]'); ...
    ylim([0 inf]);
yyaxis right; ...
    plot(t,PM100); ...
    ylabel('PM 10 [ - ]'); ...
    ylim([0 inf]);
    xlabel('Time [ s ]'); xlim([0,max(t)]);


