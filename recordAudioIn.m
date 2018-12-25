function audioIn = recordAudioIn(app)
    tic;
    while app.player.isplaying && toc < app.DurationField.Value * 60 + 1
        drawnow();
        audioFromDevice = app.deviceReader();
        app.fileWriter(audioFromDevice);
    end

    audioIn = highpass(audioread('audioResources/audioIn.wav'), 50, app.deviceReader.SampleRate);
end
