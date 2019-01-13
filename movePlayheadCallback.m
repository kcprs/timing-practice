function movePlayheadCallback(player, ~)
    playheadLoc = player.UserData.session.resultsPlot.playheadLoc;
    increment = player.SampleRate / 8;
    player.UserData.session.resultsPlot.movePlayhead(playheadLoc + increment);
end
