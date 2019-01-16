% Kacper Sagnowski, Musical Performance Analysis Systems assignment

classdef OnsetInfoDisplayer < handle
    % OnsetInfoDisplayer Class for graphically displaying timing info of onsets

    properties
        app;                    % Handle of the currently running app instance
        session;                % Handle of the currently active session
        onsets;                 % Vector of OnsetInfo objects detected in the session
        selectedOnset;          % Handle of the currently selected OnsetInfo object
        playheadLoc;            % Location of the playhead (cursor) in the Results tab of
                                % the app. This is used to select onsets.
        selectionRectangle;     % Handle of the rectangle object used to mark the selection on a plot
        selectionCircle;        % Handle of the circle object used to mark the selection on a plot
    end

    methods

        function self = OnsetInfoDisplayer(app, playheadLoc)
            % OnsetInfoDisplayer Constructor for the OnsetInfoDisplayer class

            self.app = app;
            self.session = app.session;
            self.onsets = self.session.timingInfo.onsets;
            self.selectionRectangle = 0;
            self.selectionCircle = 0;
            self.displayGlobalInfo()
            self.selectAt(playheadLoc);
        end

        function selectAt(self, playheadLoc)
            % selectAt Selects an onset based on playhead position

            if isempty(self.onsets())
                return;
            end

            self.playheadLoc = playheadLoc;

            % Search for an onset directly preceding playheadLoc and select it
            cursor = 1;
            while cursor <= length(self.onsets) && self.onsets(cursor).loc <= playheadLoc
                cursor = cursor + 1;
            end

            self.selectedOnset = self.onsets(max(1, cursor - 1));

            % Update GUI
            self.displayOnsetInfo();
            self.drawSelectionRange();
        end

        function displayGlobalInfo(self)
            % displayGlobalInfo Graphically displays global onset parameters in the current session

            self.app.AverageErrorLabel.Text = sprintf('Average error: %0.2f ms', double(self.session.timingInfo.average) / double(self.session.fs) * 1000);
            self.app.AverageLateErrorLabel.Text = sprintf('Average late error: %0.2f ms', double(self.session.timingInfo.avgLate) / double(self.session.fs) * 1000);
            self.app.AverageEarlyErrorLabel.Text = sprintf('Averge early error: %0.2f ms', double(self.session.timingInfo.avgEarly) / double(self.session.fs) * 1000);
            self.app.NumberOfEarlyOnsetsLabel.Text = sprintf('Number of early onsets: %d', self.session.timingInfo.earlyNum);
            self.app.NumberOfLateOnsetsLabel.Text = sprintf('Number of late onsets: %d', self.session.timingInfo.lateNum);
            self.app.NumberOfCorrectOnsetsLabel.Text = sprintf('Number of correct onsets: %d', self.session.timingInfo.correctNum);
        end

        function displayOnsetInfo(self)
            % displayOnsetInfo Graphically displays parameters of the selected onset

            self.app.TimestampLabel.Text = sprintf('Timestamp: %0.2f s', double(self.selectedOnset.loc) / double(self.session.fs));
            self.app.TimingLabel.Text = ['Timing: ', self.selectedOnset.timing];
            self.app.ErrorLabel.Text = sprintf('Error: %0.2f ms', double(self.selectedOnset.value) / double(self.session.fs) * 1000);
        end

        function drawSelectionRange(self)
            % drawSelectionRange Draws graphical elements marking the current selection in the results plot

            % If exists, erase previous selection circle
            if self.selectionCircle ~= 0
                delete(self.selectionCircle)
            end

            % Pick colour based on onset timing
            if strcmp(self.selectedOnset.timing, 'OK')
                markerColour = Colours.green;
                rectColour = Colours.transparentGreen;
            else
                markerColour = Colours.red;
                rectColour = Colours.transparentRed;
            end

            % Draw new selection circle
            hold(self.app.TimingPlot, 'on');
            self.selectionCircle = plot(self.app.TimingPlot, self.selectedOnset.loc, 0, 'o', 'Color', markerColour, 'MarkerSize', 20, 'LineWidth', 2);
            hold(self.app.TimingPlot, 'off');

            % If exists, erase previous selection circle
            if self.selectionRectangle ~= 0
                delete(self.selectionRectangle)
            end

            % Find position and size of the new selection rectangle
            left = self.selectedOnset.loc;
            
            cursor = 1;
            while cursor <= length(self.onsets) && self.onsets(cursor).loc < left
                cursor = cursor + 1;
            end

            rectWidth = self.onsets(min(length(self.onsets), cursor + 1)).loc - left;

            if rectWidth == 0
                rectWidth = self.app.TimingPlot.XLim(2) - left;
            end

            % Draw new selection rectangle
            hold(self.app.TimingPlot, 'on');
            self.selectionRectangle = rectangle(self.app.TimingPlot, 'Position', [left, -1, rectWidth, 2], 'EdgeColor', 'none', 'FaceColor', rectColour);
            hold(self.app.TimingPlot, 'off');
        end

    end

end
