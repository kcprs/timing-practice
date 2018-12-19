function tick_locs = get_tick_locs(tick_array)
    [~, tick_locs] = findpeaks(tick_array);
end