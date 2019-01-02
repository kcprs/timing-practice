function movePlayheadTo(direction, loc_type, app)
    if strcmp(loc_type, 'onset')
        locs = app.session.timingInfo.onsetLocs;
    elseif strcmp(loc_type, 'tick')
        locs = app.session.timingInfo.tickLocs;
    else
        error('Unknown loc type');
    end

    if strcmp(direction, 'next')
        dir_factor = 1;
        cursor = 1;
    elseif strcmp(direction, 'previous')
        dir_factor = -1;
        cursor = length(locs);
    else
        error('Unknown direction')
    end

    while cursor + dir_factor <= length(locs) && cursor + dir_factor >= 1 && locs(cursor) * dir_factor <= app.playheadLoc * dir_factor
        cursor = cursor + dir_factor;
    end

    movePlayhead(app, locs(cursor));
end
