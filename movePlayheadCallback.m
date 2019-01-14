function movePlayheadCallback(player, ~)
    % movePlayheadCallback Updates playhead position on the "Results" tab of the app.
    %   This function is called every 1/8 second by the timer of MATLAB's audioplayer object.
    
    playheadLoc = player.UserData.session.resultsPlot.playheadLoc;
    increment = player.SampleRate / 8;
    player.UserData.session.resultsPlot.movePlayhead(playheadLoc + increment);
end
