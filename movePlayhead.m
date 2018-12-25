function movePlayhead(app, samplePos)
    app.playheadLoc = samplePos;
    playheadPosTime = samplePos / app.session.fs;
    app.PlayheadSlider.Value = samplePos / (app.session.fs * app.TimingPlot.XLim(2));

    if app.playheadPlot ~= 0
        delete(app.vars.playhead);
    end

    hold(app.TimingPlot, 'on');
    app.playheadPlot = plot(app.TimingPlot, [playheadPosTime, playheadPosTime], app.TimingPlot.YLim, 'Color', 'r');
    hold(app.TimingPlot, 'off');
end