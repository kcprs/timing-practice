% Kacper Sagnowski, Musical Performance Analysis Systems assignment

classdef OnsetInfo < handle
    % OnsetInfo Class that holds timing information of a single onset

    properties
        loc;            % Location of the onset in samples
        prevTick;       % Location of the preceding metronome tick in samples
        nextTick;       % Location of the following metronome tick in samples
        closestTick;    % Location of the closest metronome tick in samples
        value;          % Distance from onset location to the closest metronome tick
        timing;         % Timing verdict for the onset. Values: 'Early', 'OK', 'Late'
        tolerance;      % Maximum distance from the closest metronome
                        % tick for the onset's timing to be considered 'OK'
    end

    methods

        function self = OnsetInfo(loc, prevTick, nextTick, tolerance)
            % OnsetInfo Constructor for the OnsetInfo class

            self.loc = loc;
            self.prevTick = prevTick;
            self.nextTick = nextTick;
            self.tolerance = tolerance;

            % Decide on the timing verdict
            if (loc - prevTick < nextTick - loc || nextTick == 0) && prevTick ~= 0
                self.closestTick = prevTick;
                self.timing = 'Late';
            else
                self.closestTick = nextTick;
                self.timing = 'Early';
            end

            self.value = self.loc - self.closestTick;

            if abs(self.value) < self.tolerance
                self.timing = 'OK';
            end

        end

    end

end
