% Function to extract the reTHM data from a .con file.

% Authors:  Matt Sanderson (matt.sanderson@mq.edu.au)
%           Robert Seymour (robert.seymour@mq.edu.au)

function [coil_data] = read_reTHM(file_path)
    % input: file_path - location of the .con file
    % output: an (n x 20) matrix of the reTHM data.
    %         Each row is a measurement and contains (x, y, z, gof) for
    %         each of the 5 markers
    % Currently this has no sort of error checking (sorry!)
    
    fprintf('Reading reTHM data from %s\n',file_path)
    
    % the events are all in the 192 channel as these are the times the
    % measurements are recorded (on the trailing edge of the pulse).
    events = ft_read_event(file_path, 'trigindx', [192], 'threshold', 2, 'detectflank','down');
    % remove first two rows. It is unknown currently if there is a way to
    % determine from the con file the number of initial pulses that
    % indicate the start of reading. The number is shown by opening the con
    % file in MEG160, but I couldn't find the value in the .con file, so it
    % may just always be 2...
    events([1,2],:) = [];
    sfreq = ft_read_header(file_path);
    sfreq = sfreq.Fs;
    
    num_events = size(events, 1);
    
    fileID = fopen(file_path);
    % jump to +0x1D0 in the file
    fseek(fileID, 464, 'bof');
    % read the appropriate part of the header
    header = fread(fileID, 3, 'uint32');
    offset = header(1);
    % not needed, but this is what the data corresponds to
    element_size = header(2);
    markers = 5;                 % this can potentially be read elsewhere
    count = uint32(header(3)/markers);	% better way to ensure int??
    
    % The number of events should be less than the number of recordings in
    % the con file. This is fine as we pair off the events with the
    % measurements until we run out, leaving some extra measurements with
    % no time stamp. These are just discarded.
    count = min(count, num_events);
    fprintf('Found %d time points\n',count);
    % now move to the start of the reTHM data
    fseek(fileID, offset, 'bof');

    reTHM_data = zeros([count, 4*markers + 1]);

    % iterate over the number of entries
    for i = 1:count
        reTHM_data(i, 1) = events(i).sample/sfreq;
        for j = 1:markers
            is_good = fread(fileID, 1, 'uint32');
            if is_good == 1
                data = fread(fileID, 4, 'double');
            else
                data = [NaN, NaN, NaN, NaN];
                % also move the file location forward by 32 bytes
                fseek(fileID, 32, 'cof');
            end
            for k = 1:4
                if k ~= 4
                    reTHM_data(i,4*(j-1)+k+1) = 1000*data(k);
                else
                    reTHM_data(i,4*(j-1)+k+1) = data(k);
                end
            end
        end
    end
    
    disp('Reorganising Data');
    coil_data = [];
    coil_data.pos = reshape(reTHM_data(...
    :,[2:4;6:8;10:12;14:16;18:20]),[length(reTHM_data) 5 3]);
    coil_data.label = {'LPAred','RPAyel','PFblue','LPFwh','RPFblack'};
    coil_data.time  = reTHM_data(:,1);
    coil_data.gof   = reTHM_data(:,[5;9;13;17;21]);
    coil_data.unit = 'mm';
    
end