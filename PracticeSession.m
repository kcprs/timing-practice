classdef PracticeSession < handle

    properties
        tempo;
        duration;
        fs;
        metronome;
        audioIn;
        timingInfo;

        audioCursor;
    end

    methods

        function self = PracticeSession()
            self.timingInfo = TimingInfo();
        end

        function update(self, app)
            self.tempo = app.TempoField.Value;
            self.duration = app.DurationField.Value * 60;
            self.fs = str2double(app.SampleRateDropDown.Value);
            self.metronome = Metronome(self.tempo, self.duration, self.fs);
            self.audioIn = zeros(self.duration * self.fs + 2 * self.fs, 1);
            self.audioCursor = 1;
            self.timingInfo.prepare(self.duration, self.metronome);
        end

        function addFrame(self, frame)
            self.audioIn(self.audioCursor:self.audioCursor + length(frame) - 1) = frame;
            self.audioCursor = self.audioCursor + length(frame);
            self.timingInfo.addFrame(frame, self.audioCursor);
        end

        function runExtAnalysis(self)
            self.timingInfo.cleanUpOnsets();
            self.timingInfo.runExtAnalysis();
        end

        function plotSession(self, ax)
            lagCompAudioIn = self.audioIn(self.timingInfo.audioLag + 1:end);
            time = linspace(0, length(lagCompAudioIn) / self.fs, length(lagCompAudioIn));
            plot(ax, time, lagCompAudioIn);
            hold(ax, 'on');
            onsetTimes = self.timingInfo.onsetLocs / self.fs;
            plot(ax, onsetTimes, zeros(length(onsetTimes), 1), 'x', 'LineWidth', 2, 'MarkerSize', 10, 'Color', 'r');
            tickTimes = self.timingInfo.tickLocs / self.fs;
            plot(ax, tickTimes, zeros(length(tickTimes), 1), '+', 'LineWidth', 2, 'MarkerSize', 10, 'Color', 'g');
            hold(ax, 'off');
        end

    end

end
