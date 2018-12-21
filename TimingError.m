classdef TimingError < handle
    properties
        onset;
        prevTick;
        nextTick;
        closestTick;
        value;
        isEarly;
    end

    methods
        function self = TimingError(onset, prevTick, nextTick)
            self.onset = onset;
            self.prevTick = prevTick;
            self.nextTick = nextTick;

            if (onset - prevTick < nextTick - onset || nextTick == 0) && prevTick ~= 0
                self.closestTick = prevTick;
                self.isEarly = false;
            else
                self.closestTick = nextTick;
                self.isEarly = true;
            end

            self.value = self.onset - self.closestTick;
        end
    end
end