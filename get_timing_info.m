function timing_info = get_timing_info(onset_locs, tick_locs)
    timing_errors(length(onset_locs)) = struct('onset', [], 'prev_tick', [], 'next_tick', [], 'closest_tick', [], 'value', [], 'early', []);

    tick_cursor = 1;
    wb = waitbar(0, 'Analysing timing...');

    for iter = 1:length(onset_locs)
        onset = onset_locs(iter);
        timing_error.onset = onset;

        while tick_cursor <= length(tick_locs) && tick_locs(tick_cursor) < onset
            prev_tick = tick_locs(tick_cursor);
            tick_cursor = tick_cursor + 1;
        end

        timing_error.prev_tick = prev_tick;

        if tick_cursor <= length(tick_locs)
            next_tick = tick_locs(tick_cursor);
        else
            next_tick = 0;
        end

        timing_error.next_tick = next_tick;

        if onset - prev_tick < next_tick - onset || next_tick == 0
            closest_tick = prev_tick;
            timing_error.early = false;
        else
            closest_tick = next_tick;
            timing_error.early = true;
        end

        timing_error.closest_tick = closest_tick;

        timing_error.value = onset - closest_tick;

        timing_errors(iter) = timing_error;
        waitbar(iter / length(onset_locs), wb);
    end

    early = 0;
    early_num = 0;
    late = 0;
    late_num = 0;
    sum_all = 0;

    for iter = 1:length(onset_locs)
        timing_error = timing_errors(iter);
        sum_all = sum_all + timing_error.value;

        if timing_error.early
            early = early + timing_error.value;
            early_num = early_num + 1;
        else
            late = late + timing_error.value;
            late_num = late_num + 1;
        end
    end

    timing_info.errors = timing_errors;
    timing_info.average = sum_all / length(timing_errors);
    timing_info.avg_early = early / early_num;
    timing_info.avg_late = late / late_num;
    close(wb);
    disp('Average:');
    disp(timing_info.average);
    disp('Average early:');
    disp(timing_info.avg_early);
    disp('Average late:');
    disp(timing_info.avg_late);
end
