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
    end

    methods

        function self = PracticeSession(app)
            self.app = app;
            self.timingInfo = TimingInfo();

            if exist('resources/audioLag.mat', 'file')
                lagStruct = load('resources/audioLag.mat');
                self.timingInfo.audioLag = lagStruct.audioLag;
            end

            self.resultsReady = false;
            self.resultsPlot = ResultsPlot(self, app.TimingPlot, app.TimingPlotPreview, app.PlayheadSlider, app.PreviewPlayheadSlider);
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

            if ~isempty(self.timingInfo.errors)
                recentError = self.timingInfo.errors(self.timingInfo.errorCursor - 1);

                if strcmp(recentError.timing, 'early')
                    self.app.EarlyLamp.Color = Colours.red;
                    self.app.OKLamp.Color = Colours.grey;
                    self.app.LateLamp.Color = Colours.grey;
                elseif strcmp(recentError.timing, 'late')
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
            %% Setup player
            self.prepare(app);
            app.player = audioplayer(self.metronome.audio, str2double(app.SampleRateDropDown.Value), 16, app.OutputDeviceDropDown.Value);

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

            self.timingInfo.analyseRemaining();
            self.timingInfo.cleanUp();
            self.runExtAnalysis()

            %% Plot the results
            self.resultsReady = true;
            self.resultsPlot.plotSession(self);
            app.ResultsTextArea.Value = sprintf('Average: %d\nAverage early: %d\nAverage late: %d', self.timingInfo.average, self.timingInfo.avgEarly, self.timingInfo.avgLate);
        end

        function stopPractice(~, app)
            stop(app.player);
        end

        function recordPractice(self, app)
            tic;

            while app.player.isplaying() && toc <= self.duration + 1
                drawnow();
                [audioFrame, numOverrun] = app.deviceReader();

                if numOverrun ~= 0
                    disp('Overrun');
                    disp(numOverrun);
                end

                self.addFrame([zeros(numOverrun, 1); audioFrame]);
            end

            % Debug
            % cursor = 1;
            % frameSize = 256;
            % testAudio = audioread('resources/test.wav');

            % while cursor + frameSize < length(testAudio)
            %     audioFrame = testAudio(cursor:cursor + frameSize - 1);
            %     cursor = cursor + frameSize;
            %     self.addFrame(audioFrame);
            %     pause(length(audioFrame) / self.fs);
            % end
        end

        function measureAudioLag(self, app)
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
            app.TabGroup.SelectedTab = app.MainTab;
            cla(app.TimingPlot);
            app.ResultsTextArea.Value = '';
            multiWaitbar('Measuring average audio lag...', 'Close');
        end

        function runExtAnalysis(self)
            self.timingInfo.cleanUp();
            self.timingInfo.runExtAnalysis();
        end

    end

end
