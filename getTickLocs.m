function tickLocs = getTickLocs(tickArray)
    [~, tickLocs] = findpeaks(tickArray);
end