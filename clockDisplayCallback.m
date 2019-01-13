function clockDisplayCallback(player, ~)
    secondsElapsed = player.CurrentSample / player.SampleRate;
    minutes = floor(secondsElapsed / 60);
    seconds = mod(secondsElapsed, 60);
    player.UserData.ClockLabel.Text = sprintf('%02.0f:%02.0f', minutes, seconds);
end