% Define the base path to the subject folders
base_path = 'C:\Users\saran\Desktop\INSIDE LAB\AIoMT Special Issue\Detecting_Social_Anxiety-master\data_preprocessing';

%%
% loro fanno (i) moving average filtering e (ii) value - min/max-min range
% correction

% io propongo: 
% solito filtraggio, non downsampling perché freq già basse, no upsampling.
% isolamento baseline, standardizzazione z score (avendo escluso baseline),
% normalizz ppg, poi divisione fasico tonico e
% estrazione features

% task 1 ovvero 
% baseline start:2820, da cui però tolgono i primi 2 min per acclimatamento
% experiment 2820:5299 (11,75 to 22 min)
% 5299 alla fine- finisce quindi lo discardano
%% 0) LOAD GSR e HR (BPM) mean heart rate (computed in spans of 10 seconds)

gsr_data = cell(1, 12);
for i = 1:12
    file_path = fullfile(base_path, num2str(i), 'EDA.csv');
    gsr_data{i} = readtable(file_path); 
    gsr_data{1,i} = gsr_data{1,i}.Var1(4:end);
    disp(['Data size for subject ', num2str(i), ': ', num2str(size(gsr_data{i}))]);
end

ppg_data = cell(1, 12);
for i = 1:12
    file_path = fullfile(base_path, num2str(i), 'HR.csv');
    ppg_data{i} = readtable(file_path); % or use readmatrix(file_path) if more suitable
    ppg_data{1,i} = ppg_data{1,i}.Var1(4:end);
    disp(['Data size for subject ', num2str(i), ': ', num2str(size(ppg_data{i}))]);
end

%% plot gsr
for i = 1:12
    plot(gsr_data{1,i});
    title('GSR Data for Subject', i);
    xlabel('Time');
    ylabel('GSR Value');
end
%1,2,10,11 verso la fine svalvolano

%% plot HR 
for i = 1:12
    plot(ppg_data{1,i});
    title('PPG Data for Subject', i);
    xlabel('Time');
    ylabel('PPG Value');
end

%% 1.1) GSR FILTERING
% 
% % INITIALIZATION - Filter parameters
% fs = 4;                 % Original sampling frequency
% fcutoff_gsr = 4;        % Cutoff frequency for GSR filter
% 
% % Design GSR butterworth filter
% [ba_gsr, aa_gsr] = butter(3, fcutoff_gsr/(fs/2), 'low');
% 
% % Set for overwriting
% filtered_gsr = gsr_data;
% 
% for i = 1:12
%     % Apply GSR butterworth and PPG bandpass filters
%     currentdata = filtered_gsr{1,i};
%     currentdata(41, :) = filtfilt(ba_gsr, aa_gsr, filtered_gsr{1,i}); 
%     filtered_gsr{1,i} = currentdata;
% end
% 
% %% 1.2) PPG FILTERING
% 
% % filtro per PPG di ordine 2 e non di ordine 4
% f_range_ppg = [0.7, 4]; % Frequency range (Hz)
% n = 2;                  % PPG Filter order
% 
% % PPG bandpass filtering [0.7-4] Hz
% [ba_ppg, aa_ppg] = butter(n, f_range_ppg/(fs/2), 'bandpass');
% 
% % Set for overwriting
% filtered_HR = HR_data;
% 
% for i = 1:12
%     % Apply GSR butterworth and PPG bandpass filters
%     currentdata = filtered_HR{1,i}.data;
%     currentdata(46, :) = filtfilt(ba_ppg, aa_ppg, filtered_HR{1,i});
%     filtered_HR{1,i}.data = currentdata;
% end

%% tolgo i primi 2 min di acclimatamento e produco "gsr" e "ppg"

for i = 1:12
    gsr_1s = gsr_data{1,i};
    ppg_1s = ppg_data{1,i};
    
    % gsr (480 bc 4Hz fs)
    if length(gsr_1s) > 480
        gsr{i} = gsr_1s(481:end);
    end
    % ppg (120 bc 1Hz sf)
    if length(gsr_1s) > 120
        ppg{i} = ppg_1s(121:end);
    end
    
    disp(['New data size for subject ', num2str(i), ': ', num2str(length(gsr{i}))]);
    disp(['New data size for subject ', num2str(i), ': ', num2str(length(ppg{i}))]);
end

%% isolo baseline gsr (gsr_base) e ppg (ppg_base) e anx (gsr_anx e ppg_anx)
% in realtà al posto di 2 strutture nuove, strutturalo come video

for i = 1:12
    gsr_1s = gsr{1,i};
    ppg_1s = ppg{1,i};
    
    % gsr (2400 bc 4Hz fs)
    gsr_base{i} = gsr_1s(1:2400);
    if length(gsr_1s) > 4802
        gsr_anx{i} = gsr_1s(2401:4802);
    else
        gsr_anx{i} = gsr_1s(2401:end);
    end
    
    % ppg (60 bc 1Hz sf)
    ppg_base{i} = ppg_1s(1:600); %da min 0 a min 10 (considerando che 0 è 2min dopo rimozione acclimatamento)
    ppg_anx{i} = ppg_1s(601:end);  %da min 10 a min 20
    if length(ppg_1s) > 1202
        ppg_anx{i} = ppg_1s(601:1202);
    else
        ppg_anx{i} = ppg_1s(601:end);
    end
    %modifica per tagliare anx se piùù lungo di 4802/1202
    
    disp(['New data size for subject ', num2str(i), ': ', num2str(length(gsr_base{i}))]);
    disp(['New data size for subject ', num2str(i), ': ', num2str(length(ppg_base{i}))]);
    disp(['New data size for subject ', num2str(i), ': ', num2str(length(gsr_anx{i}))]);
    disp(['New data size for subject ', num2str(i), ': ', num2str(length(ppg_anx{i}))]);
end

%% BASELINE 

bas_ppg = ppg;
% Initialize a structure to store the segments
cond1_segments = struct('baseline', {});

subject_counter = 1;
for i = 1:12   
    bas_ppg{i} = ppg{1,i};
    segment_data = bas_ppg{i}(1:600);
    cond1_segments(subject_counter).baseline = segment_data;
    disp(['Segment for s', num2str(i), ': ', num2str(size(cond1_segments(subject_counter).baseline))]);

    % Increment the subject counter
    subject_counter = subject_counter + 1;
end

%% STANDARDIZATION of both PPG and GSR
%modifico questo in modo tale che standardizzazione sia su tutto ??controlla e
%modifica struttura in modo tale che al posto dei 40 video hai i 2
%separazioni tra base e anx

% 2) standardizzo ogni soggetto con il suo z-score
stnd_data_gsr = gsr;
stnd_data_ppg = ppg;

for i = 1:12
    currentdata_gsr = stnd_data_gsr{i};
    currentdata_ppg = stnd_data_ppg{i};

    mean_gsr = mean(gsr_base{i});            
    sd_gsr = std(gsr_base{i});              

    mean_ppg = mean(ppg_base{i});      
    sd_ppg = std(ppg_base{i});         

    % z-score normalization
    currentdata_gsr = (stnd_data_gsr{i} - mean_gsr) / sd_gsr;
    currentdata_ppg = (stnd_data_ppg{i} - mean_ppg) / sd_ppg;

    stnd_data_gsr{i} = currentdata_gsr;
    stnd_data_ppg{i} = currentdata_ppg;
end

%%
for i = 1:12
    plot(stnd_data_ppg{1,i});
    title('PPG Data for Subject', i);
    xlabel('Time');
    ylabel('PPG Value');
end
%%
for i = 1:12
    plot(stnd_data_gsr{1,i});
    title('GSR Data for Subject', i);
    xlabel('Time');
    ylabel('PPG Value');
end

%% CREATION OF PPG DATA STRUCTURE SUITABLE FOR NORMALIZATION fncts

% Initialize the output structure array
stnd_ppg_struct = struct('PPG', {});

% % Loop through each subject
% for subject_idx = 1:numel(stnd_data_ppg)
%     % Extract data from the current subject
%     subject_data = stnd_data_ppg{1,subject_idx};
% 
%     % Assign the video_signals structure to the PPG field for the current subject
%     stnd_ppg_struct(subject_idx).PPG = subject_data;
% end

% Loop through each subject
for subject_idx = 1:numel(stnd_data_ppg)
    % Extract data from the current subject
    subject_data = stnd_data_ppg{1,subject_idx};

    % Assign the video_signals structure to the PPG field for the current subject
    stnd_ppg_struct(subject_idx).PPG = subject_data;
end

%% PPG frequency normalization

newFs = newfsPPG_empatica(cond1_segments, 12, 1, 'baseline', 0);
baseNorm = baselineNormalizationPPG_empatica(stnd_ppg_struct, 12, 1, newFs, 0);

%% plot
plot(baseNorm(5).PPG)
% frequency normalization fa sì che il numero di campioni si reduca
% significativamente

%% SAVE

% Save the cell array to a MAT file
save('stnd_data_ppg.mat', 'stnd_data_ppg');
save('stnd_data_gsr.mat', 'stnd_data_gsr');
save('ppg_normalized.mat', 'baseNorm');
