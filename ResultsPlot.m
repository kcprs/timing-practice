% Kacper Sagnowski, Musical Performance Analysis Systems assignment

classdef ResultsPlot < handle
    % ResultsPlot Handles plotting session results in the "Results" tab

    properties
        session;                % Handle of the currently active session
        mainPlot;               % Handle of the main (detailed) results plot
        previewPlot;            % Handle of the preview plot
        playheadLoc;            % Location of the playhead (cursor) in samples
        playheadPlot;           % Handle of the playhead plot in the main figure
        playheadPreviewPlot;    % Handle of the playhead plot in the preview figure
        playheadSlider;         % Handle of the slider for adjusting playhead position below the main figure
        previewPlayheadSlider;  % Handle of the slider for adjusting playhead position above the preview figure
        zoomFactor;             % Factor for zooming into the detailed plot. Range: 0-1
        initXLim;               % Initial XLimits of the main plot (no zoom)
        initYLim;               % Initial YLimits of the main plot
        onsetInfoDisplayer;     % Handle of an OnsetInfoDisplayer object
        zoomRectangle;          % Handle of a rectangle object for marking zoom range
        initPreviewXLim;        % Initial XLimits of the preview figure
        initPreviewYLim;        % Initial YLimits of the preview figure
    end

    methods

        function self = ResultsPlot(session, mainPlot, previewPlot, playheadSlider, previewPlayheadSlider)
            % ResultsPlot Constructor for the ResultsPlot class 

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
            self.initPreviewYLim = [-1, 1];
            self.zoomRectangle = 0;
        end

        function plotSession(self, session)
            % plotSession Plots session data in the Results tab

            self.onsetInfoDisplayer = OnsetInfoDisplayer(session.app, self.playheadLoc);
            
            % Save plot limits (bounds) for the preview
            leftBound = 1;
            rightBound = length(session.lagCompAudioIn);

            % Plot the preview in the top part of the GUI
            plot(self.previewPlot, session.lagCompAudioIn);
            self.initPreviewXLim = [leftBound, rightBound];
            self.previewPlot.XLim = [leftBound, rightBound];
            self.initPreviewYLim = self.previewPlot.YLim;

            % Plot the detailed plot in the main figure
            plot(self.mainPlot, session.lagCompAudioIn);
            hold(self.mainPlot, 'on');
            plot(self.mainPlot, session.timingInfo.correctOnsetLocs, zeros(length(session.timingInfo.correctOnsetLocs), 1), 'x', 'LineWidth', 2, 'MarkerSize', 10, 'Color', 'g');
            plot(self.mainPlot, session.timingInfo.incorrectOnsetLocs, zeros(length(session.timingInfo.incorrectOnsetLocs), 1), 'x', 'LineWidth', 2, 'MarkerSize', 10, 'Color', 'r');
            hold(self.mainPlot, 'off');

            % Save plot limits (bounds) for the main plot
            self.mainPlot.XLim = [leftBound, rightBound];
            self.initXLim = [leftBound, rightBound];
            self.initYLim = self.mainPlot.YLim;

            % Add grid in metronome tick positions
            set(self.mainPlot, 'XGrid', 'on', 'XTick', self.session.timingInfo.tickLocs);

            % Set playhead and zoom to initial values
            self.movePlayhead(1);
            self.zoom(0);
        end

        function movePlayheadTo(self, direction, locType)
            % movePlayheadTo Moves playhead to next/previous onset or metronome tick

            if ~self.session.resultsReady
                return;
            end

            % Save onset or tick locations to the locs variable
            if strcmp(locType, 'onset')
                if isempty(self.session.timingInfo.onsets)
                    return;
                end

                locs = self.session.timingInfo.onsetLocs;
            elseif strcmp(locType, 'tick')
                locs = self.session.timingInfo.tickLocs;
            else
                error('Unknown loc type');
            end

            % Set up the search for next/previous location
            if strcmp(direction, 'next')
                % Start from 1 and search up
                cursor = 1;
                dirFactor = 1;
            elseif strcmp(direction, 'previous')
                % Start from the end and search down
                cursor = length(locs);
                dirFactor = -1;
            else
                error('Unknown direction')
            end

            % Step through the locs vector in the direction of dirFactor while:
            %     (    the cursor stays within the limits of the locs vector    ) and(      the onset/tick is before/after the playhead       )
            while (cursor + dirFactor <= length(locs) && cursor + dirFactor >= 1) && (locs(cursor) * dirFactor <= self.playheadLoc * dirFactor)
                cursor = cursor + dirFactor;
            end

            % Move the playhead to the new location
            self.movePlayhead(locs(cursor));
        end

        function movePlayhead(self, sampleLoc)
            % movePlayhead Moves playhead to a given location (sample)

            if ~self.session.resultsReady
                return;
            end

            % Force new location to stay within allowed limits
            sampleLoc = max(1, min(sampleLoc, length(self.session.lagCompAudioIn)));

            % Save playhead location
            self.playheadLoc = sampleLoc;

            % If the user accidentally scrolled the plots by clicking and dragging
            % within the plot, reset limits
            self.previewPlot.XLim = self.initPreviewXLim;
            self.previewPlot.YLim = self.initPreviewYLim;
            self.mainPlot.YLim = self.initYLim;

            % Update playhead slider
            playheadSliderValue = (self.playheadLoc - self.mainPlot.XLim(1)) / (self.mainPlot.XLim(2) - self.mainPlot.XLim(1));

            if 0.1 <= playheadSliderValue && playheadSliderValue <= 0.9
                self.playheadSlider.Value = playheadSliderValue;
            else
                % If playhead is close to the edge of the main plot, scroll to follow the cursor
                % Here zoom resets cursor position
                self.zoom(self.zoomFactor);
                self.playheadSlider.Value = max(0, min(1, (self.playheadLoc - self.mainPlot.XLim(1)) / (self.mainPlot.XLim(2) - self.mainPlot.XLim(1))));
            end

            % Update playhead plot.
            % If exists, delete previous playhead plot
            if self.playheadPlot ~= 0
                delete(self.playheadPlot);
            end

            hold(self.mainPlot, 'on');
            self.playheadPlot = plot(self.mainPlot, [sampleLoc, sampleLoc], self.mainPlot.YLim, 'Color', 'r');
            hold(self.mainPlot, 'off');

            % Update playhead slider for the preview
            self.previewPlayheadSlider.Value = max(0, min(1, sampleLoc / (self.previewPlot.XLim(2) - self.previewPlot.XLim(1))));

            % Update playhead plot in the preview
            % If exists, delete previous playhead preview plot
            if self.playheadPreviewPlot ~= 0
                delete(self.playheadPreviewPlot);
            end

            hold(self.previewPlot, 'on');
            self.playheadPreviewPlot = plot(self.previewPlot, [sampleLoc, sampleLoc], self.previewPlot.YLim, 'Color', 'r');
            hold(self.previewPlot, 'off');

            % Update displayed onset info
            self.onsetInfoDisplayer.selectAt(self.playheadLoc);
        end

        function zoom(self, zoomFactor)
            % zoom Zooms into the main (detailed) plot by a given factor

            if ~self.session.resultsReady
                return;
            end

            % If the user accidentally scrolled the plots by clicking and dragging within the plot, reset limits
            self.previewPlot.XLim = self.initPreviewXLim;
            self.previewPlot.YLim = self.initPreviewYLim;
            self.mainPlot.YLim = self.initYLim;

            % Save current zoom factor and update the slider
            self.zoomFactor = zoomFactor;
            self.session.app.ZoomSlider.Value = zoomFactor;

            % Find the requested span (difference between XLimits).
            % Using sqrt(zoomFactor) here because it remains in the range 0-1,
            % but gives better precision at the top of the range.
            initSpan = self.initXLim(2) - self.initXLim(1);
            maxZoomSpan = self.session.fs / 4;
            currentSpan = initSpan - sqrt(zoomFactor) * (initSpan - maxZoomSpan);

            % Find new XLimits (bounds) for the main plot
            leftBoundRequested = self.playheadLoc - currentSpan / 2;
            leftBoundPossible = max(leftBoundRequested, self.initXLim(1));

            rightBoundRequested = self.playheadLoc + currentSpan / 2;
            rightBoundPossible = min(rightBoundRequested, self.initXLim(2));

            leftBound = max(leftBoundPossible - rightBoundRequested + rightBoundPossible, self.initXLim(1));
            rightBound = min(rightBoundPossible - leftBoundRequested + leftBoundPossible, self.initXLim(2));

            % Set the new value and update the playhead slider
            self.mainPlot.XLim = [leftBound, rightBound];
            self.playheadSlider.Value = max(0, min(1, (self.playheadLoc - self.mainPlot.XLim(1)) / (self.mainPlot.XLim(2) - self.mainPlot.XLim(1))));

            % Update the zoom rectangle in the preview.
            if self.zoomRectangle ~= 0
                delete(self.zoomRectangle);
            end

            if self.zoomFactor ~= 0
                left = self.mainPlot.XLim(1);
                bottom = self.previewPlot.YLim(1);
                rectWidth = self.mainPlot.XLim(2) - self.mainPlot.XLim(1);
                height = self.previewPlot.YLim(2) - self.previewPlot.YLim(1);
                self.zoomRectangle = rectangle(self.previewPlot, 'Position', [left, bottom, rectWidth, height], 'EdgeColor', 'none', 'FaceColor', Colours.transparentBlue);
            end

        end

        function playheadSliderMoved(self, sliderValue)
            % playheadSliderMoved Converts slider value to playhead position and moves the playhead

            self.movePlayhead(self.mainPlot.XLim(1) + sliderValue * (self.mainPlot.XLim(2) - self.mainPlot.XLim(1)));
        end

        function previewPlayheadSliderMoved(self, sliderValue)
            % previewPlayheadSliderMoved Converts preview slider value to playhead position and moves the playhead

            self.movePlayhead(self.previewPlot.XLim(1) + sliderValue * (self.previewPlot.XLim(2) - self.previewPlot.XLim(1)));
        end

    end

end
