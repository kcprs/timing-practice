% Kacper Sagnowski, Musical Performance Analysis Systems assignment

classdef Metronome < handle
    % Metronome Provides metronome functionality to the app

    properties
        session;    % Handle to the currently active session
        audio;      % Audio containing metronome ticks
        ticks;      % Vector with 1's at tick positions, otherwise 0's
    end

    methods

        function self = Metronome(session)
            % Metronome Constructor for the Metronome class

            self.session = session;
            
            % Calculate the interval between ticks based on session tempo
            interval = idivide(60 * int64(self.session.fs), int64(self.session.tempo), 'round');
            
            % Calculate the length of metronome audio as an integer multiple of inter-tick intervals
            metronomeLength = interval * idivide(int64(self.session.duration * self.session.fs), interval, 'round');
            
            % Initialise the 'ticks' vector and put 1's at tick positions
            self.ticks = zeros(metronomeLength, 1);
            cursor = 1;
            multiWaitbar('Generating metronome signal...');
            
            while cursor < metronomeLength
                self.ticks(cursor) = 1;
                cursor = cursor + interval;
                progress = double(cursor) / double(metronomeLength);
                multiWaitbar('Generating metronome signal...', progress);
            end
            
            % Circshift the ticks vector based on the audioLag of the session
            % so that the onsets occur in the middle of processing buffers.
            % This is important for onset detection accuracy.
            self.ticks = circshift(self.ticks, floor(interval / 2) - session.timingInfo.audioLag);
            
            % Read the audio file containing a single metronome tick
            % and pad it so that the tick begins in the middle of the vector
            tick = audioread('resources/tick.wav');
            tick = [zeros(length(tick), 1); tick];

            % Convolve a single tick with the ticks vector, which effectively
            % puts a tick at each point where the ticks vector contains a 1.
            % Save this to be the metronome audio.
            self.audio = conv(self.ticks, tick, 'same');

            multiWaitbar('Generating metronome signal...', 'Close');
        end

        function tickLocs = getTickLocs(self)
            % getTickLocs Returns locations (indexes) of ticks in the metronome vector.

            % Pre-allocate the vector with maximum possible number of ticks
            tickLocs = zeros(length(self.ticks), 1);
            
            % Iterate over the ticks vector and save indexes at which it is equal to 1
            cursor = 1;
            for iter = 1:length(self.ticks)

                if self.ticks(iter) == 1
                    tickLocs(cursor) = iter;
                    cursor = cursor + 1;
                end

            end

            % Trim the remainder of the pre-allocated vector
            tickLocs = tickLocs(1:cursor - 1);
        end

        function tickDist = getTickDistance(self)
            % getTickDistance Returns the distance between metronome ticks in samples
            tickDist = idivide(int64(60 * self.session.fs), int64(self.session.tempo), 'round');
        end

    end

end
