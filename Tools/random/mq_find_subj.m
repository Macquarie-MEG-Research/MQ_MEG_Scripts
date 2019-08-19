function info_out = mq_find_subj(subj_info,subject,info)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% mq_find_subj: a function to extract subject specific information from
% a subject information structure
%
% subj_info should be a structure with mandatory field subject_id 
% (e.g. 2768) and fields with other information
%
% Author: Robert Seymour (robert.seymour@mq.edu.au)
%
%%%%%%%%%%%
% Inputs:
%%%%%%%%%%%
%
% - subj_info   = structure containing the subject information 
% - subject     = number or string of the subject
% - info        = the field required by the user
%
%%%%%%%%%%%
% Outputs:
%%%%%%%%%%%
%
% - info_out    = the value or string specified
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% If the user has specified a string.. try converting this to a number
if ischar(subject)
    subject = str2double(subject);
elseif isstring(subject)
    subject = str2double(subject);
end

% Find the row corresponding to the specified subject
try
position_of_subject = find(subj_info.subject_id == subject);
catch
    disp(['Cannot find the subject specified. Does your subj_info have',...
        'a subject_id field?']);
end

% Get the column corresponding to the specified information
get_column          = getfield(subj_info,info);

% Get the info from the "row" and "column" specified

if isa(get_column,'double')
    info_out            = get_column(position_of_subject);
elseif isa(get_column,'cell')
    info_out            = get_column{position_of_subject};
else
    disp('NOT supported yet');
end


end

