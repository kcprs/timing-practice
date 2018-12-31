function runPracticeSession(app)
    %% Setup player
    update(app.session, app);
    app.player = audioplayer(app.session.metronome.audio, str2double(app.SampleRateDropDown.Value));

    %% Setup recorder and file writer
    app.deviceReader = audioDeviceReader(str2double(app.SampleRateDropDown.Value), str2double(app.BufferSizeDropDown.Value));
    setup(app.deviceReader);
    app.fileWriter = dsp.AudioFileWriter('audioResources/audioIn.wav', 'FileFormat', 'WAV');

    %% Play and record
    play(app.player);
    recordAudioIn(app, length(app.session.metronome.audio));
    app.session.runExtAnalysis()

    %% Release resources
    release(app.deviceReader);
    release(app.fileWriter);

    %% TMP
    plotSession(app.session, app.TimingPlot);
end