classdef TimingInfo < handle

    properties
        fftSize;
        hopSize;
        audioLag;
        detBufLoc;
        detBufSize;
        detBuf;
        novelty;
        maxNoveltyValue;
        onsetLocs;
        onsetCursor;
        tickCursor;
        tickLocs;
        onsets;
        onsetInfoCursor;
        minOnsetDist;
        average;
        avgEarly;
        avgLate;
        timingTolerance;
        earlyNum;
        lateNum;
        allNum;
        correctNum;
        correctOnsetLocs;
        incorrectOnsetLocs;
        detectionSensitivity;
    end

    methods

        function self = TimingInfo()
            self.fftSize = 128; % Keep this low to maintain high accuracy
            self.hopSize = 128;
            self.audioLag = 0;
        end

        function prepare(self, session)
            self.detBufLoc = 1;
            self.detBufSize = session.metronome.getTickDistance();
            self.detBuf = CircularBuffer(self.detBufSize);
            self.novelty = zeros(length(session.audioIn), 1);
            self.maxNoveltyValue = 0;
            numOnsets = ceil(session.duration / 60 * session.tempo + session.duration); % Predicted num of onsets
            self.onsetLocs = zeros(numOnsets, 1);
            self.onsetCursor = 1;
            self.tickCursor = 0;
            self.tickLocs = session.metronome.getTickLocs();
            self.onsets = OnsetInfo.empty(0, numOnsets);
            self.onsetInfoCursor = 1;
            self.minOnsetDist = self.detBufSize / 2;
            self.timingTolerance = session.fs / 100;
            self.detectionSensitivity = session.app.DetectionSensitivityKnob.Value;
        end

        function addFrame(self, frame)

            if self.detBuf.add(frame)
                self.analyseBuffer();
                self.detBufLoc = self.detBufLoc + self.detBufSize;
            end

        end

        function analyseRemaining(self)
            self.detBuf.add(zeros(self.detBufSize, 1));
            self.analyseBuffer();
        end

        function cleanUp(self)
            cursor = 1;
            gonePositive = false;
            startCursor = 1;

            while cursor <= length(self.onsetLocs)

                if self.onsetLocs(cursor) > 0 && not(gonePositive)
                    startCursor = cursor;
                    gonePositive = true;
                end

                cursor = cursor + 1;

                if gonePositive && self.onsetLocs(cursor) == 0
                    break;
                end

            end

            self.onsetLocs = self.onsetLocs(startCursor:cursor - 1);
            self.onsets = self.onsets(startCursor:cursor - 1);
        end

        function runExtAnalysis(self)
            early = 0;
            self.earlyNum = 0;
            late = 0;
            self.lateNum = 0;
            sumAll = 0;
            self.correctOnsetLocs = zeros(0, length(self.onsets));
            correctCursor = 1;
            self.incorrectOnsetLocs = zeros(0, length(self.onsets));
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

            self.correctOnsetLocs = self.correctOnsetLocs(1:correctCursor - 1);
            self.incorrectOnsetLocs = self.incorrectOnsetLocs(1:incorrectCursor - 1);
            self.allNum = length(self.onsets);
            self.correctNum = self.allNum - self.earlyNum - self.lateNum;

            if self.allNum ~= 0
                self.average = sumAll / self.allNum;
            else
                self.average = 0;
            end

            if self.earlyNum ~= 0
                self.avgEarly = early / self.earlyNum;
            else
                self.avgEarly = 0;
            end

            if self.avgLate ~= 0
                self.avgLate = late / self.lateNum;
            else
                self.avgLate = 0;
            end

        end

    end

    methods (Access = private)

        function newOnsetLocs = detectOnsets(self)
            cursor = 1;
            bufNovelty = zeros(self.detBufSize, 1); % TODO: Store one value per FFT frame
            previousFrameFFT = fft(self.detBuf.prepreviousData(end - self.fftSize + 1:end) .* hann(self.fftSize));

            while cursor + self.fftSize <= self.detBufSize

                frameFFT = fft(self.detBuf.previousData(cursor:cursor + self.fftSize - 1) .* hann(self.fftSize));
                fftDifference = abs(frameFFT(1:self.fftSize / 2 - 1)) - abs(previousFrameFFT(1:self.fftSize / 2 - 1));

                bufNovelty(cursor:cursor + self.hopSize - 1) = sum(fftDifference); % Keeping the sign of the difference helps differentiate between note on and note off

                previousFrameFFT = frameFFT;
                cursor = cursor + self.hopSize;
            end

            numRemaining = self.detBufSize - cursor;
            padLen = self.fftSize - numRemaining - 1;
            frameFFT = fft(([self.detBuf.previousData(cursor:end); zeros(padLen, 1)]) .* hann(self.fftSize));
            fftDifference = abs(frameFFT(1:self.fftSize / 2 - 1)) - abs(previousFrameFFT(1:self.fftSize / 2 - 1));
            bufNovelty(cursor:end) = sum(fftDifference);

            maxBufVal = max(bufNovelty);
            self.maxNoveltyValue = max(maxBufVal, self.maxNoveltyValue);
            bufNovelty = bufNovelty / self.maxNoveltyValue;
            self.novelty(self.detBufLoc:self.detBufLoc + self.detBufSize - 1) = bufNovelty;
            [~, newOnsetLocs] = findpeaks(bufNovelty, 'MinPeakProminence', 1 - self.detectionSensitivity, 'MinPeakDistance', self.minOnsetDist);

            numOnsets = length(newOnsetLocs);

            if numOnsets > 0
                newOnsetLocs = int64(newOnsetLocs) + int64(self.detBufLoc) - 1 - int64(self.audioLag);
                self.onsetLocs(self.onsetCursor:self.onsetCursor + numOnsets - 1) = newOnsetLocs;
                self.onsetCursor = self.onsetCursor + numOnsets;
            end

        end

        function analyseErrors(self, newOnsetLocs)

            if self.tickCursor < 1
                tick = 0;
                self.tickCursor = 0;
            else
                tick = self.tickLocs(self.tickCursor);
            end

            newOnsetCursor = 1;

            while tick < self.detBufLoc + self.detBufSize

                if self.tickCursor + 1 <= length(self.tickLocs)
                    nextTick = self.tickLocs(self.tickCursor + 1);
                else
                    nextTick = 0;
                end

                while newOnsetCursor <= length(newOnsetLocs) && (newOnsetLocs(newOnsetCursor) <= nextTick || nextTick == 0)
                    onset = newOnsetLocs(newOnsetCursor);
                    self.onsets(self.onsetInfoCursor) = OnsetInfo(onset, tick, nextTick, self.timingTolerance);
                    newOnsetCursor = newOnsetCursor + 1;
                    self.onsetInfoCursor = self.onsetInfoCursor + 1;
                end

                if nextTick == 0
                    break;
                end

                self.tickCursor = self.tickCursor + 1;
                tick = self.tickLocs(self.tickCursor);
            end

            self.tickCursor = self.tickCursor - 1;
        end

        function analyseBuffer(self)
            newOnsetLocs = self.detectOnsets();
            self.analyseErrors(newOnsetLocs);
        end

    end

end
