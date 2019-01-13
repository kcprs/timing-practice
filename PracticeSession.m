classdef PracticeSession < handle

    properties
        app;
        tempo;
        duration;
        fs;
        metronome;
        audioIn;
        audioCursor;
        timingInfo;
        resultsPlot;
        resultsReady;
        measuringLag;
        lagCompAudioIn;
    end

    methods

        function self = PracticeSession(app)
            self.app = app;
            self.timingInfo = TimingInfo();

            if exist('resources/audioLag.mat', 'file')
                lagStruct = load('resources/audioLag.mat');
                self.timingInfo.audioLag = lagStruct.audioLag;
                self.app.AudioLagLabel.Text = sprintf('Audio lag: %d samples', self.timingInfo.audioLag);
                self.app.AudioLagLamp.Color = Colours.green;
            end

            self.resultsReady = false;
            self.resultsPlot = ResultsPlot(self, app.TimingPlot, app.TimingPlotPreview, app.PlayheadSlider, app.PreviewPlayheadSlider);
            self.measuringLag = false;
        end

        function prepare(self, app)
            self.tempo = app.TempoField.Value;
            self.duration = app.DurationField.Value * 60;
            self.fs = str2double(app.SampleRateDropDown.Value);
            self.metronome = Metronome(self);
            self.audioIn = zeros(self.duration * self.fs + 2 * self.fs, 1);
            self.audioCursor = 1;
            self.timingInfo.prepare(self);

            self.app.EarlyLamp.Color = Colours.grey;
            self.app.OKLamp.Color = Colours.grey;
            self.app.LateLamp.Color = Colours.grey;
        end

        function addFrame(self, frame)
            self.audioIn(self.audioCursor:self.audioCursor + length(frame) - 1) = frame;
            self.audioCursor = self.audioCursor + length(frame);
            self.timingInfo.addFrame(frame);

            if ~isempty(self.timingInfo.onsets)
                recentError = self.timingInfo.onsets(self.timingInfo.onsetInfoCursor - 1);

                if strcmp(recentError.timing, 'Early')
                    self.app.EarlyLamp.Color = Colours.red;
                    self.app.OKLamp.Color = Colours.grey;
                    self.app.LateLamp.Color = Colours.grey;
                elseif strcmp(recentError.timing, 'Late')
                    self.app.EarlyLamp.Color = Colours.grey;
                    self.app.OKLamp.Color = Colours.grey;
                    self.app.LateLamp.Color = Colours.red;
                else
                    self.app.EarlyLamp.Color = Colours.grey;
                    self.app.OKLamp.Color = Colours.green;
                    self.app.LateLamp.Color = Colours.grey;
                end

                self.app.TimingGauge.Value = 0.05 * double(recentError.value) / self.timingInfo.timingTolerance;
            end

        end

        function runPractice(self, app)

            if self.timingInfo.audioLag == 0 && not(self.measuringLag)
                msgbox('No previously saved information about your system latency was found. Before starting the session, please measure the audio lag of your system. You can do that from the "Settings" tab.');
                return;
            end

            %% Setup player
            self.prepare(app);
            app.player = audioplayer(self.metronome.audio, str2double(app.SampleRateDropDown.Value), 16, app.OutputDeviceDropDown.Value);
            set(app.player, 'TimerPeriod', 1);
            set(app.player, 'TimerFcn', @clockDisplayCallback);
            set(app.player, 'UserData', app);

            %% Setup recorder
            app.deviceReader = audioDeviceReader('SampleRate', str2double(app.SampleRateDropDown.Value), 'SamplesPerFrame', str2double(app.BufferSizeDropDown.Value), 'Device', app.InputDeviceDropDown.Value);
            setup(app.deviceReader);

            % Wait for the soundcard to set up
            pause(2);

            %% Play and record
            play(app.player);
            self.recordPractice(app);

            %% Release resources
            release(app.deviceReader);

            self.cleanUp();
            self.runExtAnalysis();

            %% Plot the results
            self.resultsReady = true;
            self.resultsPlot.plotSession(self);
        end

        function stopPractice(~, app)

            if app.player ~= 0
                stop(app.player);
            end

        end

        function recordPractice(self, app)
            tic;

            while app.player.isplaying() && toc <= self.duration + 1
                drawnow();

                [audioFrame, numOverrun] = app.deviceReader();

                if numOverrun ~= 0
                    app.DropoutWarning.Visible = true;
                end

                self.addFrame([zeros(numOverrun, 1); audioFrame]);
            end

            % Debug
            % cursor = 1;
            % frameSize = 512;
            % testAudio = audioread('resources/testPiano.wav');

            % while cursor + frameSize < length(testAudio)
            %     audioFrame = testAudio(cursor:cursor + frameSize - 1);
            %     cursor = cursor + frameSize;
            %     self.addFrame(audioFrame);
            %     % pause(length(audioFrame) / self.fs);
            % end
        end

        function measureAudioLag(self, app)
            self.measuringLag = true;
            app.UIFigure.Visible = 'off';
            multiWaitbar('Measuring average audio lag...');
            setTempo = app.TempoField.Value;
            setDuration = app.DurationField.Value;

            app.TempoField.Value = 120;
            app.DurationField.Value = 1/60;
            self.timingInfo.audioLag = 0;

            numIter = 5;
            lagSum = 0;

            for iter = 1:numIter
                self.runPractice(app);
                lagSum = lagSum + self.timingInfo.average;
                multiWaitbar('Measuring average audio lag...', iter / numIter);
                pause(1);
            end

            audioLag = round(lagSum / numIter);
            self.timingInfo.audioLag = audioLag;
            save('resources/audioLag.mat', 'audioLag');

            app.TempoField.Value = setTempo;
            app.DurationField.Value = setDuration;
            app.EarlyLamp.Color = Colours.grey;
            app.OKLamp.Color = Colours.grey;
            app.LateLamp.Color = Colours.grey;
            app.TimingGauge.Value = 0;
            app.UIFigure.Visible = 'on';
            cla(app.TimingPlot);
            multiWaitbar('Measuring average audio lag...', 'Close');
            self.app.AudioLagLabel.Text = sprintf('Audio lag: %d samples', self.timingInfo.audioLag);
            self.app.AudioLagLamp.Color = Colours.green;
            self.measuringLag = false;
        end

        function cleanUp(self)

            if self.audioCursor < length(self.audioIn)
                self.audioIn = self.audioIn(1:self.audioCursor);
            end

            self.timingInfo.analyseRemaining();
            self.timingInfo.cleanUp();
            self.lagCompAudioIn = self.audioIn(round(self.timingInfo.fftSize * 0.6563) + self.timingInfo.audioLag + 1:end);
        end

        function runExtAnalysis(self)
            self.timingInfo.runExtAnalysis();
        end

        function playFromCursor(self, app)

            if ~self.resultsReady
                return;
            end

            app.RecordingVolumeSlider.Enable = false;
            app.MetronomeVolumeSlider.Enable = false;
            app.PlaybackRateSlider.Enable = false;

            if length(self.metronome.audio) > length(self.lagCompAudioIn)
                alignedMetro = self.metronome.audio(1:length(self.lagCompAudioIn));
            end

            if length(self.metronome.audio) < length(self.lagCompAudioIn)
                alignedMetro = [self.metronome.audio; zeros(length(self.lagCompAudioIn) - length(self.metronome.audio), 1)];
            end

            startIndex = max(1, int64(self.resultsPlot.playheadLoc));

            if app.StopAfterOneOnsetCheckBox.Value && not(isempty(self.timingInfo.onsets))
                cursor = 1;

                while cursor <= length(self.timingInfo.onsets) && self.timingInfo.onsets(cursor).loc < self.resultsPlot.playheadLoc
                    cursor = cursor + 1;
                end

                stopIndex = self.timingInfo.onsets(cursor + 1).loc;

                toPlay = app.RecordingVolumeSlider.Value^2 * self.lagCompAudioIn(startIndex:stopIndex) + app.MetronomeVolumeSlider.Value^2 * alignedMetro(startIndex:stopIndex);
            else
                toPlay = app.RecordingVolumeSlider.Value^2 * self.lagCompAudioIn(startIndex:end) + app.MetronomeVolumeSlider.Value^2 * alignedMetro(startIndex:end);
            end

            if ~isempty(toPlay)
                rate = 2^(app.PlaybackRateSlider.Value);
                app.player = audioplayer(toPlay, str2double(app.SampleRateDropDown.Value) * rate, 16, app.OutputDeviceDropDown.Value);
                set(app.player, 'StopFcn', @reactivatePlaybackSlidersCallback);
                set(app.player, 'UserData', app);
                set(app.player, 'TimerPeriod', 1/8);
                set(app.player, 'TimerFcn', @movePlayheadCallback)
                play(app.player);
            end

        end

        function stopPlayingFromCursor(~, app)

            if app.player ~= 0
                stop(app.player);
            end

            app.RecordingVolumeSlider.Enable = true;
            app.MetronomeVolumeSlider.Enable = true;
        end

        function saveSessionSettings(~, app)
            sensitivity = app.DetectionSensitivityKnob.Value;
            sessionTempo = app.TempoField.Value;
            sessionDuration = app.DurationField.Value;
            tolerance = app.PermissibleErrorField.Value;
            save('resources/sessionSettings.mat', 'sensitivity', 'sessionTempo', 'sessionDuration', 'tolerance');
        end

    end

end
