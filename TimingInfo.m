classdef TimingInfo < handle

    properties
        onsetLocs;
        tickLocs;
        errors;
        average;
        avgEarly;
        avgLate;
    end

    methods

        function self = TimingInfo(audioIn, metronome, lagCompensation)
            minTickDistance = metronome.getTickDistance() / 2;
            self.onsetLocs = TimingInfo.detectOnsets(audioIn, minTickDistance);
            self.tickLocs = metronome.getTickLocs();

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

            if lagCompensation == -1
                averageLag = round(self.average);
                metronome.ticks = circshift(metronome.ticks, averageLag);
            else
                metronome.ticks = circshift(metronome.ticks, lagCompensation);
            end

            self.tickLocs = metronome.getTickLocs();

        end

    end

    methods (Static, Access = private)

        function onsetLocs = detectOnsets(audioIn, minPeakDist)
            fftSize = 128; % Keep this low to maintain high accuracy
            hopSize = 128;

            cursor = 1;
            novelty = zeros(length(audioIn), 1);
            previousFrameFFT = fft(audioIn(1:fftSize) .* hann(fftSize));

            wb = waitbar(0, 'Detecting onsets...');

            while cursor + fftSize < length(audioIn)
                waitbar(cursor / length(audioIn) - 0.2, wb);
                frameFFT = fft(audioIn(cursor:cursor + fftSize - 1) .* hann(fftSize));
                fftDifference = abs(frameFFT(1:fftSize / 2 - 1)) - abs(previousFrameFFT(1:fftSize / 2 - 1));

                novelty(cursor:cursor + hopSize - 1) = sum(fftDifference); % Keeping the sign of the difference helps differentiate between note on and note off
                previousFrameFFT = frameFFT;
                cursor = cursor + hopSize;
            end

            waitbar(0.9, wb);

            maxVal = max(novelty);
            novelty = novelty / maxVal;
            [~, onsetLocs] = findpeaks(novelty, 'MinPeakProminence', 0.5, 'MinPeakDistance', minPeakDist);

            close(wb);

            % plot(audioIn);
            % hold;
            % plot(novelty);
            % plot(onsetLocs, onsetPeaks, 'x');
            % hold;
        end

    end

end
