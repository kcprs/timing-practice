function timingInfo = getTimingInfo(onsetLocs, tickLocs)
    timingErrors(length(onsetLocs)) = struct('onset', [], 'prevTick', [], 'nextTick', [], 'closestTick', [], 'value', [], 'early', []);

    tickCursor = 1;
    wb = waitbar(0, 'Analysing timing...');

    for iter = 1:length(onsetLocs)
        onset = onsetLocs(iter);
        timingError.onset = onset;

        while tickCursor <= length(tickLocs) && tickLocs(tickCursor) < onset
            prevTick = tickLocs(tickCursor);
            tickCursor = tickCursor + 1;
        end

        timingError.prevTick = prevTick;

        if tickCursor <= length(tickLocs)
            nextTick = tickLocs(tickCursor);
        else
            nextTick = 0;
        end

        timingError.nextTick = nextTick;

        if onset - prevTick < nextTick - onset || nextTick == 0
            closestTick = prevTick;
            timingError.early = false;
        else
            closestTick = nextTick;
            timingError.early = true;
        end

        timingError.closestTick = closestTick;

        timingError.value = onset - closestTick;

        timingErrors(iter) = timingError;
        waitbar(iter / length(onsetLocs), wb);
    end

    early = 0;
    earlyNum = 0;
    late = 0;
    lateNum = 0;
    sumAll = 0;

    for iter = 1:length(onsetLocs)
        timingError = timingErrors(iter);
        sumAll = sumAll + timingError.value;

        if timingError.early
            early = early + timingError.value;
            earlyNum = earlyNum + 1;
        else
            late = late + timingError.value;
            lateNum = lateNum + 1;
        end
    end

    timingInfo.errors = timingErrors;
    timingInfo.average = sumAll / length(timingErrors);
    timingInfo.avgEarly = early / earlyNum;
    timingInfo.avgLate = late / lateNum;
    close(wb);
    disp('Average:');
    disp(timingInfo.average);
    disp('Average early:');
    disp(timingInfo.avgEarly);
    disp('Average late:');
    disp(timingInfo.avgLate);
end
