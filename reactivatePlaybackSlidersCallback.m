function reactivatePlaybackSlidersCallback(player, ~)
    % reactivatePlaybackSlidersCallback Reactivates playback setting sliders in the "Results" tab of the app.
    %   This function is called by the timer of MATLAB's audioplayer object once it stops.

    player.UserData.RecordingVolumeSlider.Enable = true;
    player.UserData.MetronomeVolumeSlider.Enable = true;
    player.UserData.PlaybackRateSlider.Enable = true;
end
