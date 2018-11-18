%% Script for reading the Nova PM Sensor SDS011 High Precision Laser PM2.5 Air Quality Detection Sensor Module
% Description at https://www.banggood.com/Nova-PM-Sensor-SDS011-High-Precision-Laser-PM2_5-Air-Quality-Detection-Sensor-Module-p-1144246.html?rmmds=myorder&cur_warehouse=CN
%
% Matt 2018


clear all
clc

% Inputs
COM_PORT = 'COM5';
save_file = 'test.txt';


HEADER = uint8(hex2dec('AA'));
ORDER  = uint8(hex2dec('C0'));
FOOTER = uint8(hex2dec('AB'));

% Set up plot
figure(1); clf; %xlabel('Time [ s ]');
yyaxis left; ...
    ylabel('PM2.5 Count [ - ]');
yyaxis right; ...
    ylabel('PM10 Count [ - ]');

% Open file to save data to
fid = fopen(save_file,'w');
fprintf(fid,'%7s,%7s,%7s\n','Time [s]','PM 2.5','PM 10');
fprintf(fid,'------------------------\n');

% Close existing serial ports
if ~isempty(instrfind)
     fclose(instrfind);
      delete(instrfind);
end

% Open serial port
% Rate of 9600, data bits 8, parity none, stop bits 1
sensorID = serial(COM_PORT,'BaudRate',9600);
fopen(sensorID);

% Wait for port to open and start giving data
while (~sensorID.BytesAvailable)
    % do nothing
end


% Read data using state machine
stream_locked = 0;
plot_buffer = zeros(60,3); % t,PM2.5,PM10
tic;  % start the timer

while (1)
    
    if (stream_locked)
        % Read header, byte [0:1] should be AA C0
        xx = fread(sensorID, 2,'uint8');
        
        if ((xx(1) == HEADER) && (xx(2) == ORDER)) % Header OK, Decode the stream
            t = toc;
            csk = 0;
            
            % [ 2:3 ] : PM2.5 low byte, PM2.5 high byte
            xx = fread(sensorID, 2,'uint8');
            PM025 = xx(2)*256 + xx(1);
            csk = csk + xx(1) + xx(2);
            
            % [ 4:5 ] : PM10 low byte, PM10 high byte
            xx = fread(sensorID, 2,'uint8');
            PM100 = xx(2)*256 + xx(1);
            csk = csk + xx(1) + xx(2);
            
            % [ 6:7 ] : Reserved
            xx = fread(sensorID, 2,'uint8');
            csk = csk + xx(1) + xx(2);
            
            % [ 8 ] : Checksum
            xx = fread(sensorID, 1,'uint8');
            if (xx ~= mod(csk,256))
                % Checksum fail
                fprintf('Checksum Fail! Expected %u, got %u.\n', csk, xx);
                
                PM025 = nan;
                PM100 = nan;
                
            end
            
            % [ 9 ] : Footer
            xx = fread(sensorID, 1,'uint8');
            if (xx ~= FOOTER)
                % Footer doesn't match, stream likely lost
                fprintf('Stream lost!\n');
                stream_locked = 0;
                
            end
            
            % Update the plot
            plot_buffer(2:end,:) = plot_buffer(1:end-1,:);
            plot_buffer(1,:) = [ t PM025 PM100 ];
            
            figure(1); clf;
            yyaxis left; hold all; ...
                plot(plot_buffer(:,2)); ...
                plot(plot_buffer(1,2),'o'); ...
                ylabel('PM2.5 Count [ - ]'); ylim([0 inf]);
            yyaxis right; hold all; ...
                plot(plot_buffer(:,3)); ...
                plot(plot_buffer(1,3),'o'); ...
                ylabel('PM10 Count [ - ]'); ylim([0 inf]);
            
            drawnow;
            
            fprintf('%8.1f s =>  PM2.5: %7d    PM10: %7d\n',t,PM025,PM100);
            fprintf(fid,'%8.1f,%7d,%7d\n',t,PM025,PM100);
            
        else
            % Stream has been lost
            fprintf('Stream lost!\n');
            stream_locked = 0;
            
        end
        
    else
        % Need to find the header
        
        while (~stream_locked)
            xx = fread(sensorID, 2,'uint8');
            
            if ((xx(1) == HEADER) && (xx(2) == ORDER))
                % Stream locked
                fprintf('Stream locked!\n');
                stream_locked = 1;
                
                % Read through remaining data.  We can afford to loose it
                fread(sensorID, 8,'uint8');
            end
            
        end
        
    end
    
end