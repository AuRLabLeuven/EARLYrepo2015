function [handles] = init_gui(hObject,handles)
%[handles] = init_gui(hObject,handles)
%   Initializes all the values for the different parameters on the gui.
%   Input: the signal parameters that are allready in handles (struct)
%   Output: An updated struct handles

%% filter init

% LL and UL init values
handles.filter.lowerthreshold = 100;
handles.filter.upperthreshold = 3000;

% filtering itself (calculation)
axes(handles.axes1)
plot_demand = 0;
[trace_filtered] = filter_and_plot(hObject,handles,plot_demand);
handles.trace = trace_filtered;

%% Peak detection init

% Treshold values peakfinder
handles.peak.threshold = 0.0075;

% Peakfinder excecution
axes(handles.axes1)
plot_demand = 0;
[peaks] = peak_finder_and_plot(hObject,handles,plot_demand);
handles.peak.positions = peaks;

%% Window size init

% window size init value
handles.window_size.time = 0.015;
handles.window_size.samples = round(handles.window_size.time*handles.Fs);

%% Movie parameters init

handles.display_speed_ratio = 1;

handles.window_step_size.time = 0.010;
handles.window_step_size.samples = round(handles.window_step_size.time*handles.Fs);

handles.minimal_display_time.time = 0.015;
handles.minimal_display_time.samples = round(handles.minimal_display_time.time*handles.Fs);

%% Audio selection init

handles.source_audio.stim = 0;
handles.source_audio.trace = 1;

%% Movie save file specs init

handles.file_specs.name = 'movie';
handles.file_specs.location = 'C:\EARLYrepo2015\sandbox\osciplot_tool';

