classdef OnsetInfo < handle

    properties
        loc;
        prevTick;
        nextTick;
        closestTick;
        value;
        timing;
        tolerance;
    end

    methods

        function self = OnsetInfo(loc, prevTick, nextTick, tolerance)
            self.loc = loc;
            self.prevTick = prevTick;
            self.nextTick = nextTick;
            self.tolerance = tolerance;

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
