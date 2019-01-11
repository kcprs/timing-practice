classdef Metronome < handle

    properties
        session;
        audio;
        ticks;
    end

    methods

        function self = Metronome(session)
            self.session = session;
            tick = audioread('resources/tick.wav');
            interval = idivide(60 * int64(self.session.fs), int64(self.session.tempo), 'round');
            metronomeLength = interval * idivide(int64(self.session.duration * self.session.fs), interval, 'round');
            self.ticks = zeros(metronomeLength, 1);

            cursor = 1;
            multiWaitbar('Generating metronome signal...');

            while cursor < metronomeLength
                self.ticks(cursor) = 1;
                cursor = cursor + interval;
                progress = double(cursor) / double(metronomeLength);
                multiWaitbar('Generating metronome signal...', progress);
            end

            self.ticks = circshift(self.ticks, floor(interval / 2));
            tick = [zeros(length(tick), 1); tick];
            self.audio = conv(self.ticks, tick, 'same');

            multiWaitbar('Generating metronome signal...', 'Close');
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
            tickDist = idivide(int64(60 * self.session.fs), int64(self.session.tempo), 'round');
        end

    end

end
