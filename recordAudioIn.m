function audioIn = recordAudioIn(app)
    disp('Recording...')

    tic;
    while app.player.isplaying && toc < app.DurationField.Value * 60
        drawnow();
        audioFromDevice = app.deviceReader();
        app.fileWriter(audioFromDevice);
    end

    disp('Done recording.');
    audioIn = audioread('audioResources/audioIn.wav');
end
