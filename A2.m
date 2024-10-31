%% LOAD necessary data
load('stnd_data_ppg.mat');
load('stnd_data_gsr.mat');
load('ppg_normalized.mat');

%%  PPG - feat extraction   

% 1) creazione struttura adeguata da dare in input

% Ho una "struct" chiamata "ppg_normalized" 1x12 con 1 campo ("PPG").
% Ognuna delle 12 "struct" (es. ppg_normalized(1).PPG ovvero struct del soggetto 1)
% contiene a sua volta 40 campi, "video1", "video2", ..., fino a "video40" e come valore 
% (ppg_normalized(1).PPG.video1) un row vector 1x7552 single.
% Voglio che ppg_normalized(i).PPG per ogni soggetto "i" abbia una struttura del
% tipo ppg_normalized(1).PPG.videos, dove il campo "videos" abbia come valore
% 1x2 celle, ognuna delle quali contiene i row vector 1x7552 con i
% segmenti corrispondenti a ciascun video.

% Initialize the output structure array
stnd_ppg_st2 = struct('PPG', {});

% Loop through each subject
for subject_idx = 1:numel(ppg_normalized)
    % Create a structure to store video signals
    video_signals = struct();

    % Initialize the "videos" field as an empty cell array
    video_signals.videos = cell(1, 2);

    % Loop through each video for the current subject
    for video_idx = 1:2
        % Extract the signal for the current video
        video_signal = baseNorm(subject_idx).PPG.(['video', num2str(video_idx)]);

        % Store the video signal in the cell array
        video_signals.videos{video_idx} = video_signal;
    end

    % Assign the video_signals structure to the PPG field for the current subject
    stnd_ppg_st2(subject_idx).PPG = video_signals;
end

%   --- Creazione "sigList" ---
% una cella 22x40, ognuna delle quali contiene dei row vector 1x7680 con i segmenti 
% corrispondenti a ciascun video.
sigList = cell(12, 2);
numFields = 7;

% Initialize task_feat struct
task_feat = struct('max_ppg', [], 'min_ppg', [], 'mean_ppg', [], 'var_ppg', [], 'rate_peaks_ppg', [], 'IBI_mean', [], 'RMSSD', []);

for i = 1:12
    sigList(i,:) = stnd_ppg_st2(i).PPG; 
    % Apply computeFeaturesPPG to each row of sigList
    computedFeatures = computeFeaturesPPG(sigList(i, :), 128);
    
    % Iterate over the fields of computedFeatures and store in task_feat_tmp
    for j = 1:numFields
        field_name = fieldnames(task_feat); % Get actual field names
        task_feat.(field_name{j})(:, i) = computedFeatures.(field_name{j});
    end
end

%   --- task_feat ---
% contiene per ogni soggetto e per ogni video le features


%% GSR

%1) str
stnd_gsr = stnd_data;
for i = 1:12
    currentdata = stnd_data{i}.data;        
    stnd_gsr{i}.data = currentdata(1, :, :);
end

% Initialize the output structure array
gsr_struct = struct('GSR', {});

% Loop through each subject
for subject_idx = 1:numel(stnd_gsr)
    subject_data = stnd_gsr{1,subject_idx};

    % Create a structure to store video signals
    video_signals = struct();

    % Initialize the "videos" field as an empty cell array
    video_signals.videos = {};

    % Loop through each video for the current subject
    for video_idx = 1:size(subject_data, 3)
        % Extract the signal for the current video
        video_signal = subject_data(:, :, video_idx);

        % Store the video signal in the cell array
        video_signals.videos{video_idx} = video_signal;
    end

    % Assign the video_signals structure to the PPG field for the current subject
    gsr_struct(subject_idx).GSR = video_signals;
end

%% 2) Divisione fasico - tonico
% 
% sigListGSR = cell(12, 2);
% phasic_temp = cell(12, 2);
% tonic_temp = cell(12, 2);
% 
% for i = 1:12
%     sigListGSR(i,:) = gsr_struct(i).GSR.videos;
%     for j = 1:2
%         [phasic, ~, tonic, ~, ~, ~, ~] = cvxEDA(double(sigListGSR{i, j}), 1/128);
%         % (1/128) is the sampling interval,
%         % sigListGSR{i, j} are the normalized GSR signals
% 
%         % Store the results in cell arrays
%         phasic_temp{i, j} = phasic;
%         tonic_temp{i, j} = tonic;
%     end
% end

%% save full, phasic and tonic
% save('phasic_temp.mat', 'phasic_temp');
% save('tonic_temp.mat', 'tonic_temp');
% save('sigListGSR.mat', 'sigListGSR');

%% LOAD 
load('phasic_temp.mat');
load('tonic_temp.mat');
load('sigListGSR.mat');

%% Estrazione Features GSR

% GSRfeat = computeFeaturesGSR_phasicTonicFullSignal(sigListGSR(i, :), phasic_temp(i, :), tonic_temp(i, :), 128);

numFeat = 15;
% Initialize task_feat struct
final_GSRfeat = struct('max_gsr', [], 'min_gsr', [], 'mean_gsr', [], 'var_gsr', [], ...
    'max_gsr_phas', [], 'min_gsr_phas', [], 'mean_gsr_phas', [], 'var_gsr_phas', [], ...
    'n_peaks_gsr', [], 'rate_peaks_gsr', [], 'height_peaks_gsr', [], 'peaks_area_gsr', [], ...
    'peaks_area_per_sec_gsr', [], 'peaks_rise_time', [], 'reg_coef_gsr', []);

for i = 1:12
    % Apply fnct to each row of sigListGSR
    GSRfeat = computeFeaturesGSR_phasicTonicFullSignal(sigListGSR(i, :), phasic_temp(i, :), tonic_temp(i, :), 128);
    
    % Iterate over the fields of computedFeatures and store in task_feat_tmp
    for j = 1:numFeat
        field_name = fieldnames(final_GSRfeat); % Get actual field names
        final_GSRfeat.(field_name{j})(:, i) = GSRfeat.(field_name{j});
    end
end


%% SAVE FEATURES

% GSR
save('GSRfeat.mat', 'final_GSRfeat');
% PPG
save('PPGfeat.mat', 'task_feat');