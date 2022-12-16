%% Mouth Robot Data Collection - mweaver@andrew.cmu

clear a;
clear s;
a = arduino();
s = servo(a, 'D9', 'MinPulseDuration', 1e-3, 'MaxPulseDuration', 2e-3);
writePosition(s, .15);

test_length_s = 3;
pitch_changes_per_test = 3;

lowest_tone = 1/3;
tone_step_size = (1-lowest_tone)/pitch_changes_per_test;

numTrials = 280;

PWMA = 'D3';
AIN1 = 'D5';
AIN2 = 'D4';

Fs = 44100; 
nBits = 16; 
nChannels = 2; 
ID = -1;       % default audio input device
filenum = 1;
recDuration = test_length_s; % record for test length
recCushion = 0.5;

position_array = [];
Y = {};

%//drive forward at full speed by pulling AIN1 High
%//and AIN2 low, while writing a full 255 to PWMA to
%//control speed
%digitalWrite(AIN1, HIGH);
writeDigitalPin(a,AIN1,1);
%digitalWrite(AIN2, LOW);
writeDigitalPin(a,AIN2,0);
a1 = 0.25; % low thresh
b1 = 1; % high thresh

%% HIGH LEVEL
class = 1;
for t = 1:numTrials
    x = (b1-a1).*rand(1,3)+a1;
    x_sort = [x(1), x(1), x(1)];
    [filenum, Y, position_array] = RunTrial(x_sort,class,filenum,Y,position_array,a);
end


%% Rising
class = 2;
for t = 1:numTrials
    x = (b1-a1).*rand(1,3)+a1;
    x_sort = sort(x);
    [filenum, Y, position_array] = RunTrial(x_sort,class,filenum,Y,position_array,a);
end

%% Dip
class = 3;
for t = 1:numTrials
    x = (b1-a1).*rand(1,3)+a1;
    x_sort = sort(x);
    x_sort = [x_sort(3), x_sort(1), x_sort(3)];
    [filenum, Y, position_array] = RunTrial(x_sort,class,filenum,Y,position_array,a);
end

%% Fall
class = 4;
for t = 1:numTrials
    x = (b1-a1).*rand(1,3)+a1;
    x_sort = sort(x);
    x_sort = [x_sort(3), x_sort(2), x_sort(1)];
    [filenum, Y, position_array] = RunTrial(x_sort,class,filenum,Y,position_array,a);
end

%% Store Data
writematrix(position_array,'xvalueslong.csv')
writecell(Y,'labels.csv')
%% Functions
function [filenum, Y, position_array] = RunTrial(x_sort,class,filenum, Y, position_array,a)
    PWMA = 'D3';
    AIN1 = 'D5';
    AIN2 = 'D4';

    test_length_s = 3;
    pitch_changes_per_test = 3;

    Fs = 44100; 
    nBits = 16; 
    nChannels = 2; 
    ID = -1;       % default audio input device
    %recDuration = test_length_s; % record for test length
    recCushion = 0.5;

    position_array = cat(1,position_array,x_sort);

    i = x_sort(1);
    j = x_sort(2);
    k = x_sort(3);
    disp('iteration: ')
    disp(filenum)
    disp('new trial')
    %digitalWrite(AIN1, HIGH);
    writeDigitalPin(a,AIN1,1);
    %digitalWrite(AIN2, LOW);
    writeDigitalPin(a,AIN2,0)

    %1. start motor
    writePWMDutyCycle(a, PWMA, i);
%     %2. make servo m
%     writePosition(s, .15);
    %3. pause to let motor adjust
    pause(2)
    %4. start recording
    disp("Begin recording.")
    recObj(filenum) = audiorecorder(Fs,nBits,nChannels,ID);
    record(recObj(filenum));
    %pause(recCushion);
    pause(test_length_s/pitch_changes_per_test);

    writePWMDutyCycle(a, PWMA, j);
    pause((test_length_s/pitch_changes_per_test)/2);
%     % Switch mouth to a
%     writePosition(s, .60);
%     pause((test_length_s/pitch_changes_per_test)/2);

    writePWMDutyCycle(a, PWMA, k);
    pause(test_length_s/pitch_changes_per_test);

    pause(recCushion);
    stop(recObj(filenum));
    disp("End of recording.")

    %Optional stop motor between samples
    %writeDigitalPin(a, AIN1, 0);
    %writeDigitalPin(a, AIN2, 0);
    %writePWMDutyCycle(a, PWMA, 0);

    data = getaudiodata(recObj(filenum));
    audiowrite(sprintf('MouthRobot%d.wav', filenum),data,Fs);

    if class == 1
        Y{filenum} = "HighLevel";
    elseif class == 2
        Y{filenum} = "Rise";
    elseif class == 3
        Y{filenum} = "Dip";
    elseif class == 4
        Y{filenum} = "Fall";
    end
    disp(Y{filenum})

    filenum = filenum+1;
    pause(0.1)

end





%% Notes
% writematrix(position_array,'xvalueslong.csv')
% writematrix(Y,'labels.csv')