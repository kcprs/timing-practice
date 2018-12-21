function runPracticeSession(app)
    %% Setup player
    app.session = PracticeSession(app.TempoField.Value, app.DurationField.Value * 60, app.vars.fs);
    app.player = audioplayer(app.session.metronome.audio, app.vars.fs);
    app.player.StopFcn = @(~, ~) disp('Player stop');

    %% Setup recorder and file writer
    app.deviceReader = audioDeviceReader(app.vars.fs, app.vars.frameLength);
    setup(app.deviceReader);
    app.fileWriter = dsp.AudioFileWriter('audioResources/audioIn.wav', 'FileFormat', 'WAV');

    %% Play and record
    play(app.player);
    app.session.audioIn = recordAudioIn(app);

    %% Release resources
    release(app.deviceReader);
    release(app.fileWriter);

    %% TMP
    analyse(app.session, true);
    plotSession(app.session, app.TimingPlot);
end