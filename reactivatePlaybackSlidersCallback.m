function reactivatePlaybackSlidersCallback(player, ~)
    player.UserData.RecordingVolumeSlider.Enable = true;
    player.UserData.MetronomeVolumeSlider.Enable = true;
    player.UserData.PlaybackRateSlider.Enable = true;
end
