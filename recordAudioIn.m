function audioIn = recordAudioIn(duration, deviceReader)
    fileWriter = dsp.AudioFileWriter('audioIn.wav', 'FileFormat', 'WAV');

    disp('Recording...')
    tic;

    while toc < duration
        audioFromDevice = deviceReader();
        fileWriter(audioFromDevice);
    end

    disp('Done recording.');

    release(deviceReader);
    release(fileWriter);

    audioIn = audioread('audioIn.wav');
end
