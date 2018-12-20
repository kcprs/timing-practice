function tickDist = getTickDistance(tempo, fs)
    tickDist = idivide(60 * fs, int32(tempo), 'round');
end