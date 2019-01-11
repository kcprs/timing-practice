function saveIoSettings(app)
    inputDevice = app.InputDeviceDropDown.Value;
    outputDevice = app.OutputDeviceDropDown.Value;
    
    save('resources/IOSettings.mat', 'inputDevice', 'outputDevice');
end