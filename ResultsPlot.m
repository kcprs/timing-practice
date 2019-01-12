classdef ResultsPlot < handle

    properties
        session;
        mainPlot;
        previewPlot;
        playheadLoc;
        playheadPlot;
        playheadPreviewPlot;
        playheadSlider;
        previewPlayheadSlider;
        zoomFactor;
        initXLim;
        initYLim;
        onsetInfoDisplayer;
        zoomRectangle;
        initPreviewXLim;
    end

    methods

        function self = ResultsPlot(session, mainPlot, previewPlot, playheadSlider, previewPlayheadSlider)
            self.session = session;
            self.mainPlot = mainPlot;
            self.playheadSlider = playheadSlider;
            self.previewPlot = previewPlot;
            self.previewPlayheadSlider = previewPlayheadSlider;
            self.playheadPlot = 0;
            self.playheadPreviewPlot = 0;
            self.playheadLoc = 1;
            self.zoomFactor = 0;
            self.initXLim = [0, 1];
            self.initPreviewXLim = [0, 1];
            self.zoomRectangle = 0;
        end

        function plotSession(self, session)
            self.onsetInfoDisplayer = OnsetInfoDisplayer(session.app, self.playheadLoc);
            lagCompAudioIn = session.audioIn(session.timingInfo.audioLag + 1:end);
            lagCompNovelty = session.timingInfo.novelty(session.timingInfo.audioLag + 1:end);
            % time = linspace(0, length(lagCompAudioIn) / session.fs, length(lagCompAudioIn));
            leftBound = 0;
            rightBound = max(length(lagCompAudioIn), length(lagCompNovelty));

            % Plot the preview in the top
            plot(self.previewPlot, lagCompAudioIn);
            self.initPreviewXLim = [leftBound, rightBound];
            self.previewPlot.XLim = [leftBound, rightBound];
            self.previewPlot.YLim = [-1, 1];

            % Plot the detailed plot in the main figure
            plot(self.mainPlot, lagCompAudioIn);
            hold(self.mainPlot, 'on');
            % plot(self.mainPlot, lagCompNovelty);
            % plot(self.mainPlot, session.timingInfo.onsetLocs, zeros(length(session.timingInfo.onsetLocs), 1), '+', 'LineWidth', 2, 'MarkerSize', 10, 'Color', 'g');
            plot(self.mainPlot, session.timingInfo.tickLocs, zeros(length(session.timingInfo.tickLocs), 1), 'x', 'LineWidth', 2, 'MarkerSize', 10, 'Color', 'r');
            hold(self.mainPlot, 'off');

            self.mainPlot.XLim = [leftBound, rightBound];
            self.initXLim = [leftBound, rightBound];
            self.initYLim = self.mainPlot.YLim;

            set(self.mainPlot, 'XGrid', 'on', 'XTick', self.session.timingInfo.tickLocs);


            self.movePlayhead(1);
            self.zoom(0);
        end

        function movePlayheadTo(self, direction, locType)

            if ~self.session.resultsReady
                return;
            end

            if strcmp(locType, 'onset')
                locs = self.session.timingInfo.onsetLocs;
            elseif strcmp(locType, 'tick')
                locs = self.session.timingInfo.tickLocs;
            else
                error('Unknown loc type');
            end

            if strcmp(direction, 'next')
                dirFactor = 1;
                cursor = 1;
            elseif strcmp(direction, 'previous')
                dirFactor = -1;
                cursor = length(locs);
            else
                error('Unknown direction')
            end

            while cursor + dirFactor <= length(locs) && cursor + dirFactor >= 1 && locs(cursor) * dirFactor <= self.playheadLoc * dirFactor
                cursor = cursor + dirFactor;
            end

            self.movePlayhead(locs(cursor));
        end

        function movePlayhead(self, sampleLoc)

            if ~self.session.resultsReady
                return;
            end

            % Save playhead location
            self.playheadLoc = sampleLoc;

            %% Update playhead slider
            playheadSliderValue = (self.playheadLoc - self.mainPlot.XLim(1)) / (self.mainPlot.XLim(2) - self.mainPlot.XLim(1));

            if 0.1 <= playheadSliderValue && playheadSliderValue <= 0.9
                self.playheadSlider.Value = playheadSliderValue;
            else
                self.zoom(self.zoomFactor);
                self.playheadSlider.Value = max(0, min(1, (self.playheadLoc - self.mainPlot.XLim(1)) / (self.mainPlot.XLim(2) - self.mainPlot.XLim(1))));
            end

            %% Update playhead plot
            % If exists, delete previous playhead plot
            if self.playheadPlot ~= 0
                delete(self.playheadPlot);
            end

            hold(self.mainPlot, 'on');
            self.playheadPlot = plot(self.mainPlot, [sampleLoc, sampleLoc], self.mainPlot.YLim, 'Color', 'r');
            hold(self.mainPlot, 'off');

            %% Update playhead slider for the preview
            self.previewPlayheadSlider.Value = max(0, min(1, sampleLoc / (self.previewPlot.XLim(2) - self.previewPlot.XLim(1))));

            %% Update playhead plot in the preview
            % If exists, delete previous playhead preview plot
            if self.playheadPreviewPlot ~= 0
                delete(self.playheadPreviewPlot);
            end

            hold(self.previewPlot, 'on');
            self.playheadPreviewPlot = plot(self.previewPlot, [sampleLoc, sampleLoc], self.previewPlot.YLim, 'Color', 'r');
            hold(self.previewPlot, 'off');

            %% Update displayed onset info
            self.onsetInfoDisplayer.selectAt(self.playheadLoc);
        end

        function zoom(self, zoomFactor)

            if ~self.session.resultsReady
                return;
            end

            self.zoomFactor = zoomFactor;
            self.session.app.ZoomSlider.Value = zoomFactor;

            initSpan = self.initXLim(2) - self.initXLim(1);
            maxZoomSpan = self.session.fs;
            currentSpan = initSpan - zoomFactor * (initSpan - maxZoomSpan);

            leftBoundRequested = self.playheadLoc - currentSpan / 2;
            leftBoundPossible = max(leftBoundRequested, self.initXLim(1));

            rightBoundRequested = self.playheadLoc + currentSpan / 2;
            rightBoundPossible = min(rightBoundRequested, self.initXLim(2));

            leftBound = max(leftBoundPossible - rightBoundRequested + rightBoundPossible, self.initXLim(1));
            rightBound = min(rightBoundPossible - leftBoundRequested + leftBoundPossible, self.initXLim(2));

            self.mainPlot.XLim = [leftBound, rightBound];
            self.playheadSlider.Value = max(0, min(1, (self.playheadLoc - self.mainPlot.XLim(1)) / (self.mainPlot.XLim(2) - self.mainPlot.XLim(1))));

            if self.zoomRectangle ~= 0
                delete(self.zoomRectangle);
            end

            if self.zoomFactor ~= 0
                left = self.mainPlot.XLim(1);
                bottom = self.previewPlot.YLim(1);
                rectWidth = self.mainPlot.XLim(2) -self.mainPlot.XLim(1);
                height = self.previewPlot.YLim(2) - self.previewPlot.YLim(1);
                self.zoomRectangle = rectangle(self.previewPlot, 'Position', [left, bottom, rectWidth, height], 'EdgeColor', 'none', 'FaceColor', Colours.transparentGrey);
            end
        end

        function playheadSliderMoved(self, sliderValue)
            self.mainPlot.YLim = self.initYLim;
            self.movePlayhead(self.mainPlot.XLim(1) + sliderValue * (self.mainPlot.XLim(2) - self.mainPlot.XLim(1)));
        end

        function previewPlayheadSliderMoved(self, sliderValue)
            self.previewPlot.XLim = self.initPreviewXLim;
            self.previewPlot.YLim = [-1, 1];
            self.movePlayhead(self.previewPlot.XLim(1) + sliderValue * (self.previewPlot.XLim(2) - self.previewPlot.XLim(1)));
        end

    end

end
