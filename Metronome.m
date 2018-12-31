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

            tick = [zeros(length(tick), 1); tick];
            self.audio = conv(self.ticks, tick, 'same');

            close(wb)
        end

        function tickLocs = getTickLocs(self)
            tickLocs = zeros(length(self.ticks), 1);
            cursor = 1;

            for iter = 1:length(self.ticks)

                if self.ticks(iter) == 1
                    tickLocs(cursor) = iter;
                    cursor = cursor + 1;
                end

            end

            tickLocs = tickLocs(1:cursor - 1);
            
            % plot(self.audio);
            % hold('on');
            % plot(tickLocs, ones(length(tickLocs)), 'x');
            % hold('off');
        end

        function tickDist = getTickDistance(self)
            tickDist = idivide(60 * self.fs, int32(self.tempo), 'round');
        end

    end

end
