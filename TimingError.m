classdef TimingError < handle
    properties
        onset;
        prevTick;
        nextTick;
        closestTick;
        value;
        timing;
        tolerance;
    end

    methods
        function self = TimingError(onset, prevTick, nextTick, tolerance)
            self.onset = onset;
            self.prevTick = prevTick;
            self.nextTick = nextTick;
            self.tolerance = tolerance;

            if (onset - prevTick < nextTick - onset || nextTick == 0) && prevTick ~= 0
                self.closestTick = prevTick;
                self.timing = 'late';
            else
                self.closestTick = nextTick;
                self.timing = 'early';
            end
            
            self.value = self.onset - self.closestTick;

            if abs(self.value) < self.tolerance
                self.timing = 'ok';
            end
        end
    end
end