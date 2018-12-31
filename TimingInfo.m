classdef TimingInfo < handle

    properties
        onsetLocs;

        tickLocs;
        errors;
        average;
        avgEarly;
        avgLate;
        detBufSize;
        detBuf;
        detBufLoc;
        onsetCursor;
        fftSize;
        hopSize;
        minOnsetDist;
        audioLag;
    end

    methods

        function self = TimingInfo()
            self.fftSize = 128; % Keep this low to maintain high accuracy
            self.hopSize = 128;
            self.audioLag = 0;
        end

        function prepare(self, duration, metronome)
            numOnsets = duration / 60 * metronome.tempo + duration; % Predicted num of onsets
            self.onsetLocs = zeros(numOnsets, 1);
            self.errors = TimingError.empty(0, numOnsets);
            self.tickLocs = metronome.getTickLocs();
            self.onsetCursor = 1;
            self.detBufLoc = 1;
            self.detBufSize = metronome.getTickDistance();
            self.minOnsetDist = self.detBufSize / 2;
            self.detBuf = CircularBuffer(self.detBufSize);
        end

        function addFrame(self, frame, position)

            if self.detBuf.add(frame)
                self.analyseBuffer();
                self.detBufLoc = position;
            end

        end

        function cleanUpOnsets(self)
            cursor = 1;

            while cursor <= length(self.onsetLocs) && self.onsetLocs(cursor) ~= 0
                cursor = cursor + 1;
            end

            self.onsetLocs = self.onsetLocs(1:cursor - 1);
        end

        function runExtAnalysis(self)
            self.errors = TimingError.empty(0, length(self.onsetLocs));

            tickCursor = 1;
            prevTick = 0;
            wb = waitbar(0, 'Analysing timing...');

            for iter = 1:length(self.onsetLocs)
                onset = self.onsetLocs(iter);

                while tickCursor <= length(self.tickLocs) && self.tickLocs(tickCursor) < onset
                    prevTick = self.tickLocs(tickCursor);
                    tickCursor = tickCursor + 1;
                end

                if tickCursor <= length(self.tickLocs)
                    nextTick = self.tickLocs(tickCursor);
                else
                    nextTick = 0;
                end

                self.errors(iter) = TimingError(onset, prevTick, nextTick);
                waitbar(iter / length(self.onsetLocs), wb);
            end

            early = 0;
            earlyNum = 0;
            late = 0;
            lateNum = 0;
            sumAll = 0;

            for iter = 1:length(self.onsetLocs)
                timingError = self.errors(iter);
                sumAll = sumAll + timingError.value;

                if timingError.isEarly
                    early = early + timingError.value;
                    earlyNum = earlyNum + 1;
                else
                    late = late + timingError.value;
                    lateNum = lateNum + 1;
                end

            end

            self.average = sumAll / length(self.errors);
            self.avgEarly = early / earlyNum;
            self.avgLate = late / lateNum;
            close(wb);
        end

    end

    methods (Access = private)

        function analyseBuffer(self)
            cursor = 1;
            novelty = zeros(self.detBufSize, 1); % TODO: Store one value per FFT frame
            previousFrameFFT = fft(self.detBuf.prepreviousData(end - self.fftSize + 1:end) .* hann(self.fftSize));

            while cursor + self.fftSize <= self.detBufSize
                frameFFT = fft(self.detBuf.previousData(cursor:cursor + self.fftSize - 1) .* hann(self.fftSize));
                fftDifference = abs(frameFFT(1:self.fftSize / 2 - 1)) - abs(previousFrameFFT(1:self.fftSize / 2 - 1));

                novelty(cursor:cursor + self.hopSize - 1) = sum(fftDifference); % Keeping the sign of the difference helps differentiate between note on and note off
                previousFrameFFT = frameFFT;
                cursor = cursor + self.hopSize;
            end

            numRemaining = self.detBufSize - cursor;
            padLen = self.fftSize - numRemaining;
            frameFFT = fft([self.detBuf.previousData(cursor:end); zeros(padLen, 1)]);
            fftDifference = abs(frameFFT(1:self.fftSize / 2 - 1)) - abs(previousFrameFFT(1:self.fftSize / 2 - 1));
            novelty(cursor:end) = sum(fftDifference);

            maxVal = max(novelty);
            novelty = novelty / maxVal;
            [~, newOnsetLocs] = findpeaks(novelty, 'MinPeakProminence', 0.5, 'MinPeakDistance', self.minOnsetDist);

            numOnsets = length(newOnsetLocs);
            newOnsetLocs = newOnsetLocs + self.detBufLoc - self.audioLag;
            self.onsetLocs(self.onsetCursor:self.onsetCursor + numOnsets - 1) = newOnsetLocs;
            self.onsetCursor = self.onsetCursor + numOnsets;
        end

    end

end
