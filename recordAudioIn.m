function recordAudioIn(app, numSamples)
    update(app.session, app);
    app.session.audioIn = zeros(numSamples, 1);

    % Debug
%     cursor = 1;
%     frameSize = 256;
%     testAudio = audioread('audioResources/audioInTest.wav');

    tic;

    while app.player.isplaying && toc < app.DurationField.Value * 60 + 1
        drawnow();
        [audioFrame, numOverrun] = app.deviceReader();
        if numOverrun > 0
            disp('samples overrun:');
            disp(numOverrun);
        end

        % Debug
%         audioFrame = testAudio(cursor:cursor + frameSize - 1);
%         cursor = cursor + frameSize;

        app.session.addFrame(audioFrame);
        app.fileWriter(audioFrame);
    end

end
