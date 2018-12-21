function audioIn = recordAudioIn(app)
    tic;
    while app.player.isplaying && toc < app.DurationField.Value * 60
        drawnow();
        audioFromDevice = app.deviceReader();
        app.fileWriter(audioFromDevice);
    end

    audioIn = audioread('audioResources/audioIn.wav');
end
