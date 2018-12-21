function movePlayhead(app, samplePos)
    app.vars.playheadPos = samplePos;
    playheadPosTime = samplePos / app.session.fs;
    app.PlayheadSlider.Value = samplePos / length(app.session.audioIn);

    if app.vars.playhead ~= 0
        delete(app.vars.playhead);
    end

    hold(app.TimingPlot, 'on');
    app.vars.playhead = plot(app.TimingPlot, [playheadPosTime, playheadPosTime], app.TimingPlot.YLim, 'Color', 'r');
    hold(app.TimingPlot, 'off');
end