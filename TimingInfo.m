classdef TimingInfo < handle
    % TimingInfo Holds information about all timing information in a practice session, e.g. onsets or latency

    properties
        fftSize;                % FFT size used for onset detection
        hopSize;                % Hop size used for onset detection
        audioLag;               % Latency of the system
        detBuf;                 % Detection buffer. Object of class CircularBuffer.
        detBufSize;             % Size of the detection buffer
        detBufLoc;              % Current location (in samples) of the detection buffer in the session's audio
        maxNoveltyValue;        % Maximum novelty function value
        onsetLocs;              % Vector containing all onset locations (in samples)
        onsetCursor;            % Cursor for iterating through the onsetLocs vector
        tickLocs;               % Vector containing all metronome tick locations (in samples)
        tickCursor;             % Cursor for iterating through the tickLocs vector
        onsets;                 % Array of OnsetInfo objects detected
        onsetInfoCursor;        % Cursor for iterating through the onsets array
        minOnsetDist;           % Minimum allowed onset distance
        average;                % Average onset error (in samples)
        avgEarly;               % Average error of onsets played too early (in samples)
        avgLate;                % Average error of onsets played too late (in samples)
        timingTolerance;        % Maximum allowed onset earliness/delay (in samples)
        allNum;                 % Number of all onsets detected
        earlyNum;               % Number of onsets played too early
        lateNum;                % Number of onsets played too late
        correctNum;             % Number of onsets played within timingTolerance
        correctOnsetLocs;       % Locations of onsets played correctly (in samples)
        incorrectOnsetLocs;     % Locations of onsets played incorrectly (in samples)
        detectionSensitivity;   % Sensitivity of the detection algorithm. Range: 0.1-0.9
    end

    methods

        function self = TimingInfo()
            % TimingInfo Constructor for the TimingInfo class

            % Values optimised by trial and error
            self.fftSize = 2048;
            self.hopSize = 128;
            self.audioLag = 0;
        end

        function prepare(self, session)
            % prepare Sets up the object before the practice session runs
            
            self.detBufLoc = 1;
            self.detBufSize = session.metronome.getTickDistance();
            self.detBuf = CircularBuffer(self.detBufSize);
            self.maxNoveltyValue = 0;
            % Predicted num of onsets based on BPM + allow 1 additional onset per second of duration, in case of false positives
            numOnsets = ceil(session.duration / 60 * session.tempo + session.duration);
            self.onsetLocs = zeros(numOnsets, 1);
            self.onsetCursor = 1;
            self.tickCursor = 0;
            self.tickLocs = session.metronome.getTickLocs();
            self.onsets = OnsetInfo.empty(0, numOnsets);
            self.onsetInfoCursor = 1;
            self.minOnsetDist = self.detBufSize / 2;
            self.timingTolerance = session.app.PermissibleErrorField.Value * session.fs / 1000;
            self.detectionSensitivity = session.app.DetectionSensitivityKnob.Value;
        end

        function addFrame(self, frame)
            % addFrame Adds a new frame to the detection buffer

            % Add frame to the buffer. If buffer is filled, analyse it and move cursor
            if self.detBuf.add(frame)
                self.analyseBuffer();
                self.detBufLoc = self.detBufLoc + self.detBufSize;
            end

        end

        function analyseRemaining(self)
            % analyseRemaining Analyse samples remaining in the buffer
            %   This function is called after a session stops.
            %   Since detection buffer is only analysed when it's full,
            %   there might be some samples leftover after a session stops.

            % Add new samples to the buffer to force analysis
            self.detBuf.add(zeros(self.detBufSize, 1));
            self.analyseBuffer();
        end

        function cleanUp(self)
            % cleanUp Cleans up the object's internal state after the session stops

            self.analyseRemaining();

            % If any onsets have negative location due to audio latency,
            % remove them. Also remove any unused pre-allocated
            % OnsetInfo objects in self.onsets and zeros in self.onsetLocs
            cursor = 1;
            gonePositive = false;
            startCursor = 1;

            while cursor <= length(self.onsetLocs)

                if self.onsetLocs(cursor) > 0 && not(gonePositive)
                    % startCursor points to the first onset with a positive location
                    startCursor = cursor;
                    gonePositive = true;
                end

                cursor = cursor + 1;

                if cursor <= length(self.onsetLocs) && gonePositive && self.onsetLocs(cursor) == 0
                    % Break if cursor has already gone into positive values and later encountered
                    % onset location equal to zero (which is what all locations were initialised to).
                    break;
                end

            end

            % Trim onsetLocs and onset arrays
            self.onsetLocs = self.onsetLocs(startCursor:cursor - 1);

            if ~isempty(self.onsets)
                self.onsets = self.onsets(startCursor:cursor - 1);
            end

        end

        function runExtAnalysis(self)
            % runExtAnalysis Runs additional extended onset analysis after the session stops

            % Initialise
            self.earlyNum = 0;
            self.lateNum = 0;
            self.average = 0;
            self.avgEarly = 0;
            self.avgLate = 0;
            self.correctNum = 0;

            if isempty(self.onsets)
                return;
            end
            
            % Pre-allocate arrays with maximum possible lengths
            self.correctOnsetLocs = zeros(0, length(self.onsets));
            self.incorrectOnsetLocs = zeros(0, length(self.onsets));

            % Sum total error of early, late and all onsets
            % Also sort onsets by correct/incorrect timing
            early = 0;
            late = 0;
            sumAll = 0;
            correctCursor = 1;
            incorrectCursor = 1;

            for iter = 1:length(self.onsetLocs)
                onsetInfo = self.onsets(iter);
                sumAll = sumAll + onsetInfo.value;

                if strcmp(onsetInfo.timing, 'Early')
                    early = early + onsetInfo.value;
                    self.earlyNum = self.earlyNum + 1;
                    self.incorrectOnsetLocs(incorrectCursor) = onsetInfo.loc;
                    incorrectCursor = incorrectCursor + 1;
                elseif strcmp(onsetInfo.timing, 'Late')
                    late = late + onsetInfo.value;
                    self.lateNum = self.lateNum + 1;
                    self.incorrectOnsetLocs(incorrectCursor) = onsetInfo.loc;
                    incorrectCursor = incorrectCursor + 1;
                else
                    self.correctOnsetLocs(correctCursor) = onsetInfo.loc;
                    correctCursor = correctCursor + 1;
                end

            end

            % Trim unused pre-allocated cells from arrays
            self.correctOnsetLocs = self.correctOnsetLocs(1:correctCursor - 1);
            self.incorrectOnsetLocs = self.incorrectOnsetLocs(1:incorrectCursor - 1);

            % Save global timing info
            self.allNum = length(self.onsets);
            self.correctNum = self.allNum - self.earlyNum - self.lateNum;

            if self.allNum ~= 0
                self.average = sumAll / self.allNum;
            end

            if self.earlyNum ~= 0
                self.avgEarly = early / self.earlyNum;
            end

            if self.lateNum ~= 0
                self.avgLate = late / self.lateNum;
            end

        end

    end

    methods (Access = private)

        function novelty = getNovelty(self, currentFrame, previousFrame)
            % getNovelty Calculates novelty function
            %   Novelty is calculated as the sum over FFT bins of bin magnitude differences between current and previous FFT

            % FFT of the current frame, windowed
            frameFFT = fft(currentFrame .* hann(self.fftSize));

            % FFT of the previous frame, windowed
            previousFrameFFT = fft(previousFrame .* hann(self.fftSize));

            % Difference between FFT bin magnitudes (up to half FFT size, due to FFT symmetry around its mid-point)
            fftDifference = abs(frameFFT(1:self.fftSize / 2 - 1)) - abs(previousFrameFFT(1:self.fftSize / 2 - 1));

            % Novelty is the sum over FFT bins of bin magnitude differences
            novelty = sum(fftDifference);
        end

        function newOnsetLocs = detectOnsets(self)
            % detectOnsets Detects onsets in the contents of the detection buffer

            % This function gets called after the buffer is filled, so the data
            % used for onset detection is in the buffer's previousData property.

            % Initialise
            cursor = 1;
            bufNovelty = zeros(self.detBufSize, 1);  % Novelty vector for the detection buffer

            % Get previous frame from the end of buffer's prepreviousData vector
            previousFrame = self.detBuf.prepreviousData(end - self.fftSize + 1:end);

            % Calculate novelty by iterating over detection buffer in increments of hopSize
            while cursor + self.fftSize <= self.detBufSize
                frame = self.detBuf.previousData(cursor:cursor + self.fftSize - 1);
                bufNovelty(cursor:cursor + self.hopSize - 1) = bufNovelty(cursor:cursor + self.hopSize - 1) + self.getNovelty(frame, previousFrame);
                previousFrame = frame;
                cursor = cursor + self.hopSize;
            end

            % Since detection buffer's size isn't necessarily an integer multiple
            % of fftSize, there may be some samples leftover. Analyse them too.
            numRemaining = self.detBufSize - cursor;
            padLen = self.fftSize - numRemaining - 1;
            frame = [self.detBuf.previousData(cursor:end); zeros(padLen, 1)];
            bufNovelty(cursor:end) = bufNovelty(cursor:end) + self.getNovelty(frame, previousFrame);

            % Find maximum novelty value and save it if it's the largest so far.
            maxBufVal = max(bufNovelty);
            self.maxNoveltyValue = max(maxBufVal, self.maxNoveltyValue);

            % Normalise novelty to stay within the range 0-1 over the entire session.
            % This will help avoid false positives.
            if self.maxNoveltyValue ~= 0
                bufNovelty = bufNovelty / self.maxNoveltyValue;
            end

            % Find peaks in the novelty function
            [~, newOnsetLocs] = findpeaks(bufNovelty, 'MinPeakProminence', 1 - self.detectionSensitivity, 'MinPeakDistance', self.minOnsetDist);

            % Save newly detected onsets locations into the onsetLocs vector.
            numOnsets = length(newOnsetLocs);

            if numOnsets > 0
                newOnsetLocs = int64(newOnsetLocs) + int64(self.detBufLoc) - 1 - int64(self.audioLag); % Compensate for audio lag
                self.onsetLocs(self.onsetCursor:self.onsetCursor + numOnsets - 1) = newOnsetLocs;
                self.onsetCursor = self.onsetCursor + numOnsets;
            end

        end

        function analyseOnsets(self, newOnsetLocs)
            % analyseOnsets Creates OnsetInfo objects based on given onset locations

            % Initialise
            % tickCursor - cursor for searching through indexes of metronome tick locations
            % tick - dummy variable for searching through metronome tick locations
            if self.tickCursor < 1
                tick = 0;
                self.tickCursor = 0;
            else
                tick = self.tickLocs(self.tickCursor);
            end

            % Cursor for moving through the array of new onset locations
            newOnsetCursor = 1;

            % Search though all metronome ticks within the detection buffer + one before it
            % Assign a preceding and following metronome tick to each new onset
            while tick < self.detBufLoc + self.detBufSize

                % If there exists no following metronome tick, set nextTick to 0
                if self.tickCursor + 1 <= length(self.tickLocs)
                    nextTick = self.tickLocs(self.tickCursor + 1);
                else
                    nextTick = 0;
                end

                % Go through all onsets between this tick ('tick' variable) and the next one ('nextTick' variable)
                % and create an OnsetInfo object for each of them.
                while newOnsetCursor <= length(newOnsetLocs) && (newOnsetLocs(newOnsetCursor) <= nextTick || nextTick == 0)
                    onset = newOnsetLocs(newOnsetCursor);
                    self.onsets(self.onsetInfoCursor) = OnsetInfo(onset, tick, nextTick, self.timingTolerance);
                    newOnsetCursor = newOnsetCursor + 1;
                    self.onsetInfoCursor = self.onsetInfoCursor + 1;
                end

                if nextTick == 0
                    break;
                end

                % Go to next tick
                self.tickCursor = self.tickCursor + 1;
                tick = self.tickLocs(self.tickCursor);
            end

            % Move the cursor to the previous metronome tick so that the search
            % start with a tick preceding the currently analysed detection buffer
            self.tickCursor = self.tickCursor - 1;
        end

        function analyseBuffer(self)
            % analyseBuffer Analyses the detection buffer to find onsets

            newOnsetLocs = self.detectOnsets();
            self.analyseOnsets(newOnsetLocs);
        end

    end

end
