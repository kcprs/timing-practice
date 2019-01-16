% Kacper Sagnowski, Musical Performance Analysis Systems assignment

classdef PracticeSession < handle
    % PracticeSession Stores all information of a practice session
    %   A practice session consists of a single recording of the user
    %   playing to the metronome along with all information associated
    %   with it such as metronome information, onset information and
    %   I/O information.

    properties
        app;            % Handle of the currently running app instance
        tempo;          % Tempo of the session in BPM
        duration;       % Duration of the session in seconds
        fs;             % Sampling rate at which session audio is played and recorded
        metronome;      % Handle to a Metronomoe object used in the session
        audioIn;        % Vector containing the recording of the user's playing
        audioCursor;    % Cursor for keeping track of write position
        timingInfo;     % Handle to a TimingInfo object, which holds onset information
        resultsPlot;    % Handle to a ResultsPlot object for displaying onset information
        resultsReady;   % Set to true after a session is successfully recorded and analysed
        measuringLag;   % Set to true during the process of measuring system audio latency
        lagCompAudioIn; % Vector audioIn shifted to compensate for audio lag. Not used for onset
                        % detection, only for displaying session results
    end

    methods

        function self = PracticeSession(app)
            % PracticeSession Constructor for the PracticeSession class

            self.app = app;
            self.timingInfo = TimingInfo();

            % If exist, load saved settings
            if exist('resources/audioLag.mat', 'file')
                lagStruct = load('resources/audioLag.mat');
                self.timingInfo.audioLag = lagStruct.audioLag;
                self.app.AudioLagLabel.Text = sprintf('Audio lag: %d samples', self.timingInfo.audioLag);
                self.app.AudioLagLamp.Color = Colours.green;
            end

            self.resultsReady = false;
            self.resultsPlot = ResultsPlot(self, app.TimingPlot, app.TimingPlotPreview, app.PlayheadSlider, app.PreviewPlayheadSlider);
            self.measuringLag = false;
        end

        function prepare(self, app)
            % prepare Sets up the session to be played based on user settings

            self.tempo = app.TempoField.Value;
            self.duration = app.DurationField.Value * 60;
            self.fs = str2double(app.SampleRateDropDown.Value);
            self.metronome = Metronome(self);
            self.audioIn = zeros(self.duration * self.fs + 2 * self.fs, 1);  % Pre-allocate extra 2 seconds just in case
            self.audioCursor = 1;
            self.timingInfo.prepare(self);

            % Reset lamps in the GUI
            self.app.EarlyLamp.Color = Colours.grey;
            self.app.OKLamp.Color = Colours.grey;
            self.app.LateLamp.Color = Colours.grey;
        end

        function addFrame(self, frame)
            % addFrame Adds (appends) audio frame to the session
            %   This function is called continuously while the session is running.
            %   Frames are passed into this function from an audio input driver.

            % Append frame to audioIn vector, move audioCursor and send the frame to timingInfo for analysis
            self.audioIn(self.audioCursor:self.audioCursor + length(frame) - 1) = frame;
            self.audioCursor = self.audioCursor + length(frame);
            self.timingInfo.addFrame(frame);

            % Give feedback to the user through lamps and gauge in the GUI
            if ~isempty(self.timingInfo.onsets)
                recentOnset = self.timingInfo.onsets(self.timingInfo.onsetInfoCursor - 1);

                if strcmp(recentOnset.timing, 'Early')
                    self.app.EarlyLamp.Color = Colours.red;
                    self.app.OKLamp.Color = Colours.grey;
                    self.app.LateLamp.Color = Colours.grey;
                elseif strcmp(recentOnset.timing, 'Late')
                    self.app.EarlyLamp.Color = Colours.grey;
                    self.app.OKLamp.Color = Colours.grey;
                    self.app.LateLamp.Color = Colours.red;
                else
                    self.app.EarlyLamp.Color = Colours.grey;
                    self.app.OKLamp.Color = Colours.green;
                    self.app.LateLamp.Color = Colours.grey;
                end

                % TimingGauge has green background for |value| < 0.05
                % so adjust depending on the requested timing tolerance
                self.app.TimingGauge.Value = 0.05 * double(recentOnset.value) / self.timingInfo.timingTolerance;
            end

        end

        function runPractice(self, app)
            % runPractice Starts the practice session

            % Check if audio latency of the system was measured
            if self.timingInfo.audioLag == 0 && not(self.measuringLag)
                msgbox('No previously saved information about your system latency was found. Before starting the session, please measure the audio lag of your system. You can do that from the "Settings" tab.');
                return;
            end

            % Setup player
            self.prepare(app);
            app.player = audioplayer(self.metronome.audio, str2double(app.SampleRateDropDown.Value), 16, app.OutputDeviceDropDown.Value);
            set(app.player, 'TimerPeriod', 1);
            set(app.player, 'TimerFcn', @clockDisplayCallback);
            set(app.player, 'UserData', app);

            % Setup recorder
            app.deviceReader = audioDeviceReader('SampleRate', str2double(app.SampleRateDropDown.Value), 'SamplesPerFrame', str2double(app.BufferSizeDropDown.Value), 'Device', app.InputDeviceDropDown.Value);
            setup(app.deviceReader);

            % Wait for the soundcard to set up.
            % Without this large DC offset was present at
            % the beginning of the recorded signal
            pause(2);

            % Play and record
            play(app.player);
            self.recordPractice(app);

            % Release resources
            release(app.deviceReader);

            % Clean up the session and run extended (non-realtime) analysis
            self.cleanUp();
            self.timingInfo.runExtAnalysis();

            % Plot the results
            self.resultsReady = true;
            self.resultsPlot.plotSession(self);
        end

        function stopPractice(~, app)
            % stopPractice Stops the practice session

            if app.player ~= 0
                stop(app.player);
            end

        end

        function recordPractice(self, app)
            % recordPractice Records audio for the session
            %   The recording is done in buffers to provide
            %   realtime feedback to the user. 

            % Start a timer
            tic;

            % Repeatedly poll the input device 
            while app.player.isplaying() && toc <= self.duration + 1
                % Refresh the GUI - required to keep the GUI responsive 
                % while the loop is executing
                drawnow();

                % Get the most recent frame from the input device
                [audioFrame, numOverrun] = app.deviceReader();

                % Display a warning about audio dropouts if the buffer overruns
                if numOverrun ~= 0
                    app.DropoutWarning.Visible = true;
                end

                % Save the frame while compensating for dropped samples
                self.addFrame([zeros(numOverrun, 1); audioFrame]);
            end

        end

        function measureAudioLag(self, app)
            % measureAudioLag Measures the audio lag (latency) of the system

            % Set the appropriate flag and change GUI 
            self.measuringLag = true;
            app.UIFigure.Visible = 'off';
            multiWaitbar('Measuring average audio lag...');

            % Save current session settings so that they can be restored later
            setTempo = app.TempoField.Value;
            setDuration = app.DurationField.Value;
            setSensitivity = app.DetectionSensitivityKnob.Value;

            % Set values appropriate for lag measurement
            app.TempoField.Value = 120;
            app.DurationField.Value = 1/60;
            app.DetectionSensitivityKnob.Value = 0.75;
            self.timingInfo.audioLag = 0;

            % Run five sessions and take an average of measured onset delays
            numIter = 5;
            lagSum = 0;

            for iter = 1:numIter
                self.runPractice(app);
                lagSum = lagSum + self.timingInfo.average;
                multiWaitbar('Measuring average audio lag...', iter / numIter);
                pause(1);
            end

            % Save audioLag value
            audioLag = round(lagSum / numIter);
            self.timingInfo.audioLag = audioLag;
            save('resources/audioLag.mat', 'audioLag');

            % Restore settings from before and update the GUI
            app.TempoField.Value = setTempo;
            app.DurationField.Value = setDuration;
            app.DetectionSensitivityKnob.Value = setSensitivity;

            app.EarlyLamp.Color = Colours.grey;
            app.OKLamp.Color = Colours.grey;
            app.LateLamp.Color = Colours.grey;
            app.TimingGauge.Value = 0;

            app.UIFigure.Visible = 'on';
            cla(app.TimingPlot);
            multiWaitbar('Measuring average audio lag...', 'Close');
            self.app.AudioLagLabel.Text = sprintf('Audio lag: %d samples', self.timingInfo.audioLag);
            self.app.AudioLagLamp.Color = Colours.green;

            % Reset the flag
            self.measuringLag = false;
        end

        function cleanUp(self)
            % cleanUp Cleans up the session's internal state after it was run

            % Trim unused zeros if too much space was pre-allocated
            if self.audioCursor < length(self.audioIn)
                self.audioIn = self.audioIn(1:self.audioCursor);
            end

            % Clean up the timingInfo object
            self.timingInfo.cleanUp();

            % Shift audioIn to compensate for audio lag and the offset in the novelty function of the detection algorithm.
            % The factor of 0.6563 was found by trial and error.
            self.lagCompAudioIn = self.audioIn(round(self.timingInfo.fftSize * 0.6563) + self.timingInfo.audioLag + 1:end);
        end

        function playFromCursor(self, app)
            % playFromCursor Plays contents of the lagCompAudioIn from a given position

            if ~self.resultsReady
                return;
            end

            % Disable playback control sliders when playing.
            % They do not work in real-time.
            app.RecordingVolumeSlider.Enable = false;
            app.MetronomeVolumeSlider.Enable = false;
            app.PlaybackRateSlider.Enable = false;

            % Align metronome audio with lagCompAudioIn
            if length(self.metronome.audio) > length(self.lagCompAudioIn)
                alignedMetro = self.metronome.audio(1:length(self.lagCompAudioIn));
            end

            if length(self.metronome.audio) < length(self.lagCompAudioIn)
                alignedMetro = [self.metronome.audio; zeros(length(self.lagCompAudioIn) - length(self.metronome.audio), 1)];
            end

            % Find the start and end index of audio to be played
            startIndex = max(1, int64(self.resultsPlot.playheadLoc));

            if app.StopAfterOneOnsetCheckBox.Value && not(isempty(self.timingInfo.onsets))
                % If the user wants to stop playback after playing one onset, find the following onset.
                cursor = 1;

                while cursor <= length(self.timingInfo.onsets) && self.timingInfo.onsets(cursor).loc < self.resultsPlot.playheadLoc
                    cursor = cursor + 1;
                end

                stopIndex = self.timingInfo.onsets(cursor + 1).loc;

                toPlay = app.RecordingVolumeSlider.Value^2 * self.lagCompAudioIn(startIndex:stopIndex) + app.MetronomeVolumeSlider.Value^2 * alignedMetro(startIndex:stopIndex);
            else
                % Otherwise play to the end of lagComAudioIn
                toPlay = app.RecordingVolumeSlider.Value^2 * self.lagCompAudioIn(startIndex:end) + app.MetronomeVolumeSlider.Value^2 * alignedMetro(startIndex:end);
            end

            % Set up the player and play
            if ~isempty(toPlay)
                rate = 2^(app.PlaybackRateSlider.Value);
                app.player = audioplayer(toPlay, str2double(app.SampleRateDropDown.Value) * rate, 16, app.OutputDeviceDropDown.Value);
                set(app.player, 'StopFcn', @reactivatePlaybackSlidersCallback);
                set(app.player, 'UserData', app);
                set(app.player, 'TimerPeriod', 1/8);
                set(app.player, 'TimerFcn', @movePlayheadCallback)
                play(app.player);
            end

        end

        function stopPlayingFromCursor(~, app)
            % stopPlayingFromCursor Stops playback in the Results tab

            if app.player ~= 0
                stop(app.player);
            end

            % Re-enable playback controls
            app.RecordingVolumeSlider.Enable = true;
            app.MetronomeVolumeSlider.Enable = true;
            app.PlaybackRateSlider.Enable = true;

        end

        function saveSessionSettings(~, app)
            % saveSessionSettings Saves current session settings to a file 

            sensitivity = app.DetectionSensitivityKnob.Value;
            sessionTempo = app.TempoField.Value;
            sessionDuration = app.DurationField.Value;
            tolerance = app.PermissibleErrorField.Value;
            save('resources/sessionSettings.mat', 'sensitivity', 'sessionTempo', 'sessionDuration', 'tolerance');
        end

    end

end
