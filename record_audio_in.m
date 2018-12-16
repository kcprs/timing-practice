function audio_in = record_audio_in(duration, frameLength, fs)
    deviceReader = audioDeviceReader(fs, frameLength);
    setup(deviceReader);

    fileWriter = dsp.AudioFileWriter('audio_in.wav', 'FileFormat', 'WAV');

    disp('Recording...')
    tic;

    while toc < duration
        audioFromDevice = deviceReader();
        fileWriter(audioFromDevice);
    end

    disp('Done recording.');

    release(deviceReader);
    release(fileWriter);

    audio_in = audioread('audio_in.wav');
end
