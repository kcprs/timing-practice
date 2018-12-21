classdef Metronome < handle
    properties
        tempo;
        fs;
        audio;
        ticks;
    end

    methods
        function self = Metronome(tempo, duration, fs)
            self.tempo = tempo;
            self.fs = fs;
            tick = audioread('audioResources/tick.wav');
            interval = idivide(60 * fs, int32(tempo), 'round');
            metronomeLength = interval * idivide(duration * fs, interval, 'round');
            self.ticks = zeros(metronomeLength, 1);

            cursor = 1;
            wb = waitbar(0, 'Generating metronome signal...');

            while cursor < metronomeLength
                self.ticks(cursor) = 1;
                cursor = cursor + interval;
                waitbar(cursor / metronomeLength, wb);
            end

            self.audio = conv(self.ticks, tick, 'same');

            close(wb)
        end

        function tickLocs = getTickLocs(self)
            [~, tickLocs] = findpeaks(self.ticks);
        end

        function tickDist = getTickDistance(self)
            tickDist = idivide(60 * self.fs, int32(self.tempo), 'round');
        end
    end
end