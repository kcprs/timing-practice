classdef ResultsPlot < handle
    properties
        session;
        ax;
        playheadLoc;
        playheadPlot;
        playheadSlider;
        initXLim;
    end

    methods
        function self = ResultsPlot(session, ax, slider)
            self.session = session;
            self.ax = ax;
            self.playheadSlider = slider;
            self.playheadPlot = 0;
            self.playheadLoc = 0;
        end

        function movePlayheadTo(self, direction, loc_type)
            if strcmp(loc_type, 'onset')
                locs = self.session.timingInfo.onsetLocs;
            elseif strcmp(loc_type, 'tick')
                locs = self.session.timingInfo.tickLocs;
            else
                error('Unknown loc type');
            end
        
            if strcmp(direction, 'next')
                dir_factor = 1;
                cursor = 1;
            elseif strcmp(direction, 'previous')
                dir_factor = -1;
                cursor = length(locs);
            else
                error('Unknown direction')
            end
        
            while cursor + dir_factor <= length(locs) && cursor + dir_factor >= 1 && locs(cursor) * dir_factor <= self.playheadLoc * dir_factor
                cursor = cursor + dir_factor;
            end
        
            self.movePlayhead(locs(cursor));
        end
        
        function movePlayhead(self, samplePos)
            self.playheadLoc = samplePos;
            playheadPosTime = samplePos / self.session.fs;
            self.playheadSlider.Value = samplePos / (self.session.fs * self.ax.XLim(2));
        
            if self.playheadPlot ~= 0
                delete(self.playheadPlot);
            end
        
            hold(self.ax, 'on');
            self.playheadPlot = plot(self.ax, [playheadPosTime, playheadPosTime], self.ax.YLim, 'Color', 'r');
            hold(self.ax, 'off');
        end

        function zoom(self, zoomFactor)
            leftBound = (self.initXLim(1) + 0.5) * (1 - zoomFactor) - 0.5 + self.playheadLoc / self.session.fs;
            rightBound = (self.initXLim(2) - 0.5) * (1 - zoomFactor) + 0.5 + self.playheadLoc / self.session.fs;

            self.ax.XLim = [leftBound, rightBound];
        end

        function playheadSliderMoved(self, sliderValue)
            self.movePlayhead(self.ax.XLim(1) * self.session.fs + sliderValue * self.session.fs * self.ax.XLim(2));
        end
    end

end