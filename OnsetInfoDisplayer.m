classdef OnsetInfoDisplayer < handle

    properties
        app;
        session;
        onsets;
        selectedOnset;
        playheadLoc;
        selectionRectangle;
        selectionCircle;
    end

    methods

        function self = OnsetInfoDisplayer(app, playheadLoc)
            self.app = app;
            self.session = app.session;
            self.onsets = self.session.timingInfo.onsets;
            self.selectionRectangle = 0;
            self.selectionCircle = 0;
            self.displayGlobalInfo()
            self.selectAt(playheadLoc);
        end

        function selectAt(self, playheadLoc)
            self.playheadLoc = playheadLoc;

            cursor = 1;

            while cursor <= length(self.onsets) && self.onsets(cursor).loc <= playheadLoc
                cursor = cursor + 1;
            end

            self.selectedOnset = self.onsets(max(1, cursor - 1));
            self.displayOnsetInfo();
            self.drawSelectionRange();
        end

        function displayGlobalInfo(self)
            self.app.AverageErrorLabel.Text = sprintf('Average error: %0.2f ms', self.session.timingInfo.average / self.session.fs * 1000);
            self.app.AverageLateErrorLabel.Text = sprintf('Average late error: %0.2f ms', self.session.timingInfo.avgLate / self.session.fs * 1000);
            self.app.AverageEarlyErrorLabel.Text = sprintf('Averge early error: %0.2f ms', self.session.timingInfo.avgEarly / self.session.fs * 1000);
            self.app.NumberOfEarlyErrorsLabel.Text = sprintf('Number of early errors: %d', self.session.timingInfo.earlyNum);
            self.app.NumberOfLateErrorsLabel.Text = sprintf('Number of late errors: %d', self.session.timingInfo.lateNum);
            self.app.NumberOfCorrectOnsetsLabel.Text = sprintf('Number of correct onsets: %d', self.session.timingInfo.correctNum);
        end

        function displayOnsetInfo(self)
            self.app.TimeLabel.Text = sprintf('Time: %0.2f s', double(self.selectedOnset.loc) / double(self.session.fs));
            self.app.TimingLabel.Text = ['Timing: ', self.selectedOnset.timing];
            self.app.ErrorLabel.Text = sprintf('Error: %0.2f ms', double(self.selectedOnset.value) / double(self.session.fs) * 1000);
        end

        function drawSelectionRange(self)

            if self.selectionCircle ~= 0
                delete(self.selectionCircle)
            end

            hold(self.app.TimingPlot, 'on');
            self.selectionCircle = plot(self.app.TimingPlot, self.selectedOnset.loc, 0, 'o', 'Color', 'g', 'MarkerSize', 20);
            hold(self.app.TimingPlot, 'off');

            if self.selectionRectangle ~= 0
                delete(self.selectionRectangle)
            end

            left = self.selectedOnset.loc;
            bottom = self.app.TimingPlot.YLim(1);

            cursor = 1;

            while cursor <= length(self.onsets) && self.onsets(cursor).loc < left
                cursor = cursor + 1;
            end

            rectWidth = self.onsets(min(length(self.onsets), cursor + 1)).loc - left;

            if rectWidth == 0
                rectWidth = self.app.TimingPlot.XLim(2) - left;
            end

            height = self.app.TimingPlot.YLim(2) - bottom;

            self.selectionRectangle = rectangle(self.app.TimingPlot, 'Position', [left, bottom, rectWidth, height], 'EdgeColor', 'none', 'FaceColor', Colours.transparentBlue);
        end

    end

end
