function runPracticeSession(app)
    %% Setup player
    app.session = PracticeSession(app.TempoField.Value, app.DurationField.Value * 60, str2double(app.SampleRateDropDown.Value));
    app.player = audioplayer(app.session.metronome.audio, str2double(app.SampleRateDropDown.Value));

    %% Setup recorder and file writer
    app.deviceReader = audioDeviceReader(str2double(app.SampleRateDropDown.Value), str2double(app.BufferSizeDropDown.Value));
    setup(app.deviceReader);
    app.fileWriter = dsp.AudioFileWriter('audioResources/audioIn.wav', 'FileFormat', 'WAV');

    %% Play and record
    play(app.player);
    app.session.audioIn = recordAudioIn(app);

    %% Release resources
    release(app.deviceReader);
    release(app.fileWriter);

    %% TMP
    analyse(app.session, app.audioLag);
    plotSession(app.session, app.TimingPlot);
end