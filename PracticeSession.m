classdef PracticeSession < handle

    properties
        tempo;
        duration;
        fs;
        metronome;
        audioIn;
        audioCursor;
        timingInfo;
    end

    methods

        function self = PracticeSession()
            self.timingInfo = TimingInfo();
        end

        function prepare(self, app)
            self.tempo = app.TempoField.Value;
            self.duration = app.DurationField.Value * 60;
            self.fs = str2double(app.SampleRateDropDown.Value);
            self.metronome = Metronome(self);
            self.audioIn = zeros(self.duration * self.fs + 2 * self.fs, 1);
            self.audioCursor = 1;
            self.timingInfo.prepare(self);
        end

        function addFrame(self, frame)
            self.audioIn(self.audioCursor:self.audioCursor + length(frame) - 1) = frame;
            self.audioCursor = self.audioCursor + length(frame);
            self.timingInfo.addFrame(frame);
        end

        function runPractice(self, app)
            %% Setup player
            self.prepare(app);
            app.player = audioplayer(self.metronome.audio, str2double(app.SampleRateDropDown.Value));

            %% Setup recorder
            app.deviceReader = audioDeviceReader(str2double(app.SampleRateDropDown.Value), str2double(app.BufferSizeDropDown.Value));
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

            %% TMP
            self.plot(app.TimingPlot);
            app.ResultsTextArea.Value = sprintf('Average: %d\nAverage early: %d\nAverage late: %d', self.timingInfo.average, self.timingInfo.avgEarly, self.timingInfo.avgLate);
        end

        function stopPractice(self, app)
            stop(app.player);
        end

        function recordPractice(self, app)
            tic;

            while app.player.isplaying() && toc <= self.duration + 1
                drawnow();
                [audioFrame, numOverrun] = app.deviceReader();
                self.addFrame([zeros(numOverrun, 1); audioFrame]);
            end

            %% Debug
            % cursor = 1;
            % frameSize = 256;
            % testAudio = audioread('audioResources/metronome.wav');
            % testAudio = circshift(testAudio, 8000);

            % while cursor + frameSize < length(testAudio)
            %     audioFrame = testAudio(cursor:cursor + frameSize - 1);
            %     cursor = cursor + frameSize;
            %     self.addFrame(audioFrame);
            % end
        end

        function measureAudioLag(self, app)
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
                lagSum = lagSum + self.timingInfo.errors(1).value;
                multiWaitbar('Measuring average audio lag...', iter / numIter);
                pause(1);
            end

            self.timingInfo.audioLag = round(lagSum / numIter);

            app.TempoField.Value = setTempo;
            app.DurationField.Value = setDuration;
            multiWaitbar('Measuring average audio lag...', 'Close');
        end

        function runExtAnalysis(self)
            self.timingInfo.cleanUp();
            self.timingInfo.runExtAnalysis();
        end

        function plot(self, ax)
            lagCompAudioIn = self.audioIn(self.timingInfo.audioLag + 1:end);
            lagCompNovelty = self.timingInfo.novelty(self.timingInfo.audioLag + 1:end);
            time = linspace(0, length(lagCompAudioIn) / self.fs, length(lagCompAudioIn));
            plot(ax, time, lagCompAudioIn);
            hold(ax, 'on');
            plot(ax, time, lagCompNovelty);
            onsetTimes = self.timingInfo.onsetLocs / self.fs;
            plot(ax, onsetTimes, zeros(length(onsetTimes), 1), 'x', 'LineWidth', 2, 'MarkerSize', 10, 'Color', 'r');
            tickTimes = self.timingInfo.tickLocs / self.fs;
            plot(ax, tickTimes, zeros(length(tickTimes), 1), '+', 'LineWidth', 2, 'MarkerSize', 10, 'Color', 'g');
            hold(ax, 'off');
        end

    end

end
