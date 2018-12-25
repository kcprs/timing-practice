classdef PracticeSession < handle

    properties
        tempo;
        duration;
        fs;
        metronome;
        audioIn;
        timingInfo;
    end

    methods

        function self = PracticeSession(tempo, duration, fs)
            self.tempo = tempo;
            self.duration = duration;
            self.fs = fs;
            self.metronome = Metronome(tempo, duration, fs);
        end

        function analyse(self, subtractAverageLag)
            self.timingInfo = TimingInfo(self.audioIn, self.metronome, subtractAverageLag);
        end

        function plotSession(self, ax)
            time = linspace(0, length(self.audioIn) / self.fs, length(self.audioIn));
            plot(ax, time, self.audioIn);
            hold(ax, 'on');
            onsetTimes = self.timingInfo.onsetLocs / self.fs;
            plot(ax, onsetTimes, zeros(length(onsetTimes)), 'x', 'LineWidth', 2, 'MarkerSize', 10, 'Color', 'r');
            tickTimes = self.timingInfo.tickLocs / self.fs;
            plot(ax, tickTimes, zeros(length(tickTimes)), '+', 'LineWidth', 2, 'MarkerSize', 10, 'Color', 'g');
            hold(ax, 'off');
        end

    end

end
