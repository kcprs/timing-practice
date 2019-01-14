function saveIoSettings(app)
    % saveIoSettings Saves I/O settings of the app to a file for later use

    inputDevice = app.InputDeviceDropDown.Value;
    outputDevice = app.OutputDeviceDropDown.Value;
    save('resources/IOSettings.mat', 'inputDevice', 'outputDevice');
end
