function clockDisplayCallback(player, ~)
    % clockDisplayCallback Updates the clock display on the "Practice" tab of the app.
    %   This function is called every second by the timer of MATLAB's audioplayer object.

    secondsElapsed = player.CurrentSample / player.SampleRate;
    minutes = floor(secondsElapsed / 60);
    seconds = mod(secondsElapsed, 60);
    player.UserData.ClockLabel.Text = sprintf('%02.0f:%02.0f', minutes, seconds);
end