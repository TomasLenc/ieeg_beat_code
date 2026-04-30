function UR_EAR_2020b
% Version 2020b, 18 May 2020

program = 'UR_EAR';
version = '2020b';


%% %%%%%%%%%%%%%%%%%%%%%%  UR_EAR_2020b (May 2020)  %%%%%%%%%%%%%%%%%%%%%%
% Improved appearance and discoverability of analysis window features.
% Added periodic check for existence of a new version.
%% %%%%%%%%%%%%%%%%%%%%%  UR_EAR_2020a (April 2020)  %%%%%%%%%%%%%%%%%%%%%
% GUI code extensively modified with the following goals in mind:
%   1. Resizing figure does not change font sizes and whole interface keeps a
%      consistent and pleasing look.
%   2. Make it easier to add new stimuli, especially if special features are
%      needed such as functions to process parameter entries as they are
%      entered.
% In addition, some limitations and bugs were fixed and some new features added.
%   1. Right-clicking on a plot for the purpose of detaching the plot no
%      longer causes the plot contents to change first.
%   2. Analysis window, the time span over which plots and averages of model
%      results are computed, can be changed easily.
%   3. Audio files can be selected by browsing simply by right-clicking on
%      file name parameter fields.
%   4. Figure size and position are saved between uses.
%% %%%%%%%%%%%%%%%%%%%%%%%   UR_EAR_v2_0  (8/10/18)  %%%%%%%%%%%%%%%%%%%%%
%  Version of UR_EAR updated and extended by Afagh Farhadi at University of
%  Rochester.  
%% %%%%%%%%%%%%%%  v2_1 (9/20/18 LHC)
%  Fixed bugs in re-sampling and LTASS noise addition (optional) for *.wav
%  inputs. Fixed assignment of cohc, cihc based on audiogram values.
%% %%%%%%%%%%%%%%%%%%%% LHC - v1_0 (9/23/16) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% First "release" version of code tool developed by UR Research Assistants
% Natalia Galant, Braden Maxwell, Danika Teverovsky, Thomas Varner,
% Langchen Fan in the Carney lab at the University of Rochester, Depts of
% BME & Neuroscience
%   Presented at ARO 2016
% See User_Manual.pdf and Readme.txt files for more info.
% Send queries to Laurel.Carney@Rochester.edu.
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%{
            Code outline
----------------------------------------------
 1. Set platform-specific font and control info.
 2. Initialize local and shared variables.
 3. Create the figure.
 4. Define stimuli:
   A. Set the stimulus types.
   B. Create Stimulus Type popup menu
   C. Create the stimulus parameter panels and their contents.
   D. Fill in information about parameters for each stimulus type.
   E. Create the stimulus parameter panels and their controls.
   F. Initialize any controls that need it.
 5. Create the Model Parameters panel and its controls.
 6. Create Run button and associated controls.
 7. Create info panel above graphs and its contents and documentation note below figures.
 8. Create output panel and contents for "narrow" plots.
 9. Create output panel and contents for "wide" plots.
10. Run AN and IC model callback functions to set up initial states.
11. Make figure visible and hide its handle.
12. Callback functions and other nested functions:
   A. run():                  Create stimuli and then run UR_EAR_model_plots().
   B. UR_EAR_model_plots():   Run the model(s) and display results. (not callback)
   C. select_AN_model():      Select which AN model to use.
   D. select_IC_model():      Select which IC model to use.
   E. size_changed():         Run when figure is resized.
   F. play_cond1_stim():      Play condition 1 stimulus.
   G. play_cond2_stim():      Play condition 2 stimulus (if any).
   H. close_fig():            Close the figure and quit the application.
   I. stimTypeMenuCallback(): Select the stimulus type.
   J. handle_be_bs_radio():   Select whether IC Ave. Rate plot shows BE or BS
                              model results.
   K. sel_line_down():        Handle clicking on an analysis window line to be dragged.
   L. sel_line_move():        Handle dragging an analysis window line.
   M. sel_line_up():          Handle releasing a click on an analysis window line.
   N. set_analysis_window():  Display an input dialog to set analysis window.
   O. display_help_dialog():  Display help info for setting the analysis window.
   P. reset_selection():      Reset analysis window to default.
   Q. update_plots_with_selection() (not callback)
   R. Next plots: These functions are triggered by clicking on the corresponding
                  graph and are named next_* because they display the data for
                  the next condition in sequence, returning to the beginning as
                  if they are in a circular buffer. Currently, the program only
                  handles two conditions.
     a. next_wave():       Display stimulus waveform.
     b. next_specgram():   Display stimulus spectrogram.
     c. next_spec():       Display stimulus spectrum.
     d. next_AN_model():   Display AN model results.
     e. next_IC_model():   Display IC model results.
     f. next_AN_avg():     Display average of AN model results (no click behavior)
     g. next_CN_avg():     Display average of CN model results (no click behavior)
     h. next_IC_avg():     Display average of IC model results (no click behavior)
     i. next_wave_w():     Display stimulus waveform (wide version)
     j. next_specgram_w(): Display stimulus spectrogram (wide version).
     k. next_VIHC_w():     Display VIHC model results (wide plot).
     l. next_AN_model_w(): Display AN model results (wide version).
     m. next_IC_model_w(): Display IC model results (wide version).
     n. next_wide_plots(): Change all wide plots.
   S. wide_display(): Toggles whether narrow or wide plots are displayed.
   T. save_data(): Saves data to mat-file.
   U. quickplot(): Plots summary plots in a new figure.
13. Utility function:
   A. make_detachable(): Adds a context menu to an axes which can be used to
                         "detach" a plot, meaning that a copy of the plot is
                         made in a new figure.
%}

% Throughout this program, sprintf with the %c format specifier appears
% occasionally.  This is done to create strings containing Unicode characters
% which employ character codes above 127.  For example,
%   sprintf('This is an upper case Greek letter delta: %c',916)


% Check web site to see if this is the most recent version.
if getpref(program,'check_for_new_version',true)
	last_version_check_success = getpref(program,'last_version_check_success',0);
	version_check_interval = getpref(program,'version_check_interval',30);
	timeout = 5;
	today = floor(now);
	if today >= last_version_check_success + version_check_interval
		url = 'https://www.urmc.rochester.edu/labs/carney.aspx';
		try
			page = webread(url,weboptions('Timeout',timeout));
			online_version = regexp(page,'UR_EAR_(\d{4}[a-z])\.zip','tokens','once');
			[~,order] = sort({char(online_version),version});
			if isequal(order,[2 1])
				web(url)
			end
			setpref(program,'last_version_check_success',today);
		catch
		end
	end
end

% Initial default parameters for GUI on Windows, Mac and Ubuntu displays.  In
% general, display parameters on GNU/Linux vary more so changes may need to be
% made for your workstation.  Small changes will probably still look okay.
g_root = groot;
if ispc
	font_name = 'Segoe UI';
	font_size = 9;
	bigfont = 12;
	axes_font_size = 8.25;
	% Adjustments to uicontrols for this font and font size.
	edit_adj = [0 0 0 23];
	popup_adj = [0 -2 0 23];
	text_adj = [0 0 0 19];
	button_adj = [0 -2 0 24];
	check_adj = [0 0 0 23];
	radio_cb_width = 15;
elseif ismac
	font_name = 'Lucida Grande';
	font_size = 11;
	bigfont = 14;
	axes_font_size = 10;
	% Adjustments to uicontrols for this font and font size.
	edit_adj = [0 0 0 22];
	popup_adj = [0 0 0 22];
	text_adj = [0 0 0 20];
	button_adj = [0 -4 0 28];
	check_adj = [0 0 0 22];
	radio_cb_width = 20;
else % GNU/Linux, tested on Ubuntu 18.04.3 LTS
	font_name = 'Dialog';
	font_size = 9;
	bigfont = 11;
	axes_font_size = 7;
	% Adjustments to uicontrols for this font and font size.
	edit_adj = [0 0 0 23];
	popup_adj = [0 0 0 23];
	text_adj = [0 0 0 19];
	button_adj = [0 -2 0 26];
	check_adj = [0 0 0 23];
	radio_cb_width = 15;
end


% Initialize variables.
%--------------------------------------------------------------------------
% Set initial IC model.
Which_IC = 2;

% Set initial AN model.
Which_AN = 1;

% Initial selection for which IC model avg. rate plot to show.
be_bs_selection = 1; % 1 => BE, 2 => BS

% Set a default range of CFs; this can be updated on GUI.
cfRange = [200 3000];

% Set color of Analysis Window selection lines.
selection_line_color = [0.75 0.75 0.75];

% "Randomize" the random number generator seed.
rng('shuffle')

% Set width of parameter panels.
param_width = 330; % pixels
stimIdx = 1; % stimulus type identifier

% Make sure the following are shared variables.
CFs = [];
Condition = [];
CF_range = [];
nconditions = [];
aw_t = [0 0.04]; % initial analysis window
move_both = [];

%  Initialize counters for rotating plots through conditions.
clicks_wave_n = 0;
clicks_specgram_n = 0;
clicks_spec_n = 0;
clicks_wave_w = 0;
clicks_specgram_w = 0;
clicks_an_timefreq_w = 0;
clicks_vihc_timefreq = 0;
clicks_ic_timefreq_w = 0;
clicks_an_timefreq = 0;
clicks_ic_timefreq = 0;
clicks_ic_avg_rate = 0;
clicks_wide = 0;

% Model sampling rate (must be 100k, 200k or 500k for AN model):
Fs = 100e3; % samples/sec
RsFs = 10e3;  % resample rate for time_freq surface plots
Pref = 20e-6; % reference pressure in pascals


% Create and position the figure.
%--------------------------------------------------------------------------
% Determine initial figure position.
% Get screen size in pixels.
screen_units = g_root.Units;
g_root.Units = 'pixels';
ss = g_root.ScreenSize;
screen_wh = ss(3:4);
g_root.Units = screen_units;
if ispref(program,'figure_position')
	% Use the preference if it exists and set flag not to run movegui.
	fig_pos = getpref(program,'figure_position');
	fig_wh = fig_pos(3:4);
	center_figure = false;
else
	% If preference does not exist, i.e., this is the first time application has
	% been run, set width and height of figure to preferred values up to a
	% maximum of 90% of screen size. Figure can be resized as desired and that
	% size will be saved as a preference and used in the future.  Figure will be
	% centered at run-time with movegui.
	
	% Set width and height up to a maximum of 90% of screen size.
	preferred_wh = [1000 708];
	fig_wh = min(preferred_wh,0.9*screen_wh);
	fig_pos = [0,0,fig_wh];
	center_figure = true;
end

% Create figure.
fig = figure('Units','pixels',...
	'Position',fig_pos,...
	'IntegerHandle','off',...
	'Name',mfilename,...
	'Menubar','none',...
	'ToolBar','none',...
	'DefaultUIControlFontName',font_name,...
	'DefaultUIControlFontSize',font_size,...
	'DefaultUIPanelFontName',font_name,...
	'DefaultUIPanelFontSize',font_size,...
	'DefaultAxesFontName','Helvetica',...
	'DefaultAxesFontSize',axes_font_size,...
	'Visible','off',...
	'Color',[0.94 0.94 0.94],...
	'SizeChangedFcn',@size_changed,...
	'CloseRequestFcn',@close_fig);
% Starting in R2018a, MATLAB has automatic axes font sizing which needs to be
% turned off.  The following command is placed in a try/catch block in case the
% version used is older than that and this command fails.
try
	set(fig,'DefaultAxesFontSizeMode','manual')
catch
end

% Center the figure on the screen if not using previously saved position,
% otherwise make sure figure is completely on-screen in case screen size has
% been changed.
if center_figure
	movegui(fig,'center')
else
	op = fig.OuterPosition + [0 0 -1 -1];
	ur = op(1:2) + op(3:4);
	if op(1) < ss(1) || op(2) < ss(2) || ur(1) > ss(3) || ur(2) > ss(4)
		movegui(fig,'onscreen')
	end
end

% Determine name of Tootip property.  Create temporary uicontrol, get its
% properties, then delete it.  Property name will be either 'Tooltip' (new
% versions of MATLAB) or 'TooltipString' (older versions).
temp = uicontrol(fig);
props = properties(temp);
delete(temp)
Tooltip = props{strncmp(props,'Tooltip',7)};



% Set stimulus types.
%--------------------------------------------------------------------------
% Types of Stimuli: Modify this, and every line marked with "STIM", to add a new
% stimulus.
stimTypeOptions = {'Audio File',...
	'Noise Band (Edge Pitch)',...
	'Notched Noise',...
	'Tone in Noise',...
	'Profile Analysis',...
	'Pinna Cues',...
	'SAM Tone',...
	'Complex Tone',...
	'Single Formant',...
	'Double Formant',...
	'Schroeder Phase',...
	'Noise-in-Notched Noise',...
	'FM Tone',...
	'Forward Masking',...
	'CMR Band Widen',...
	'CMR Flank Band'};

numOptions = length(stimTypeOptions);


% Create "Stimulus Type" popup menu and its label.
%--------------------------------------------------------------------------
stim_type_text = uicontrol(fig,...
	'Style','text',...
	'Units','pixels',...
	'Position',[20 fig_wh(2)-35 param_width-35 0] + text_adj,...
	'HorizontalAlignment','left',...
	'String','Stimulus Type:');
stim_type_text.Position(3) = stim_type_text.Extent(3);

x = stim_type_text.Position(3) + 20;
w = param_width - 40 - stim_type_text.Position(3);
stim_type_popup = uicontrol(fig,...
	'Style','popupmenu',...
	'Units','pixels',...
	'Position',[x fig_wh(2)-35 w 0] + popup_adj,...
	'String',stimTypeOptions,...
	'Callback',@select_stim_type);


% Create the stimulus parameter panels and their contents (STIM).
%--------------------------------------------------------------------------
% Make a structure array, one element per stim type.
% Each structure element will have the following fields:
%	Type = stimulus type string (taken from stimTypeOptions above)
%	Description1 = description of condition 1 (if any)
%	Description2 = description of condition 2 (if any)
%	Panel = graphics handle to panel for that stimulus type
%	UseLogAxes = whether results will be plotted on a log scale (T/F)
%	NumParams = number of parameters for that stimulus type
%	Params = structure array, one element per parameter with fields:
%		Row = row # placement on panel, integer from 1 (top row) to NumParams
%		Style = inferred from Value, but can also be 'radiobutton'
%		Label = label string for param
%		Value = numeric, logical, popupmenu index, or string(?)
%		Choices = cell array of strings for popupmenu, empty for others
%		LabelH graphics handle to label uicontrol (if any)
%		ValueH graphics handle to value uicontrol
%		Callback = callback function for ValueH (if any)
%		ButtonDownFcn = ButtonDownFcn for ValueH (if any)
%		Tooltip = tool tip with any explanatory text
%		Data = anything
%
%	The Type and Panel fields are assigned automatically as are the Row number
%	and graphic handles in the Params structure array.
%
% 	(Note: checkboxes have no separate label uicontrol; use label text for
% 	String property of checkbox.)
%
%	The Params structure fields Callback and ButtonDownFcn are provided in case
%	some code needs to be run when the user changes the parameter, such as
%	changing the content of another parameter.  They won't be needed for most
%	stimuli where it is only necessary to collect some simple values.

% Initialize structure array with all information about parameters.
stimData = struct('Type',stimTypeOptions,...
	'Description1','',...
	'Description2','',...
	'Panel',[],...
	'UseLogAxes',true,... % usual case so use as default
	'NumParams',0,...
	'Params',[]);

% Anonymous function to initialize one Params field.
init_params_struct = @(s,id)struct('Row',num2cell(1:s(id).NumParams),...
	'Style','','Label',[],'Value',[],'Choices',[],'LabelH',[],...
	'ValueH',[],'Callback','','ButtonDownFcn','','Tooltip','','Data',[]);

% Fill in information about parameters for each stimulus type.
%-------------------------------------------------------------

% Audio file.
id = 1;
initial_file1 = 'm06ae.wav';
initial_file2 = 'm06iy.wav';
stimData(id).Description1 = initial_file1;
stimData(id).Description2 = initial_file2;
stimData(id).NumParams = 4;
stimData(id).Params = init_params_struct(stimData,id);
stimData(id).Params(1).Label = 'Sound level (dB SPL)';
stimData(id).Params(1).Value = 65;
stimData(id).Params(1).Callback = @process_sound_level_entry;
stimData(id).Params(1).Tooltip = 'If blank, do not scale sound level';
stimData(id).Params(2).Label = 'File 1';
stimData(id).Params(2).Value = initial_file1;
stimData(id).Params(2).Data = initial_file1;
stimData(id).Params(2).Callback = {@process_audio_file_entry,2};
stimData(id).Params(2).ButtonDownFcn = {@browse_audio_file,2};
stimData(id).Params(2).Tooltip = 'Right-click edit box to browse';
stimData(id).Params(2).Tooltip = sprintf('%s\n%s',...
			strrep(which(initial_file1),'/',char(8725)),'Right-click edit box to browse');
stimData(id).Params(3).Label = 'File 2';
stimData(id).Params(3).Value = initial_file2;
stimData(id).Params(3).Data = initial_file2;
stimData(id).Params(3).Callback = {@process_audio_file_entry,3};
stimData(id).Params(3).ButtonDownFcn = {@browse_audio_file,3};
stimData(id).Params(3).Tooltip = 'Right-click edit box to browse';
stimData(id).Params(3).Tooltip = sprintf('%s\n%s',...
			strrep(which(initial_file2),'/',char(8725)),'Right-click edit box to browse');
stimData(id).Params(4).Label = 'LTASS SNR (dB)';
stimData(id).Params(4).Value = -Inf;
stimData(id).Params(4).Tooltip = 'If sound level is not specified, enter noise level in dB SPL';
	function process_sound_level_entry(hh,~)
		if isempty(hh.String)
			stimData(1).Params(4).LabelH.String = 'LTASS level (dB SPL)';
			stimData(1).Params(4).LabelH.Position(3) = stimData(1).Params(4).LabelH.Extent(3);
		else
			stimData(1).Params(4).LabelH.String = 'LTASS SNR (dB)';
			stimData(1).Params(4).LabelH.Position(3) = stimData(1).Params(4).LabelH.Extent(3);
		end
	end
	function process_audio_file_entry(hh,~,k)
		% Copy typed entry to Data and Description.
		stimData(1).Params(k).Data = hh.String;
		switch k
			case 2
				stimData(1).Description1 = hh.String;
			case 3
				stimData(1).Description2 = hh.String;
		end
	end
	function browse_audio_file(hh,~,k)
		% Browse for any audio file.
		valid_types_c = {'*.wav','*.ogg','*.flac','*.au','*.aiff','*.aif',...
			'*.aifc','*.mp3','*.m4a','*.mp4','*.m4v'};
		if ~ismac % Windows and Linux
			valid_types_c = [valid_types_c,{'*.wmv','*.avi'}];
		end
		valid_types_str = strjoin(valid_types_c,';');
		
		% Get last audio_file_path from preferences.
		audio_file_path = getpref(program,'audio_file_path','');
		if ~exist(audio_file_path,'dir')
			audio_file_path = '';
		end
		
		[f,p] = uigetfile({valid_types_str,'All Audio Files'},'Select an audio file',audio_file_path);
		if isequal(p,0) % user pressed Cancel
			return
		end
		
		% Make returned path the default for next time.
		setpref(program,'audio_file_path',p)
		
		% Put full path to the file in Data and only the file name in Value and
		% the edit box.
		hh.String = f;
		pf = fullfile(p,f);
		stimData(1).Params(k).Data = pf;
		stimData(1).Params(k).Value = f;
		% The unicode symbol 8725 looks like a slash and is necessary to avoid a
		% bug that causes the tooltip text to overlap.  Replacing true slashes
		% with char(8725) makes it look better.
		stimData(1).Params(k).ValueH.(Tooltip) = sprintf('%s\n%s',...
			strrep(pf,'/',char(8725)),'Right-click edit box to browse');
		switch k
			case 2
				stimData(1).Description1 = f;
			case 3
				stimData(1).Description2 = f;
		end
	end

% Noise Band.
id = 2;
stimData(id).NumParams = 5;
stimData(id).Params = init_params_struct(stimData,id);
stimData(id).Params(1).Label = 'Sound level (dB SPL)';
stimData(id).Params(1).Value = 65;
stimData(id).Params(2).Label = 'Duration (s)';
stimData(id).Params(2).Value = 0.5;
stimData(id).Params(3).Label = 'Ramp Dur (s)';
stimData(id).Params(3).Value = 0.02;
stimData(id).Params(4).Label = 'Low Freq Cutoff (Hz)';
stimData(id).Params(4).Value = 100;
stimData(id).Params(5).Label = 'High Freq Cutoff (Hz)';
stimData(id).Params(5).Value = 800;

% Notched Noise.
id = 3;
stimData(id).Description1 = 'Without tone';
stimData(id).Description2 = 'With tone';
stimData(id).NumParams = 7;
stimData(id).Params = init_params_struct(stimData,id);
stimData(id).Params(1).Label = 'Noise level (db SPL)';
stimData(id).Params(1).Value = 65;
stimData(id).Params(2).Label = 'Duration (s)';
stimData(id).Params(2).Value = 0.6;
stimData(id).Params(3).Label = 'Ramp duration (s)';
stimData(id).Params(3).Value = 0.1;
stimData(id).Params(4).Label = 'Center frequency (Hz)';
stimData(id).Params(4).Value = 1500;
stimData(id).Params(5).Label = sprintf('%c = CF%cnotch_width/2',916,215); % \Delta, \times
stimData(id).Params(5).Value = 0.1;
stimData(id).Params(6).Label = 'Bandwidth/CF';
stimData(id).Params(6).Value = 0.8;
stimData(id).Params(7).Label = 'Tone level (dB SPL)';
stimData(id).Params(7).Value = 50;

% Tone in Noise.
id = 4;
stimData(id).Description1 = 'Without tone';
stimData(id).Description2 = 'With tone';
stimData(id).NumParams = 7;
stimData(id).Params = init_params_struct(stimData,id);
stimData(id).Params(1).Label = 'Duration (s)';
stimData(id).Params(1).Value = 0.3;
stimData(id).Params(1).Callback = @compute_SNR;
stimData(id).Params(2).Label = 'Ramp duration (s)';
stimData(id).Params(2).Value = 0.01;
stimData(id).Params(2).Callback = @compute_SNR;
stimData(id).Params(3).Label = 'Tone frequency (Hz)';
stimData(id).Params(3).Value = 500;
stimData(id).Params(3).Callback = @compute_SNR;
stimData(id).Params(4).Label = 'Noise spectrum level';
stimData(id).Params(4).Value = 40;
stimData(id).Params(4).Callback = @compute_SNR;
stimData(id).Params(5).Label = sprintf('E%c/N%c (dB)',8347,8320); % sub s, sub zero
stimData(id).Params(5).Value = 15;
stimData(id).Params(5).Callback = @compute_SNR;
stimData(id).Params(6).Label = 'SNR, computed (dB)';
stimData(id).Params(6).Value = NaN;
stimData(id).Params(7).Label = 'Noise BW (Hz or octave fraction)';
stimData(id).Params(7).Value = '1/3';
stimData(id).Params(7).Data = struct('BWType','octaves','Value',1/3);
stimData(id).Params(7).Callback = @parse_TIN_BW;
fmtspec = 'Enter two frequencies, e.g., "100 3000" or\nfraction of an octave with a slash, e.g., "1%c3".';
stimData(id).Params(7).Tooltip = sprintf(fmtspec,8725); % 8725 = slash
	function parse_TIN_BW(~,~)
		% Determine if the entry consists of two frequencies or a fraction.
		params = stimData(4).Params;
		str = params(7).ValueH.String;
		value = str2num(str); %#ok<ST2NM>
		if sum(str == '/') == 1 && isscalar(value)
			stimData(4).Params(7).Data = struct('BWType','octaves','Value',value);
		elseif numel(value) == 2
			stimData(4).Params(7).Data = struct('BWType','hertz','Value',value);
		else
			uiwait(errordlg('Incorrect entry.','Noise BW','modal'))
			return
		end
		compute_SNR()
	end
	function compute_SNR(~,~)
		% Compute SNR based on typed entries.
		params = stimData(4).Params;
		dur = str2double(params(1).ValueH.String);
		rampdur = str2double(params(2).ValueH.String);
		freq = str2double(params(3).ValueH.String);
		N0 = str2double(params(4).ValueH.String);
		Es_N0 = str2double(params(5).ValueH.String);
		switch stimData(4).Params(7).Data.BWType
			case 'octaves'
				bw_freqs = freq.*2.^([-0.5 0.5]*params(7).Data.Value);
			case 'hertz'
				bw_freqs = params(7).Data.Value;
		end
		bin_mode = 1; % for monaural stimulus, bin_mode = 1
		
		% Just calculate SNR.
		calculate_SNR_only = true;
		TINstruct = stimuli.TIN(dur,rampdur,freq,N0,Es_N0,bin_mode,bw_freqs,Fs,calculate_SNR_only);
		% Update SNR.
		stimData(4).Params(6).ValueH.String = sprintf('%.1f',TINstruct.SNR);
	end

% Profile Analysis.
id = 5;
stimData(id).Description1 = 'Without increment';
stimData(id).Description2 = 'With increment';
stimData(id).NumParams = 5;
stimData(id).Params = init_params_struct(stimData,id);
stimData(id).Params(1).Label = 'Sound level (dB SPL)';
stimData(id).Params(1).Value = 65;
stimData(id).Params(2).Label = 'Duration (s)';
stimData(id).Params(2).Value = 0.5;
stimData(id).Params(3).Label = 'Ramp duration (s)';
stimData(id).Params(3).Value = 0.01;
stimData(id).Params(4).Label = '# of components (must be odd)';
stimData(id).Params(4).Value = 11;
stimData(id).Params(4).Callback = @check_num_components;
stimData(id).Params(5).Label = 'Increment (dB)';
stimData(id).Params(5).Value = -2;
	function check_num_components(~,~)
		% Determine if the entry is even or odd.
		params = stimData(5).Params;
		value = str2double(params(4).ValueH.String);
		if ~rem(value,2)
			new_value = value + 1;
			stimData(5).Params(4).Value = new_value;
			stimData(5).Params(4).ValueH.String = sprintf('%g',new_value);
			uiwait(errordlg('Number of components must be odd.','Number of components','modal'))
			return
		end
	end


% Pinna Cues.
id = 6;
stimData(id).Description1 = 'Notch';
stimData(id).NumParams = 4;
stimData(id).Params = init_params_struct(stimData,id);
stimData(id).Params(1).Label = 'Sound level (dB SPL)';
stimData(id).Params(1).Value = 40;
stimData(id).Params(2).Label = 'Duration (s)';
stimData(id).Params(2).Value = 0.5;
stimData(id).Params(3).Label = 'Ramp duration (s)';
stimData(id).Params(3).Value = 0.01;
stimData(id).Params(4).Label = 'Notch freq. (Hz) "Adjust CFs!"';
stimData(id).Params(4).Value = 7000;

% SAM Tone.
id = 7;
stimData(id).Description1 = 'Unmodulated';
stimData(id).Description2 = 'Modulated';
stimData(id).NumParams = 6;
stimData(id).Params = init_params_struct(stimData,id);
stimData(id).Params(1).Label = 'Sound level (dB SPL)';
stimData(id).Params(1).Value = 65;
stimData(id).Params(2).Label = 'Duration (s)';
stimData(id).Params(2).Value = 0.5;
stimData(id).Params(3).Label = 'Ramp duration (s)';
stimData(id).Params(3).Value = 0.01;
stimData(id).Params(4).Label = 'Carrier frequency (Hz)';
stimData(id).Params(4).Value = 1500;
stimData(id).Params(5).Label = 'Modulation frequency (Hz)';
stimData(id).Params(5).Value = 100;
stimData(id).Params(6).Label = 'Modulation depth (dB)';
stimData(id).Params(6).Value = 0;

% Complex Tone.
id = 8;
stimData(id).UseLogAxes = false;
stimData(id).NumParams = 8;
stimData(id).Params = init_params_struct(stimData,id);
stimData(id).Params(1).Label = 'Sound level (dB SPL)';
stimData(id).Params(1).Value = 65;
stimData(id).Params(2).Label = 'Duration (s)';
stimData(id).Params(2).Value = 0.5;
stimData(id).Params(3).Label = 'Ramp duration (s)';
stimData(id).Params(3).Value = 0.1;
stimData(id).Params(4).Label = sprintf('F%c (Hz)',8320); % sub 0
stimData(id).Params(4).Value = 200;
stimData(id).Params(5).Label = 'Number of components';
stimData(id).Params(5).Value = 15;
stimData(id).Params(6).Label = 'Include fundamental';
stimData(id).Params(6).Value = true;
stimData(id).Params(7).Label = 'Filter type';
stimData(id).Params(7).Choices = {'None','Low-pass','High-pass','Band-pass','Band-reject'};
stimData(id).Params(7).Value = 1;
stimData(id).Params(7).Callback = @show_freqs;
stimData(id).Params(8).Label = 'Cutoff frequencies (Hz)';
stimData(id).Params(8).Value = 100;
	function show_freqs(hh,~)
		% Make cutoff frequencies item visible or invisible, as needed.
		if hh.Value == 1
			stimData(8).Params(8).LabelH.Visible = 'off';
			stimData(8).Params(8).ValueH.Visible = 'off';
		else
			stimData(8).Params(8).LabelH.Visible = 'on';
			stimData(8).Params(8).ValueH.Visible = 'on';
		end
	end

% Single Formant.
id = 9;
stimData(id).UseLogAxes = false;
stimData(id).NumParams = 6;
stimData(id).Params = init_params_struct(stimData,id);
stimData(id).Params(1).Label = 'Sound level (dB SPL)';
stimData(id).Params(1).Value = 65;
stimData(id).Params(2).Label = 'Duration (s)';
stimData(id).Params(2).Value = 0.3;
stimData(id).Params(3).Label = 'Ramp duration (s)';
stimData(id).Params(3).Value = 0.025;
stimData(id).Params(4).Label = 'Peak frequency (Hz)';
stimData(id).Params(4).Value = 2000;
stimData(id).Params(5).Label = sprintf('F%c (Hz)',8320); % sub 0
stimData(id).Params(5).Value = 200;
stimData(id).Params(6).Label = 'G, spectral slope (dB/octave)';
stimData(id).Params(6).Value = 200;

% Double Formant.
id = 10;
stimData(id).UseLogAxes = false;
stimData(id).NumParams = 6;
stimData(id).Params = init_params_struct(stimData,id);
stimData(id).Params(1).Label = 'Sound level (dB SPL)';
stimData(id).Params(1).Value = 65;
stimData(id).Params(2).Label = 'Duration (s)';
stimData(id).Params(2).Value = 0.3;
stimData(id).Params(3).Label = 'Ramp duration (s)';
stimData(id).Params(3).Value = 0.025;
stimData(id).Params(4).Label = sprintf('F%c (Hz)',8320); % sub 0
stimData(id).Params(4).Value = 200;
stimData(id).Params(5).Label = 'Formant frequencies (Hz)';
stimData(id).Params(5).Value = [500 2100];
stimData(id).Params(6).Label = 'Bandwidths (Hz)';
stimData(id).Params(6).Value = [70 90];

% Schroeder Phase.
id = 11;
stimData(id).Description1 = 'C > 0';
stimData(id).Description2 = 'C < 0';
stimData(id).UseLogAxes = false;
stimData(id).NumParams = 7;
stimData(id).Params = init_params_struct(stimData,id);
stimData(id).Params(1).Label = 'Sound level (dB SPL)';
stimData(id).Params(1).Value = 65;
stimData(id).Params(2).Label = 'Duration (s)';
stimData(id).Params(2).Value = 0.1;
stimData(id).Params(3).Label = 'Ramp duration (s)';
stimData(id).Params(3).Value = 0.025;
stimData(id).Params(4).Label = sprintf('F%c (Hz)',8320); % sub 0
stimData(id).Params(4).Value = 100;
stimData(id).Params(5).Label = '# components';
stimData(id).Params(5).Value = 30;
stimData(id).Params(6).Label = '|C|';
stimData(id).Params(6).Value = 1;
stimData(id).Params(7).Label = 'Include fundamental';
stimData(id).Params(7).Value = true;

% Noise-in-Notched Noise.
id = 12;
stimData(id).Description1 = 'Standard';
stimData(id).Description2 = 'Test (w/increment)';
stimData(id).NumParams = 4;
stimData(id).Params = init_params_struct(stimData,id);
stimData(id).Params(1).Label = 'Duration (s)';
stimData(id).Params(1).Value = 0.2;
stimData(id).Params(2).Label = 'Ramp duration (s)';
stimData(id).Params(2).Value = 0.01;
stimData(id).Params(3).Label = 'Target noise spectrum level (dB)';
stimData(id).Params(3).Value = 20;
stimData(id).Params(4).Label = 'Increment (dB)';
stimData(id).Params(4).Value = 5;

% FM Tone.
id = 13;
stimData(id).Description1 = 'Signal';
stimData(id).Description2 = 'Reference';
stimData(id).NumParams = 6;
stimData(id).Params = init_params_struct(stimData,id);
stimData(id).Params(1).Label = 'Sound level (dB SPL)';
stimData(id).Params(1).Value = 65;
stimData(id).Params(2).Label = 'Duration (s)';
stimData(id).Params(2).Value = 0.65;
stimData(id).Params(3).Label = 'Ramp duration (s)';
stimData(id).Params(3).Value = 0.01;
stimData(id).Params(4).Label = 'Center frequency';
stimData(id).Params(4).Value = 1000;
stimData(id).Params(5).Label = sprintf('C1: [F%c %cf] ([Hz %%])',8344,8710); % sub m, \Delta
stimData(id).Params(5).Value = [5 13.9];
stimData(id).Params(6).Label = sprintf('C2: [F%c %cf] ([Hz %%])',8344,8710); % sub m, \Delta
stimData(id).Params(6).Value = [5 20];

% Forward Masking.
id = 14;
stimData(id).Description1 = 'Mask + Probe';
stimData(id).Description2 = 'Mask only';
stimData(id).NumParams = 8;
stimData(id).Params = init_params_struct(stimData,id);
stimData(id).Params(1).Label = 'Masker level (dB SPL)';
stimData(id).Params(1).Value = 65;
stimData(id).Params(2).Label = 'Masker duration (s)';
stimData(id).Params(2).Value = 0.2;
stimData(id).Params(3).Label = 'Masker ramp duration (s)';
stimData(id).Params(3).Value = 0.004;
stimData(id).Params(4).Label = 'Probe duration (s)';
stimData(id).Params(4).Value = 0.016;
stimData(id).Params(5).Label = 'Probe level (dB SPL)';
stimData(id).Params(5).Value = 40;
stimData(id).Params(6).Label = 'Masker frequency (Hz)';
stimData(id).Params(6).Value = 2000;
stimData(id).Params(7).Label = 'Probe frequency (Hz)';
stimData(id).Params(7).Value = 2000;
stimData(id).Params(8).Label = 'Delay (s)';
stimData(id).Params(8).Value = 0.01;

% CMR_BW.
id = 15;
stimData(id).Description1 = 'Modulated with tone';
stimData(id).Description2 = 'Unmodulated with tone';
stimData(id).NumParams = 9;
stimData(id).Params = init_params_struct(stimData,id);
stimData(id).Params(1).Label = 'Tone duration (s)';
stimData(id).Params(1).Value = 0.3;
stimData(id).Params(2).Label = 'Tone ramp duration (s)';
stimData(id).Params(2).Value = 0.05;
stimData(id).Params(3).Label = 'Tone Frequency (Hz)';
stimData(id).Params(3).Value = 1000;
stimData(id).Params(4).Label = 'Tone level (dB SPL)';
stimData(id).Params(4).Value = 65;
stimData(id).Params(5).Label = 'Noise bandwidth (Hz)';
stimData(id).Params(5).Value = 400;
stimData(id).Params(6).Label = 'Noise spectrum level (dB Pa/Hz)';
stimData(id).Params(6).Value = 30;
stimData(id).Params(7).Label = 'Noise duration (s)';
stimData(id).Params(7).Value = 0.6;
stimData(id).Params(8).Label = 'Noise ramp duration (s)';
stimData(id).Params(8).Value = 0.01;
stimData(id).Params(9).Label = 'Modulation bandwidth (Hz)';
stimData(id).Params(9).Value = 50;

% CMR_FB.
id = 16;
stimData(id).Description1 = 'Comod with tone';
stimData(id).Description2 = 'Codev with tone';
stimData(id).NumParams = 6;
stimData(id).Params = init_params_struct(stimData,id);
stimData(id).Params(1).Label = 'Duration (s)';
stimData(id).Params(1).Value = 0.3;
stimData(id).Params(2).Label = 'Ramp duration (s)';
stimData(id).Params(2).Value = 0.01;
stimData(id).Params(3).Label = 'Tone Frequency (Hz)';
stimData(id).Params(3).Value = 1000;
stimData(id).Params(4).Label = 'Noise spectrum level (dB Pa/Hz)';
stimData(id).Params(4).Value = 40;
stimData(id).Params(5).Label = 'Tone level (dB SPL)';
stimData(id).Params(5).Value = 65;
stimData(id).Params(6).Label = 'Flank bandwidth (Hz)';
stimData(id).Params(6).Value = 100;

% Example user-added stimulus with two parameters, initially 1.1 and 2.2. (STIM)
% id = 17;
% stimData(id).Description1 = 'Description of condition 1';
% stimData(id).Description2 = 'Description of condition 2';
% stimData(id).NumParams = 2;
% stimData(id).Params = init_params_struct(stimData,id);
% stimData(id).Params(1).Label = 'Label for parameter 1';
% stimData(id).Params(1).Value = 1.1;
% stimData(id).Params(2).Label = 'Label for parameter 2';
% stimData(id).Params(2).Value = 2.2;



% How to add two radiobuttons.
%{
stimData(id).Params(5).Style = 'radiobutton';
stimData(id).Params(5).Label = 'test1';
stimData(id).Params(5).Value = true;
stimData(id).Params(5).Callback = {@here,5:6,5};
stimData(id).Params(6).Style = 'radiobutton';
stimData(id).Params(6).Label = 'test2';
stimData(id).Params(6).Value = false;
stimData(id).Params(6).Callback = {@here,5:6,6};
	function here(~,~,kk,k)
		h = arrayfun(@(i)stimData(id).Params(i).ValueH,kk);
		[h.Value] = deal(false);
		stimData(id).Params(k).ValueH.Value = true;
	end
%}

% End of definition of controls for each stimulus type.
%------------------------------------------------------


% Create the stimulus parameter panels and their controls.
%---------------------------------------------------------
% Each stimulus type gets its own panel containing parameters, only one of which
% is visible at a time.
for spi = 1:numOptions
	% Create the panel for this stimulus type.
	stimData(spi).Panel = uipanel('Parent',fig,...
		'Units','pixels',...
		'Position',[0,392,param_width,max(fig_wh(2)-35-20-392,0)],...
		'Title',sprintf('%s Parameters',stimData(spi).Type),...
		'Visible','off');
	
	% Create the controls and their labels.
	for spj = 1:stimData(spi).NumParams
		% Compute the 'y' coordinate of the uicontrols.
		y = stimData(spi).Panel.Position(4) - 40 - ...
			(stimData(spi).Params(spj).Row - 1)*25;
		
		% Determine parameter style.
		if ~isempty(stimData(spi).Params(spj).Style)
			% Use the Style field if it's not empty.
			style = stimData(spi).Params(spj).Style;
		else
			% If the Style field is empty, infer the style from other
			% information.
			if ~isempty(stimData(spi).Params(spj).Choices)
				style = 'popupmenu';
			elseif isnumeric(stimData(spi).Params(spj).Value)
				style = 'numeric';
			elseif islogical(stimData(spi).Params(spj).Value)
				style = 'checkbox';
			elseif ischar(stimData(spi).Params(spj).Value)
				style = 'string';
			elseif isstring(stimData(spi).Params(spj).Value)
				style = 'string';
			end
		end
		
		% Create the uicontrol(s).
		switch style
			case 'string'
				% Create the label text uicontrol.
				stimData(spi).Params(spj).LabelH = uicontrol(...
					'Parent',stimData(spi).Panel,...
					'Style','text',...
					'Units','pixels',...
					'Position',[20,y,100,0] + text_adj,...
					'String',stimData(spi).Params(spj).Label,...
					Tooltip,stimData(spi).Params(spj).Tooltip);
				
				% Adjust label width.
				stimData(spi).Params(spj).LabelH.Position(3) = ...
					stimData(spi).Params(spj).LabelH.Extent(3);
				
				% Create the edit uicontrol.
				stimData(spi).Params(spj).ValueH = uicontrol(...
					'Parent',stimData(spi).Panel,...
					'Style','edit',...
					'Units','pixels',...
					'Position',[param_width - 120,y,100,0] + edit_adj,...
					'String',stimData(spi).Params(spj).Value,...
					'Callback',stimData(spi).Params(spj).Callback,...
					'ButtonDownFcn',stimData(spi).Params(spj).ButtonDownFcn,...
					Tooltip,stimData(spi).Params(spj).Tooltip);
				
			case 'numeric'
				% Create the label text uicontrol.
				stimData(spi).Params(spj).LabelH = uicontrol(...
					'Parent',stimData(spi).Panel,...
					'Style','text',...
					'Units','pixels',...
					'Position',[20,y,100,0] + text_adj,...
					'String',stimData(spi).Params(spj).Label,...
					Tooltip,stimData(spi).Params(spj).Tooltip);
				
				% Adjust label width.
				stimData(spi).Params(spj).LabelH.Position(3) = ...
					stimData(spi).Params(spj).LabelH.Extent(3);
				
				% Create the edit uicontrol.
				stimData(spi).Params(spj).ValueH = uicontrol(...
					'Parent',stimData(spi).Panel,...
					'Style','edit',...
					'Units','pixels',...
					'Position',[param_width - 120,y,100,0] + edit_adj,...
					'String',strjoin(arrayfun(@(x){num2str(x)},...
					stimData(spi).Params(spj).Value)),...
					'Callback',stimData(spi).Params(spj).Callback,...
					'ButtonDownFcn',stimData(spi).Params(spj).ButtonDownFcn,...
					Tooltip,stimData(spi).Params(spj).Tooltip);
				
			case 'checkbox'
				% Create the checkbox.
				stimData(spi).Params(spj).ValueH = uicontrol(...
					'Parent',stimData(spi).Panel,...
					'Style','checkbox',...
					'Units','pixels',...
					'Position',[20,y,100,0] + check_adj,...
					'String',stimData(spi).Params(spj).Label,...
					'Value',stimData(spi).Params(spj).Value,...
					'Callback',stimData(spi).Params(spj).Callback,...
					'ButtonDownFcn',stimData(spi).Params(spj).ButtonDownFcn,...
					Tooltip,stimData(spi).Params(spj).Tooltip);
				
				% Adjust checkbox width.
				stimData(spi).Params(spj).ValueH.Position(3) = ...
					stimData(spi).Params(spj).ValueH.Extent(3) + 25;
				
			case 'radiobutton'
				% Create the radiobutton.
				stimData(spi).Params(spj).ValueH = uicontrol(...
					'Parent',stimData(spi).Panel,...
					'Style','radiobutton',...
					'Units','pixels',...
					'Position',[20,y,100,0] + check_adj,...
					'String',stimData(spi).Params(spj).Label,...
					'Value',stimData(spi).Params(spj).Value,...
					'Callback',stimData(spi).Params(spj).Callback,...
					'ButtonDownFcn',stimData(spi).Params(spj).ButtonDownFcn,...
					Tooltip,stimData(spi).Params(spj).Tooltip);
				
				% Adjust radiobutton width.
				stimData(spi).Params(spj).ValueH.Position(3) = ...
					stimData(spi).Params(spj).ValueH.Extent(3) + 25;
				
			case 'popupmenu'
				% Create the label text uicontrol.
				stimData(spi).Params(spj).LabelH = uicontrol(...
					'Parent',stimData(spi).Panel,...
					'Style','text',...
					'Units','pixels',...
					'Position',[20,y,100,0] + text_adj,...
					'String',stimData(spi).Params(spj).Label,...
					Tooltip,stimData(spi).Params(spj).Tooltip);
				
				% Adjust label width.
				stimData(spi).Params(spj).LabelH.Position(3) = ...
					stimData(spi).Params(spj).LabelH.Extent(3);
				
				% Create the popupmenu.
				choices = stimData(spi).Params(spj).Choices;
				max_chars = max(cellfun(@length,choices)) + 2;
				choices = cellfun(@(x){sprintf('%*s',-max_chars,x)},choices);
				stimData(spi).Params(spj).ValueH = uicontrol(...
					'Parent',stimData(spi).Panel,...
					'Style','popupmenu',...
					'Units','pixels',...
					'Position',[param_width - 150,y,130,0] + popup_adj,...
					'String',choices,...
					'Value',stimData(spi).Params(spj).Value,...
					'Callback',stimData(spi).Params(spj).Callback,...
					'ButtonDownFcn',stimData(spi).Params(spj).ButtonDownFcn,...
					Tooltip,stimData(spi).Params(spj).Tooltip);
				
				% Adjust popupmenu width.
				width = stimData(spi).Params(spj).ValueH.Extent(3) + 60;
				stimData(spi).Params(spj).ValueH.Position([1 3]) = ...
					[param_width - width - 20,width];
				
		end
	end
end

% Initialize any controls that need it.  This has to be done here because prior
% to this the affected uicontrols do not exist.
%--------------------------------------------------------------------------
% Initialize whether the frequency control is displayed.
show_freqs(stimData(8).Params(7).ValueH)

% Set TIN SNR value control to be inactive so you can't type in it.
stimData(4).Params(6).ValueH.Enable = 'inactive';

% Initialize SNR field.
parse_TIN_BW()
%--------------------------------------------------------------------------
% End of Stimulus parameter panels.
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% Create the Model Parameters panel and its controls.
%--------------------------------------------------------------------------

% Set the vertical separation between rows of controls, and an anonymous
% function to compute the height within the panel of a control with a specified
% row number.  Rows are numbered from the bottom and need not be integers.
vertical_spacing = 28;
height = @(row)10 + (row - 1)*vertical_spacing;

% Create panel for model parameters.
modelParamPanel = uipanel(fig,...
	'Units','pixels',...
	'Position',[0,90,param_width,height(10+2/3)+20],...
	'Title','Model Parameters');

%--------------------------------------------------------------------------

% When adding an AN model, add it here.  ANmodelTypeOptions are the strings that
% appear in the popup menu.
ANmodelTypeOptions = {'Zilany, Bruce & Carney 2014',...
	'Bruce, Erfani & Zilany 2018'};

% Create AN model popup menu label.
AN_model_label = uicontrol(modelParamPanel,...
	'Style','text',...
	'Units','pixels',...
	'Position',[15,height(9+2/3),40,0] + text_adj,...
	'String','AN: ',...
	'HorizontalAlignment','left',...
	'FontWeight','bold');
AN_model_label.Position(3) = AN_model_label.Extent(3);

% Create AN model popup menu.
AN_model_popup = uicontrol(modelParamPanel,...
	'Style','popupmenu',...
	'Units','pixels',...
	'Position',[15+AN_model_label.Extent(3),height(9+2/3),200,0] + popup_adj,...
	'String',ANmodelTypeOptions,...
	'Value',Which_AN,...
	'Callback',@select_AN_model);
AN_model_popup.Position(3) = param_width - 15 - AN_model_popup.Position(1);

% Create controls for each AN model choice (if any).
% Only the second AN model has an additional parameter, number of fibers.
% The visiblity of these controls is set in the callback for AN_model_popup.
num_fibers_label = uicontrol(modelParamPanel,...
	'Style','text',...
	'Units','pixels',...
	'Position',[25,height(8+2/3),200,0] + text_adj,...
	'String','Number of fibers in each CF:',...
	'HorizontalAlignment','left');
num_fibers_label.Position(3) = num_fibers_label.Extent(3);

num_fibers_edit = uicontrol(modelParamPanel,...
	'Style','edit',...
	'Units','pixels',...
	'Position',[25+num_fibers_label.Extent(3),height(8+2/3),40,0] + edit_adj,...
	'String','1');


% Hearing loss section of Model Parameters panel.
%--------------------------------------------------------------------------
% OHC input text on GUI.
hl_label1 = uicontrol(modelParamPanel,...
	'Style','text',...
	'Units','pixels',...
	'Position',[25,height(7+2/3),200,0] + text_adj,...
	'String','Audiogram  (dbHL):',...
	'HorizontalAlignment','left');
hl_label2 = uicontrol(modelParamPanel,...
	'Style','text',...
	'Units','pixels',...
	'Position',[25,height(7),200,-2] + text_adj,...
	'String','Frequency (kHz):',...
	'HorizontalAlignment','left');
hl_width = max(hl_label1.Extent(3),hl_label2.Extent(3));
hl_label1.Position(3) = hl_width;
hl_label2.Position(3) = hl_width;

OHCEdit = gobjects(1,7);
for i = 1:7
	OHCEdit(i) = uicontrol(modelParamPanel,...
		'Style','edit',...
		'Units','pixels',...
		'Position',[25+hl_width+25*(i-1),height(7+2/3),24,0] + edit_adj,...
		'String','0',...
		'HorizontalAlignment','center');
end

% Frequency labels.
% 1/8, 1/4, 1/2, 1, 2, 4, 8.
freq_labels = {char(8539),char(188),char(189),'1','2','4','8'};
for i = 1:7
	uicontrol(modelParamPanel,...
		'Style','text',...
		'Units','pixels',...
		'Position',[25+hl_width+25*(i-1),height(7),24,-2] + text_adj,...
		'String',freq_labels{i},...
		'HorizontalAlignment','center')
end


% CF Range section of Model Parameters panel.
%--------------------------------------------------------------------------
CFEditLo_label = uicontrol(modelParamPanel,...
	'Style','text',...
	'Units','pixels',...
	'Position',[25,height(6),200,0] + text_adj,...
	'HorizontalAlignment','left',...
	'String','CF Range (Hz):');

CFEditLo = uicontrol(modelParamPanel,...
	'Style','edit',...
	'Units','pixels',...
	'Position',[25 + CFEditLo_label.Extent(3),height(6),60,0] + edit_adj,...
	'String',sprintf('%g',cfRange(1)));

x = sum(CFEditLo.Position([1 3]));
CFEditHi_label = uicontrol(modelParamPanel,...
	'Style','text',...
	'Units','pixels',...
	'Position',[x,height(6),50,0] + text_adj,...
	'HorizontalAlignment','left',...
	'String',' to ');

CFEditHi = uicontrol(modelParamPanel,...
	'Style','edit',...
	'Units','pixels',...
	'Position',[x + CFEditHi_label.Extent(3),height(6),60,0] + edit_adj,...
	'String',sprintf('%g',cfRange(2)));


% Number of CFs section of Model Parameters panel.
%--------------------------------------------------------------------------
numFibersEdit_label = uicontrol(modelParamPanel,...
	'Style','text',...
	'Units','pixels',...
	'Position',[25,height(5),200,0] + text_adj,...
	'HorizontalAlignment','left',...
	'String','Number of CFs:');

numCFEdit = uicontrol(modelParamPanel,...
	'Style','edit',...
	'Units','pixels',...
	'Position',[25+numFibersEdit_label.Extent(3),height(5),50,0] + edit_adj,...
	'String','20');


% AN Species section of Model Parameters panel.
%--------------------------------------------------------------------------
speciesTypePopup_label = uicontrol(modelParamPanel,...
	'Style','text',...
	'Units','pixels',...
	'Position',[25,height(4),200,0] + text_adj,...
	'HorizontalAlignment','left',...
	'String','AN Species:');

% Default value set to 2 (Human).
speciesTypePopup = uicontrol(modelParamPanel,...
	'Style','popupmenu',...
	'Units','pixels',...
	'Position',[25+speciesTypePopup_label.Extent(3),height(4),180,0] + popup_adj,...
	'String',{'Cat','Human (Shera tuning)'},...
	'Value',2);

% AN spontaneous rate section of Model Parameters panel.
%--------------------------------------------------------------------------
spont_rate_label = uicontrol(modelParamPanel,...
	'Style','text',...
	'Units','pixels',...
	'Position',[25,height(3),200,0] + text_adj,...
	'HorizontalAlignment','left',...
	'String','AN Spont rate:');

spontTypePopup = uicontrol(modelParamPanel,...
	'Style','popupmenu',...
	'Units','pixels',...
	'Position',[25+spont_rate_label.Extent(3),height(3),100,0] + popup_adj,...
	'String',{'Low','Med','High'},...
	'Value',3); % DEFAULT VALUE SET TO 3 (High spont)

%--------------------------------------------------------------------------

% When adding an IC model, add it here.  ICmodelTypeOptions are the strings that
% appear in the popup menu.  When a selection is made, the Tooltip string of the
% popup menu is set to the corresponding IC_model_credits string.
ICmodelTypeOptions = {'SFIE Model','AN Modulation Filter Model'};
IC_model_credits = {'Nelson & Carney, 2004; Carney et al, 2015',...
	'Mao et al, 2013'};
num_IC_options = length(ICmodelTypeOptions);

% Create IC model popup menu label.
IC_model_label = uicontrol(modelParamPanel,...
	'Style','text',...
	'Units','pixels',...
	'Position',[15,height(2),40,0] + text_adj,...
	'String','IC: ',...
	'HorizontalAlignment','left',...
	'FontWeight','bold');
IC_model_label.Position(3) = IC_model_label.Extent(3);

% Create IC model popup menu.
IC_model_popup = uicontrol(modelParamPanel,...
	'Style','popupmenu',...
	'Units','pixels',...
	'Position',[15+IC_model_label.Extent(3),height(2),200,0] + popup_adj,...
	'String',ICmodelTypeOptions,...
	'Value',Which_IC,...
	'Callback',@select_IC_model);
IC_model_popup.Position(3) = param_width - 15 - IC_model_popup.Position(1);

% Create cell arrays for the IC model options input data and their labels.
IC_data_edit = cell(1,num_IC_options);
IC_data_labels = cell(1,num_IC_options);

% Define input edit boxes and labels for option 1.
IC_data_labels{1} = uicontrol(modelParamPanel,...
	'Style','text',...
	'Units','pixels',...
	'Position',[25,height(1),300,0] + text_adj,...
	'String','BMF (Hz):',...
	'HorizontalAlignment','left');
IC_data_labels{1}.Position(3) = IC_data_labels{1}.Extent(3);

BMF = 100;
IC_data_edit{1} = uicontrol(modelParamPanel,...
	'Style','edit',...
	'Units','pixels',...
	'Position',[25+IC_data_labels{1}.Extent(3),height(1),60,0] + edit_adj,...
	'String',num2str(BMF),...
	'HorizontalAlignment','center');


% Define input edit boxes and labels for option 2.
IC_data_labels{2} = uicontrol(modelParamPanel,...
	'Style','text',...
	'Units','pixels',...
	'Position',[25,height(1),300,0] + text_adj,...
	'String','BMF (Hz):',...
	'HorizontalAlignment','left');
IC_data_labels{2}.Position(3) = IC_data_labels{2}.Extent(3);

BMF = 100;
IC_data_edit{2} = uicontrol(modelParamPanel,...
	'Style','edit',...
	'Units','pixels',...
	'Position',[25+IC_data_labels{2}.Extent(3),height(1),60,0] + edit_adj,...
	'String',num2str(BMF),...
	'HorizontalAlignment','center');


%--------------------------------------------------------------------------
% End of Model Parameters panel.
%--------------------------------------------------------------------------


% Create Run button and associated controls.
%--------------------------------------------------------------------------
PSTH_CFedit_label = uicontrol(fig,...
	'Style','text',...
	'Units','pixels',...
	'Position',[20,55,200,0] + text_adj,...
	'HorizontalAlignment','left',...
	'String','CF for AN & IC PSTHs (Hz):');

PSTH_CFedit = uicontrol(fig,...
	'Style','edit',...
	'Units','pixels',...
	'Position',[20 + PSTH_CFedit_label.Extent(3),55,55,0] + edit_adj,...
	'String','500');

% Quickplot pushbutton.
uicontrol(fig,...
	'Style','pushbutton',...
	'Units','pixels',...
	'Position',[param_width-90,55,70,0] + button_adj,...
	'String','Quickplot',...
	'Callback',@quickplot);

% Run button.
run_button = uicontrol(fig,...
	'Style','pushbutton',...
	'Units','pixels',...
	'Position',[20,20,180,0] + button_adj,...
	'String','Run',...
	'Callback',@run);

% Save data pushbutton.
uicontrol(fig,...
	'Style','pushbutton',...
	'Units','pixels',...
	'Position',[param_width-110,20,90,0] + button_adj,...
	'String',sprintf('Save Data%c',8230),... % ellipsis
	'Callback',@save_data);

try
	% Create a waitbar-like object.
	wb = uibar('Parent',fig,...
		'Units','pixels',...
		'Position',[1 1 param_width-2 15],...
		'Min',0,...
		'Max',1,...
		'Value',0,...
		'Visible','off');
catch
	% If the version of MATLAB being used does not work with the uibar class,
	% simply create a structure and all attempts to set properties of it will do
	% nothing.
	wb = struct('Value',0);
end


% Create info panel above graphs and its contents.
%--------------------------------------------------------------------------
info_panel_width = fig_wh(1) - param_width;
info_panel_pos = [param_width,fig_wh(2)-60,info_panel_width,60];
info_panel = uipanel('Parent',fig,...
	'Units','pixels',...
	'Position',info_panel_pos,...
	'BorderType','none');

stim_type_title = uicontrol(info_panel,...
	'Style','text',...
	'Units','pixels',...
	'Position',[10,17,180,25],...
	'String','',...
	'HorizontalAlignment','left',...
	'FontSize',bigfont);

colors = {[0 0.7 0],[0 0 1],[1 0 0]}; % GBR

condition_string1 = uicontrol(info_panel,...
	'Style','text',...
	'Units','pixels',...
	'Position',[300,30,200,0] + text_adj,...
	'String','C1: ',...
	'HorizontalAlignment','left',...
	'ForegroundColor',colors{1},...
	'FontSize',bigfont);

condition_string2 = uicontrol(info_panel,...
	'Style','text',...
	'Units','pixels',...
	'Position',[300,5,200,0] + text_adj,...
	'String','C2: ',...
	'HorizontalAlignment','left',...
	'ForegroundColor',colors{2},...
	'FontSize',bigfont);

play_c1_button = uicontrol('Parent',info_panel,...
	'Units','pixels',...
	'Position',[200,30,80,0] + button_adj,...
	'String','Play C1',...
	'Callback',@play_cond1_stim); %#ok<NASGU>

play_c2_button = uicontrol('Parent',info_panel,...
	'Units','pixels',...
	'Position',[200,5,80,0] + button_adj,...
	'String','Play C2',...
	'Callback',@play_cond2_stim,...
	'Visible','off');

updates_button = uicontrol('Parent',info_panel,...
	'Units','pixels',...
	'Position',[400,30,100,0] + button_adj,...
	'String',sprintf('Updates%c',8230),... % 8230 = ellipsis
	'Callback',{@updates_dialog,program,version,fig});
updates_button.Position(3) = updates_button.Extent(3) + 10;

tips_button = uicontrol('Parent',info_panel,...
	'Units','pixels',...
	'Position',[400,5,100,0] + button_adj,...
	'String',sprintf('Tips%c',8230),... % 8230 = ellipsis
	'Callback',{@tips_window,fig});
tips_button.Position(3) = updates_button.Position(3);



% Wide display on/off checkbox.
%--------------------------------------------------------------------------
wide_display_cb = uicontrol(fig,...
	'Style','checkbox',...
	'Units','pixels',...
	'Position',[param_width+0,10,100,0] + check_adj,...
	'String','Wide display',...
	'Value',0,...
	'Callback',@wide_display);
wide_display_cb.Position(3) = wide_display_cb.Extent(3) + 22;

% Create documentation note below figures.
%--------------------------------------------------------------------------
doc_note = uicontrol(fig,...
	'Style','text',...
	'Units','pixels',...
	'Position',[param_width,5,fig_wh(1)-param_width,0] + text_adj,...
	'String',['Click on a plot to toggle conditions; ',...
	'right-click to "detach" plot.'],...
	'HorizontalAlignment','center');



% Create output panel and contents for "narrow" plots.
%--------------------------------------------------------------------------
% Create panel for narrow response plots.
out_panel_pos = [param_width,30,fig_wh(1)-param_width,fig_wh(2)-90];
output_panel_n = uipanel(fig,...
	'Units','pixels',...
	'Position',out_panel_pos,...
	'BorderType','none');

% Narrow waveform plot.
wav_axes_n = axes(output_panel_n,...
	'Units','normalized',...
	'OuterPosition',[0,2/3,1/3,1/3]);
stim_wav_line = line(wav_axes_n,'XData',NaN,'YData',NaN,'HitTest','off');
selected_line = [];
analysis_window_hold = false;
analysis_window_lines = gobjects(1,2);
analysis_window_lines(1) = line(wav_axes_n,...
	'XData',[1 1]*aw_t(1),...
	'YData',[0 1],...
	'Color',selection_line_color,...
	'ButtonDownFcn',{@sel_line_down,1},...
	'Clipping','off',...
	'Visible','off',...
	'Tag','delete when detached');
analysis_window_lines(2) = line(wav_axes_n,...
	'XData',[1 1]*aw_t(2),...
	'YData',[0 1],...
	'Color',selection_line_color,...
	'ButtonDownFcn',{@sel_line_down,2},...
	'Clipping','off',...
	'Visible','off',...
	'Tag','delete when detached');
ylabel('Amplitude (Pa)')
xlabel('Time (s)')
box on
wav_axes_n.ButtonDownFcn = @next_wave;
wav_axes_n.Visible = 'off';
make_detachable(wav_axes_n)

% Add annotations to waveform plot.
wav_anno_ax = axes(output_panel_n,...
	'Units','pixels',...
	'Position',[0 0 200 50],...
	'Color','w',...
	'XLim',[0 200],...
	'YLim',[0 50],...
	'Visible','off');
common_annotation_props = struct('Units','pixels',...
	'FontName',font_name,...
	'FontSize',font_size,...
	'HorizontalAlignment','left',...
	'VerticalAlignment','bottom',...
	'Visible','off');
reset_text = text(common_annotation_props,...
	'Position',[0 0],...
	'String','Reset',...
	'Color','b',...
	'ButtonDownFcn',@reset_selection);
reset_width = reset_text.Extent(3);
text_spacing = 1.2*reset_text.Extent(4);
help_text = text(common_annotation_props,...
	'Position',[0 text_spacing],...
	'String','Help',...
	'Color','b',...
	'ButtonDownFcn',{@help_window,fig});
help_width = help_text.Extent(3);
analysis_window_text = text(common_annotation_props,...
	'Position',[0 2*text_spacing],...
	'String','Analysis Window',...
	'ButtonDownFcn',@set_analysis_window);
aw_width = analysis_window_text.Extent(3);

% Underlines for text items above.  Initially invisible, made visible when
% wav_axes_n is made visible.
tal = gobjects(1,3); % text annotation lines
tal_props = struct('Color','b','LineWidth',1,'Visible','off');
tal(1) = line([0 reset_width],[0 0],tal_props);
tal(2) = line([0 help_width],text_spacing*[1 1],tal_props);
tal(3) = line([0 aw_width],2*text_spacing*[1 1],tal_props);
wav_anno_ax.Position(4) = 3*text_spacing;
wav_anno_ax.YLim(2) = 3*text_spacing;
text_annotations = [analysis_window_text,help_text,reset_text,tal];

% Narrow spectrogram plot.
specgram_axes_n = axes(output_panel_n,...
	'Units','normalized',...
	'OuterPosition',[0,1/3,1/3,1/3]);
specgram_surf = surface(specgram_axes_n,0,0,0,...
	'FaceColor','interp',...
	'EdgeColor','none',...
	'HitTest','off');
ylabel('Frequency (Hz)')
specgram_axes_n.ButtonDownFcn = @next_specgram;
specgram_axes_n.Visible = 'off';
make_detachable(specgram_axes_n)

% Narrow spectrum plot.
spec_axes_n = axes(output_panel_n,...
	'Units','normalized',...
	'OuterPosition',[0,0,1/3,1/3]);
spec_line = plot(spec_axes_n,NaN,NaN,'HitTest','off');
ylabel('Magnitude (dB SPL)')
xlabel('Frequency (Hz)')
grid on
spec_axes_n.ButtonDownFcn = @next_spec;
spec_axes_n.Visible = 'off';
make_detachable(spec_axes_n)

% Narrow AN response plot.
AN_axes_n = axes(output_panel_n,...
	'Units','normalized',...
	'OuterPosition',[1/3,1/2,1/3,1/3],...
	'Visible','off');
AN_surf_n = surface(AN_axes_n,0,0,0,...
	'FaceColor','interp',...
	'EdgeColor','none',...
	'HitTest','off');
xlabel('Time (s)')
ylabel('AN BF (Hz)')
AN_axes_n.TickDir = 'out';
AN_axes_n.ButtonDownFcn = @next_AN_model;
AN_model_cb = colorbar('Visible','off');
title(AN_model_cb,'sp/s');
make_detachable(AN_axes_n)

% Narrow IC response plot.
IC_axes_n = axes(output_panel_n,...
	'Units','normalized',...
	'OuterPosition',[1/3,1/6,1/3,1/3],...
	'Visible','off');
IC_surf_n = surface(IC_axes_n,0,0,0,...
	'FaceColor','interp',...
	'EdgeColor','none',...
	'HitTest','off');
ylabel('IC BF (Hz)')
xlabel('Time (s)')
IC_axes_n.TickDir = 'out';
IC_axes_n.ButtonDownFcn = @next_IC_model;
IC_model_cb = colorbar('Visible','off');
title(IC_model_cb,'sp/s');
make_detachable(IC_axes_n)

% Narrow AN average response plot.
AN_avg_axes = axes(output_panel_n,...
	'Units','normalized',...
	'OuterPosition',[2/3,2/3,1/3,1/3]);
AN_avg_lines = plot(AN_avg_axes,NaN,NaN,NaN,NaN,'HitTest','off');
for jj = 1:2
	AN_avg_lines(jj).Color = colors{jj};
	AN_avg_lines(jj).LineWidth = 2;
end
ylabel('Ave. Rate (sp/s)')
xlabel('AN BF (Hz)')
title('AN Ave. Rate')
grid on
AN_avg_axes.XTick = [100 200 500 1000 2000 5000 10000];
AN_avg_axes.ButtonDownFcn = @next_AN_avg;
AN_avg_axes.Visible = 'off';
make_detachable(AN_avg_axes)

% Narrow CN average response plot.
CN_avg_axes = axes(output_panel_n,...
	'Units','normalized',...
	'OuterPosition',[2/3,1/3,1/3,1/3]);
CN_avg_lines = plot(CN_avg_axes,NaN,NaN,NaN,NaN,'HitTest','off');
for jj = 1:2
	CN_avg_lines(jj).Color = colors{jj};
	CN_avg_lines(jj).LineWidth = 2;
end
ylabel('Ave. Rate (sp/s)')
xlabel('CN BF (Hz)')
title('CN Ave. Rate')
grid on
CN_avg_axes.XTick = [100 200 500 1000 2000 5000 10000];
CN_avg_axes.ButtonDownFcn = @next_CN_avg;
CN_avg_axes.Visible = 'off';
make_detachable(CN_avg_axes)

% Narrow IC average response plot.
IC_avg_axes = axes(output_panel_n,...
	'Units','normalized',...
	'OuterPosition',[2/3,0,1/3,1/3],...
	'Visible','off');
IC_avg_lines = plot(IC_avg_axes,NaN,NaN,NaN,NaN,'HitTest','off');
for jj = 1:2
	IC_avg_lines(jj).Color = colors{jj};
	IC_avg_lines(jj).LineWidth = 2;
end
ylabel('Ave. Rate (sp/s)')
xlabel('IC BF (Hz)')
grid on
IC_avg_axes.XTick = [100 200 500 1000 2000 5000 10000];
% IC_response_avg.ButtonDownFcn = @next_IC_avg;
IC_avg_axes.Visible = 'off';
make_detachable(IC_avg_axes)

% Collect all narrow axes in one array and set the Units to 'pixels'.
narrow_axes = [wav_axes_n,specgram_axes_n,spec_axes_n,AN_axes_n,IC_axes_n,...
	AN_avg_axes,CN_avg_axes,IC_avg_axes];
set(narrow_axes,'Units','pixels')

% BE/BS radio buttons to switch IC average response plot.
ref_pos = IC_avg_axes.Position(1:2);
be_bs_radio = gobjects(1,2);
be_bs_radio(1) = uicontrol(output_panel_n,...
	'Style','radiobutton',...
	'Position',[ref_pos(1)-55,ref_pos(2)+30,40,0] + check_adj,...
	'String','BE',...
	'Value',be_bs_selection == 1,...
	'Callback',{@handle_be_bs_radio,1},...
	'Visible','off');
be_bs_radio(1).Position(3) = be_bs_radio(1).Extent(3) + radio_cb_width;
be_bs_radio(2) = uicontrol(output_panel_n,...
	'Style','radiobutton',...
	'Position',[ref_pos(1)-55,ref_pos(2)+5,40,0] + check_adj,...
	'String','BS',...
	'Value',be_bs_selection == 2,...
	'Callback',{@handle_be_bs_radio,2},...
	'Visible','off');
be_bs_radio(2).Position(3) = be_bs_radio(2).Extent(3) + radio_cb_width;

%--------------------------------------------------------------------------


% Create output panel and contents for "wide" plots.
%--------------------------------------------------------------------------
% Create panel for wide response plots.
output_panel_w = uipanel(fig,...
	'Units','pixels',...
	'Position',out_panel_pos,...
	'BorderType','none',...
	'Visible','off');

% Wide stimulus waveform plot.
wav_axes_w = axes(output_panel_w,...
	'Units','normalized',...
	'OuterPosition',[0,4/5,1,1/5],...
	'Visible','off');
stim_wav_line_w = plot(wav_axes_w,NaN,NaN,'HitTest','off');
ylabel('Amplitude (Pa)')
% xlabel('Time (s)')
% wav_axes_w.ButtonDownFcn = @next_wave_w;
wav_axes_w.ButtonDownFcn = @next_wide_plots;
wav_axes_w.Visible = 'off';
make_detachable(wav_axes_w)

% Wide spectrogram plot.
specgram_axes_w = axes(output_panel_w,...
	'Units','normalized',...
	'OuterPosition',[0,3/5,1,1/5],...
	'Visible','off');
specgram_surf_w = surface(specgram_axes_w,0,0,0,...
	'FaceColor','interp',...
	'EdgeColor','none',...
	'HitTest','off');
ylabel('Frequency (Hz)')
% specgram_axes_w.ButtonDownFcn = @next_specgram_w;
specgram_axes_w.ButtonDownFcn = @next_wide_plots;
specgram_axes_w.Visible = 'off';
make_detachable(specgram_axes_w)

% Wide VIHC plot.
VIHC_axes_w = axes(output_panel_w,...
	'Units','normalized',...
	'OuterPosition',[0,2/5,1,1/5],...
	'Visible','off');
VIHC_surf_w = surface(VIHC_axes_w,0,0,0,...
	'FaceColor','interp',...
	'EdgeColor','none',...
	'HitTest','off');
ylabel('IHC BF (Hz)')
VIHC_axes_w.TickDir = 'out';
% VIHC_axes_w.ButtonDownFcn = @next_VIHC_w;
VIHC_axes_w.ButtonDownFcn = @next_wide_plots;
VIHC_axes_w.Visible = 'off';
caxis(VIHC_axes_w,[-5 15]); % mV, based on 75 dB SPL speech
VIHC_cb = colorbar('Visible','off');
title(VIHC_cb,'mV');
make_detachable(VIHC_axes_w)
		
% Wide AN model response plot.
AN_axes_w = axes(output_panel_w,...
	'Units','normalized',...
	'OuterPosition',[0,1/5,1,1/5],...
	'Visible','off');
AN_surf_w = surface(AN_axes_w,0,0,0,...
	'FaceColor','interp',...
	'EdgeColor','none',...
	'HitTest','off');
ylabel('AN BF (Hz)')
AN_axes_w.TickDir = 'out';
% AN_axes_w.ButtonDownFcn = @next_AN_model_w;
AN_axes_w.ButtonDownFcn = @next_wide_plots;
AN_model_cb_w = colorbar('Visible','off');
title(AN_model_cb_w,'sp/s');
make_detachable(AN_axes_w)

% Wide IC model response plot.
IC_axes_w = axes(output_panel_w,...
	'Units','normalized',...
	'OuterPosition',[0,0,1,1/5],...
	'Visible','off');
IC_surf_w = surface(IC_axes_w,0,0,0,...
	'FaceColor','interp',...
	'EdgeColor','none',...
	'HitTest','off');
xlabel('Time (s)')
ylabel('IC BF (Hz)')
IC_axes_w.TickDir = 'out';
% IC_response_time_wide.ButtonDownFcn = @next_IC_model_w;
IC_axes_w.ButtonDownFcn = @next_wide_plots;
IC_model_cb_w = colorbar('Visible','off');
title(IC_model_cb_w,'sp/s');
make_detachable(IC_axes_w)

% Collect all wide axes in one array and set the Units to 'pixels'.
wide_axes = [wav_axes_w,specgram_axes_w,VIHC_axes_w,AN_axes_w,IC_axes_w];
set(wide_axes,'Units','pixels')
%--------------------------------------------------------------------------


% Display the parameter panel for the initial stimulus selection.
stimData(stimIdx).Panel.Visible = 'on';

% Run AN and IC model callback functions to set up initial states.
select_AN_model()
select_IC_model()

% Make figure visible and hide its handle.
fig.Visible = 'on';
fig.HandleVisibility = 'off';

show_tips = getpref('UR_EAR','show_tips',true);
if show_tips
	tips_window([],[],fig)
end


%--------------------------------------------------------------------------
%
%                   Callback functions
%
%--------------------------------------------------------------------------

	function run(~,~)  % Create stimuli and then run the model
		% Callback for Run button.  Compute stimuli then call function to
		% compute the model results and plot them.
		
		% Import all functions in the stimuli package (contents of the +stimuli
		% folder) so they can be called by name, e.g., TIN(), rather than having
		% to use the full package name, e.g., stimuli.TIN().
		import stimuli.*
		
		% Disable Run button and set pointer to 'watch'.
		run_button.Enable = 'off';
		fig.Pointer = 'watch';
		
		% Display the appropriate output panel.
		if wide_display_cb.Value
			output_panel_w.Visible ='on';
		else
			output_panel_w.Visible ='off';
		end
		
		% Initialize Condition.
		Condition = struct('stimulus',cell(1,2));
		
		% Get a temporary copy of the Params field for the current stimulus type
		% to simplify getting parameters.
		params = stimData(stimIdx).Params;
		
		% STIM: Each switch case is for a stimulus type, and gets input
		% parameters from the GUI, and then calls a function to create the
		% waveform(s).  Add a new case (with a new value for stimIdx) by using
		% one of the existing ones as a template.
		% If your new stimus is an audio file, the program does not need to be
		% edited, simply use case 1.
		switch stimIdx
			case 1 % Audio File
				% Note: stimulus duration is computed from file, and no ramp is applied.
				
				% Get parameters.
				spl = str2double(params(1).ValueH.String);
				path1 = params(2).Data;
				path2 = params(3).Data;
				noise_SNR = str2double(params(4).ValueH.String);
				ltass_ramp_dur = 0.010; % s

				% Set number of conditions.
				nconditions = 1;
				
				% Read first audio file, scale to desired RMS level, resample
				% waveform to sampling rate required for AN model, and store in
				% Condition.
				[wav1,Fs_wav1] = audioread(path1);
				if ~isnan(spl)
					wav1 = wav1*(Pref*10.^(spl/20)/rms(wav1));
				end
				Condition(1).stimulus = resample(wav1,Fs,Fs_wav1).';
				num_pts1 = length(Condition(1).stimulus);
				
				% Add LTASS noise.
				if noise_SNR > -Inf
					% Note that ramp is applied after noise is added and no ramp
					% is used for audio file alone.
					% Make wideband LTASS noise (100 Hz - 6 kHz).
					if isnan(spl)
						ltass_SPL = noise_SNR;
					else
						ltass_SPL = spl - noise_SNR;
					end
					% Note: function modified to handle Fs = 100 kHz.
					ltass_noise1 = ltass_noise0(Fs,ltass_SPL,num_pts1,1);
					ltass_dur1 = num_pts1/Fs;
					ramp1 = tukeywin(num_pts1, 2*ltass_ramp_dur/ltass_dur1);
					ltass_noise1 = ltass_noise1.*ramp1;
					Condition(1).stimulus = Condition(1).stimulus + ltass_noise1(:).';
				end
				
				if ~isempty(path2)
					% If second file name is entered, responses to both
					% waveforms will be compared.
					nconditions = 2;
					
					% Read and process second audio file.
					[wav2,Fs_wav2] = audioread(path2);
					if ~isnan(spl)
						wav2 = wav2*(Pref*10.^(spl/20)/rms(wav2));
					end
					Condition(2).stimulus = resample(wav2,Fs,Fs_wav2).';
					num_pts2 = length(Condition(2).stimulus);
					
					% Add LTASS noise.
					if noise_SNR > -Inf
						if isnan(spl)
							ltass_SPL = noise_SNR;
						else
							ltass_SPL = spl - noise_SNR;
						end
						ltass_noise2 = ltass_noise0(Fs,ltass_SPL,num_pts2,1);
						ltass_dur2 = num_pts2/Fs;
						ramp2 = tukeywin(num_pts2, 2*ltass_ramp_dur/ltass_dur2);
						ltass_noise2 = ltass_noise2.*ramp2;
						Condition(2).stimulus = Condition(2).stimulus + ltass_noise2(:).';
					end
				end
				
			case 2 % Noise Band
				% Get parameters.
				spl = str2double(params(1).ValueH.String);
				dur = str2double(params(2).ValueH.String);
				rampdur = str2double(params(3).ValueH.String);
				Low_freq = str2double(params(4).ValueH.String);
				High_freq = str2double(params(5).ValueH.String);
				nconditions = 1; % response to only 1 stimulus
				% Compute stimulus.
				Condition(1).stimulus = Noise(dur,rampdur,Low_freq,High_freq,spl,Fs);
				
			case 3 % Notched Noise
				% Get parameters.
				noise_spl = str2double(params(1).ValueH.String);
				dur = str2double(params(2).ValueH.String);
				rampdur = str2double(params(3).ValueH.String);
				center_freq = str2double(params(4).ValueH.String);
				delta = str2double(params(5).ValueH.String);
				rel_bw = str2double(params(6).ValueH.String);
				tone_spl = str2double(params(7).ValueH.String);
				nconditions = 2;
				% Compute stimuli.  #1 has no tone, #2 is with tone.
				Condition(1).stimulus = Notched_Noise(dur,rampdur,center_freq,delta,rel_bw,noise_spl,-Inf,Fs);
				Condition(2).stimulus = Notched_Noise(dur,rampdur,center_freq,delta,rel_bw,noise_spl,tone_spl,Fs);
				
			case 4 % TIN (Tone in Noise)
				dur = str2double(params(1).ValueH.String);
				rampdur = str2double(params(2).ValueH.String);
				freq = str2double(params(3).ValueH.String);
				N0 = str2double(params(4).ValueH.String); % Noise masker spectrum level (dB SPL / Hz)
				Es_N0 = str2double(params(5).ValueH.String); % Tone level (E/No) ( see Evilsizer et al 2001 )
				switch stimData(4).Params(7).Data.BWType
					case 'octaves'
						bw_freqs = freq.*2.^([-0.5 0.5]*stimData(4).Params(7).Data.Value);
					case 'hertz'
						bw_freqs = stimData(4).Params(7).Data.Value;
				end
% 				SNR = str2double(params(6).ValueH.String); % This is already calculated and displayed.
% 				if get(handles.binaural, 'Value')
% 					bin_mode = 2; % 'bin_mode' = binaural mode >> Stay Tuned for Binaural version!
% 				else
% 					bin_mode = 1;
% 				end
				bin_mode = 1; % for monaural stimulus, bin_mode = 1
				nconditions = 2; % compare responses to 2 stimuli
				
				% The TIN function will be run to generate a TIN stimulus, not
				% just to calculate SNR.
				calculate_SNR_only = false;
				TINstruct = TIN(dur,rampdur,freq,N0,Es_N0,bin_mode,bw_freqs,Fs,calculate_SNR_only);
				switch bin_mode
					case 1
						Condition(1).stimulus = TINstruct.pin_N; % noise alone
						Condition(2).stimulus = TINstruct.pin_TIN; % tone-plus-Noise
					case 2
						disp('Binaural TIN is not yet implemented');
						return
				end
				
			case 5 % Profile Analysis (see Lentz 2005)
				spl = str2double(params(1).ValueH.String);
				dur = str2double(params(2).ValueH.String);
				rampdur = str2double(params(3).ValueH.String);
				ncomponents = str2double(params(4).ValueH.String);
				dB_incr = str2double(params(5).ValueH.String);
				nconditions = 2; % compare responses to 2 stimuli
				Condition(1).stimulus = Profile_Analysis(dur,rampdur,ncomponents,-Inf,spl,Fs);
				Condition(2).stimulus = Profile_Analysis(dur,rampdur,ncomponents,dB_incr,spl,Fs);
				
			case 6 % Pinna Cues
				spl = str2double(params(1).ValueH.String);
				dur = str2double(params(2).ValueH.String);
				rampdur = str2double(params(3).ValueH.String);
				fcenter = str2double(params(4).ValueH.String);
				nconditions = 1;
				Condition(1).stimulus = artificial_pinna_notch(dur,rampdur,fcenter,spl,Fs);
				
			case 7 % SAM Tone
				spl = str2double(params(1).ValueH.String);
				dur = str2double(params(2).ValueH.String);
				rampdur = str2double(params(3).ValueH.String);
				carrier_freq = str2double(params(4).ValueH.String);
				mod_freq = str2double(params(5).ValueH.String);
				mod_depth = str2double(params(6).ValueH.String);
				nconditions = 2;
				Condition(1).stimulus = SAM_Tone(dur,rampdur,carrier_freq,mod_freq,-Inf,spl,Fs); % unmodulated tone
				Condition(2).stimulus = SAM_Tone(dur,rampdur,carrier_freq,mod_freq,mod_depth,spl,Fs);
% 				Condition(1).stimulus = SAM_Tone_residue(dur,rampdur,...
% 					carrier_freq,mod_freq,mod_depth,stimdB,Fs,0); % SAM tone (choose harmonics)
% 				Condition(2).stimulus = SAM_Tone_residue(dur,rampdur,...
% 					carrier_freq,mod_freq,mod_depth,stimdB,Fs,40); % shifted SAM tone
				
			case 8 % Complex Tone
				spl = str2double(params(1).ValueH.String);
				dur = str2double(params(2).ValueH.String);
				rampdur = str2double(params(3).ValueH.String);
				f0 = str2double(params(4).ValueH.String);
				ncomponents = str2double(params(5).ValueH.String);
				include_fundmntl = logical(params(6).ValueH.Value);
				filter_type = params(7).ValueH.Value - 1;
				Wn_freq = str2num(params(8).ValueH.String); %#ok<ST2NM>
				nconditions = 1; % display response to only 1 stimulus
				Condition(1).stimulus = complex_tone(dur,rampdur,f0,ncomponents,filter_type,Wn_freq,...
					include_fundmntl,spl,Fs);
				
			case 9 % Single Formant - Lyzenga & Horst's triangular spectrum
				spl = str2double(params(1).ValueH.String);
				dur = str2double(params(2).ValueH.String);
				rampdur = str2double(params(3).ValueH.String);
				Fp = str2double(params(4).ValueH.String); % Peak Freq of spectral envelope (Hz)
				F0 = str2double(params(5).ValueH.String); % Fundamental freq (Hz)
				G = str2double(params(6).ValueH.String); % spectral slope (dB/oct)
				nconditions = 1; % display response to only 1 stimulus
				Condition(1).stimulus = generate_single_formant(dur,rampdur,F0,Fp,G,spl,Fs)';
				
			case 10 % Double Formant Klatt vowel
				spl = str2double(params(1).ValueH.String);
				dur = str2double(params(2).ValueH.String);
				rampdur = str2double(params(3).ValueH.String);
				F0 = str2double(params(4).ValueH.String); % Fundamental freq (Hz)
				formant_freqs = sscanf(params(5).ValueH.String,'%f').'; % Vector of formant freqs (Hz)
				BWs = sscanf(params(6).ValueH.String,'%f').'; % Vector of bandwidths for the formants (Hz)
				nconditions = 1; % display response to only 1 stimulus
				Condition(1).stimulus = klatt_vowel(dur,rampdur,F0,formant_freqs,BWs,spl,Fs);
				
			case 11 % Schroeder Phase Complex Tone
				spl = str2double(params(1).ValueH.String);
				dur = str2double(params(2).ValueH.String);
				rampdur = str2double(params(3).ValueH.String);
				f0 = str2double(params(4).ValueH.String);
				ncomponents = str2double(params(5).ValueH.String);
				Cvalue = str2double(params(6).ValueH.String);
				include_fundmntl = logical(params(7).ValueH.Value);
				nconditions = 2; % display response to 2 stimuli
				dB_incr = -Inf; % This variable can be used for Schroeder masking simulations; turn it "off" for now
				% Note sign change of Cvalue.
				Condition(1).stimulus = schroeder(dur,rampdur,Cvalue,f0,ncomponents,dB_incr,include_fundmntl,spl,Fs);
				Condition(2).stimulus = schroeder(dur,rampdur,-Cvalue,f0,ncomponents,dB_incr,include_fundmntl,spl,Fs);
				
			case 12 % Noise-in-Notched Noise (Viemeister 1983)
				dur = str2double(params(1).ValueH.String);
				rampdur = str2double(params(2).ValueH.String);
				db_target_No = str2double(params(3).ValueH.String); % dB SPL spectrum level for standard target noise
				db_increment_So = str2double(params(4).ValueH.String); % dB increment for test target noise
				nconditions = 2; % compare responses to 2 stimuli
				% cf =      str2double(stimParamEdit{stimIdx,3}.String); % Hz; center freq of stimulus (not neuron's CF)
				%  delta =   str2double(stimParamEdit{stimIdx,4}.String); % UNITS (Notch width/2)/CF
				%  bw =      str2double(stimParamEdit{stimIdx,5}.String); % Hz for each noise band
				Condition(1).stimulus = Noise_in_Notched_Noise(dur,...
					rampdur,db_target_No,-Inf,Fs); % standard - target noise with No spectrum level
				Condition(2).stimulus = Noise_in_Notched_Noise(dur,...
					rampdur,db_target_No,db_increment_So,Fs); % test - target noise with No+So spectrum level
				
			case 13 % FM Tone
				spl = str2double(params(1).ValueH.String);
				dur = str2double(params(2).ValueH.String);
				rampdur = str2double(params(3).ValueH.String);
				signalfreq = str2double(params(4).ValueH.String);
				C1_params = sscanf(params(5).ValueH.String,'%f').';
				C2_params = sscanf(params(6).ValueH.String,'%f').';
				nconditions = 2;
				Condition(1).stimulus = FM_Tone(dur,rampdur,signalfreq,C1_params,spl,Fs);
				Condition(2).stimulus = FM_Tone(dur,rampdur,signalfreq,C2_params,spl,Fs);
				
			case 14 % Forward Masking
				spl = str2double(params(1).ValueH.String);
				mask_dur = str2double(params(2).ValueH.String);
				mask_ramp = str2double(params(3).ValueH.String);
				probe_dur = str2double(params(4).ValueH.String);
				probe_level = str2double(params(5).ValueH.String);
				mask_freq = str2double(params(6).ValueH.String);
				probe_freq = str2double(params(7).ValueH.String);
				delay = str2double(params(8).ValueH.String);
				nconditions = 2;
				% Condition(1) = Masker + probe; Condition(2) = Masker only
				[Condition(1).stimulus,Condition(2).stimulus] = Forward_masking_tones(mask_dur,mask_ramp,...
					probe_dur,probe_level,mask_freq,probe_freq,delay,spl,Fs);
				
			case 15 % CMR Band widening
				s_dur = str2double(params(1).ValueH.String);
				s_rampdur = str2double(params(2).ValueH.String);
				freq = str2double(params(3).ValueH.String);
				tone_level = str2double(params(4).ValueH.String); % Tone level (E/No) ( see Evilsizer et al 2001 )
				bw = str2double(params(5).ValueH.String); % This is calculated and displayed
				No = str2double(params(6).ValueH.String); % Noise masker spectrum level (dB SPL / Hz)
				m_dur = str2double(params(7).ValueH.String);
				m_rampdur = str2double(params(8).ValueH.String);
				bw_mod = str2double(params(9).ValueH.String);
				nconditions = 2; % compare responses to 2 stimuli
				% [mod noise plus tone,unmodulated noise-plus-tone]
				[Condition(1).stimulus,Condition(2).stimulus] = CMR_BW2(s_dur,m_dur,s_rampdur,m_rampdur,freq,bw,...
					bw_mod,No,tone_level,Fs);
				
			case 16 % CMR Flanking Bands
				dur = str2double(params(1).ValueH.String);
				rampdur = str2double(params(2).ValueH.String);
				freq = str2double(params(3).ValueH.String);
				No = str2double(params(4).ValueH.String); % Noise masker spectrum level (dB SPL / Hz)
				tone_level = str2double(params(5).ValueH.String); % Tone level (E/No) (see Evilsizer et al 2001)
				BW = str2double(params(6).ValueH.String); % This is calculated and displayed
				nconditions = 2; % compare responses to 2 stimuli
				% [comod noise plus tone,codeviant noise-plus-tone]
				[Condition(1).stimulus,Condition(2).stimulus] = CMR_FB(dur,rampdur,freq,No,tone_level,BW,Fs);
				
% 			case 17 % Example for user-supplied stimulus (STIM)
% 				param1 = str2double(params(1).ValueH.String);
% 				param2 = str2double(params(1).ValueH.String);
% 				nconditions = 2; % compare responses to 2 stimuli
% 				[Condition(1).stimulus,Condition(2).stimulus] = user_function(param1,param2,Fs);
				
% 			case n % Template for addition of new stimulus that is not a wavfile
				% Get parameters from params as above.
				% Stimulus waveforms must be in scaled into pascals in stimulus
				%   function code.
				% Must pass sampling frequency (Fs) to stimulus code; stimulus
				%   level in dB, Duration, and on/off ramp durations, etc..
				% If only 1 stimulus waveform is to be used, set nconditions = 1
				%   and use Condition(1).stimulus (see noise example above).
				% Condition(1).stimulus may be a null or baseline stimulus to
				%   compare against (i.e., noise without a tone, a tone complex
				%   without an increment in the center, etc.)
				% Condition(1).stimulus = mystimulus(dur, rampdur, param1, param2, ..., param6, spl, Fs);
				% Then comparison stimulus should be placed in Condition(2):
				% Condition(2).stimulus = mystimulus(dur, rampdur, param1, param2, ..., param6, spl, Fs);
		end
		
		% Model Parameters
		minCF = str2double(char(CFEditLo.String));
		maxCF = str2double(char(CFEditHi.String));
		CF_num =str2double(char(numCFEdit.String));
		fiber_num = str2double(char(num_fibers_edit.String));
		CF_range = [minCF, maxCF];
		
		% Hearing loss in dB, to determine Cohc and Cihc for model using
		% function from Bruce and Zilany models, as in Bruce et al 2018 code.
		ag_dbloss = cellfun(@str2double,{OHCEdit.String});
		ag_fs = [125 250 500 1e3 2e3 4e3 8e3]; % audiometric frequencies
		
		% Call Model and Plotting code
		UR_EAR_model_plots(ag_fs,ag_dbloss,fiber_num,CF_num)
		
		% Enable Run button and set pointer back to 'arrow'.
		run_button.Enable = 'on';
		fig.Pointer = 'arrow';
		
		size_changed(fig,[])
	end


%  Main Model code and plotting functions
	function UR_EAR_model_plots(ag_fs,ag_dbloss,fiber_num,CF_num)
		% Compute and display AN and IC population responses as a function of
		% Characteristic Frequency (CF) and Best Modulation Frequency (BMF).
		% Inputs: Condition.stimulus (pressure input, in pascals)
		%         cohc = Outer hair cell function (0-1 where 1 is normal)
		%         cihc = inner hair cell function
		
		% Initialize counters for toggling plots between conditions
		clicks_wave_n = 0;   % Stimulus waveform plot
		clicks_specgram_n = 0;  % Spectrogram plot
		clicks_spec_n = 0;       % Spectrum CF range
		clicks_an_timefreq = 0;  % AN time_freq plot
		clicks_ic_timefreq = 0;  % IC time_freq plot
		clicks_ic_avg_rate = 0;   % For toggling between IC BP and IC BS
		clicks_wave_w = 0;
		clicks_specgram_w = 0;
		clicks_vihc_timefreq = 0;  % AN time_freq plot
		clicks_an_timefreq_w = 0;
		clicks_ic_timefreq_w = 0;
		clicks_wide = 0;
		
		stim_type_title.String = stimData(stimIdx).Type;
		condition_string1.String = ['C1: ',stimData(stimIdx).Description1];
		condition_string2.String = ['C2: ',stimData(stimIdx).Description2];
		
		% Set visibility of second play button.
		if nconditions > 1
			play_c2_button.Visible = 'on';
		else
			play_c2_button.Visible = 'off';
		end
		
		
		% Model Selection and Parameters
		% ------------------------------
		
		fiberType = spontTypePopup.Value; % AN fiber type. (1 = low SR, 2 = medium SR, 3 = high SR)
		% Set implnt = 0 => approximate model, 1 => exact power law
		% implementation (See Zilany et al., 2009)
		implnt = 0;
		% Set noiseType to 0 for fixed fGn or 1 for variable fGn - this is the
		% 'noise' associated with spontaneous activity of AN fibers - see Zilany
		% et al., 2009. 0 lets you "freeze" it.
		noiseType = 1;
		species = speciesTypePopup.Value; % 1=cat; 2=human AN model parameters (with Shera tuning sharpness)
		CFs = logspace(log10(CF_range(1)),log10(CF_range(2)),CF_num); % set range and resolution of CFs here
		CFs([1 end]) = CF_range; % force end points to be exact.
		if Which_IC == 1
			BMF = str2double(IC_data_edit{1}.String);
		elseif Which_IC == 2
			BMF = str2double(IC_data_edit{2}.String);
		end
		
		dbloss = interp1(ag_fs,ag_dbloss,CFs,'linear','extrap');
		[cohc_vals,cihc_vals] = fitaudiogram2(CFs,dbloss,species);
		if cohc_vals(1) == 0
			% For a very low CF, a 0 may be returned by Bruce et al. fit
			% audiogram, but this is a bad default.  Set it to 1 here.
			cohc_vals(1) = 1;
		end
		if cihc_vals(1) == 0
			% For a very low CF, a 0 may be returned, but this is a bad default.
			% Set it to 1 here.
			cihc_vals(1) = 1;
		end
		
		% Check for NaN in stimulus.  This prevents NaN from being passed into
		% mex files and causing MATLAB to close.
		for NaN_check_i = nconditions
			if any(isnan(Condition(NaN_check_i).stimulus))
				error('One or more fields of the UR_EAR input were left blank or completed incorrectly.')
			end
		end
		
		% Set up and RUN the simulation.
		% Loop through conditions.
		nrep = 1;
		% Set max. number of iterations for waitbar and make it visible.
		num_iters = nconditions*length(CFs);
		iter = 0;
		wb.Max = num_iters;
		wb.Visible = 'on';
		for ci = 1:nconditions % One or two stimulus conditions
			
			% Get length of stimulus.
			Condition(ci).N = length(Condition(ci).stimulus);
			
			% Compute spectrum (FFT) of stimulus.
			Condition(ci).dur = Condition(ci).N/Fs;
			Condition(ci).spec = db(abs(sqrt(2)*fft(Condition(ci).stimulus)/Condition(ci).N/Pref));
			Condition(ci).fspec = (0:Condition(ci).N-1)/Condition(ci).dur;
			
			% Compute spectrogram of stimulus.
			% 50% overlap (using even numbers to avoid "beating" with F0 for speech)
			[Condition(ci).specgram,Condition(ci).fsg,Condition(ci).tsg] = spectrogram(...
				Condition(ci).stimulus,hanning(1000),[],2000,Fs);
			
			Condition(ci).dur2 = Condition(ci).dur + 0.04;
			dur = Condition(ci).dur; % duration of waveform in sec
			dur2 = Condition(ci).dur2;
			T = 1/Fs;
			
			% Loop through CFs (within nconditions loop) in reverse order so
			% matrices don't have to be resized.
			for n = length(CFs):-1:1
				iter = iter + 1;
				wb.Value = iter; % update waitbar
				
				% Get one element of each array.
				CF = CFs(n); % CF in Hz;
				cohc = cohc_vals(n);
				cihc = cihc_vals(n);

				switch Which_AN
					case 1
						% Using ANModel_2014 (2-step process)
						vihc = model_IHC(Condition(ci).stimulus,CF,nrep,T,dur2,cohc,cihc,species);
						% use version of model_IHC that returns BM response (ChirpFilter only)
% 						[vihc,bm] = model_IHC_BM(Condition(ci).stimulus,CF,nrep,1/Fs,dur2,cohc,cihc,species);
						% Save output waveform into matrices.
						Condition(ci).VIHC_population(n,:) = resample(vihc,RsFs,Fs);
% 						Condition(ci).BM_population(n,:) = resample(bm,RsFs,Fs);

						% an_sout is the auditory-nerve synapse output - a rate vs. time
						% function that could be used to drive a spike generator.
						[an_sout,~,~] = model_Synapse(vihc,CF,nrep,T,fiberType,noiseType,implnt);
						% Save synapse output waveform into a matrix.
						Condition(ci).an_sout_population(n,:) = resample(an_sout,RsFs,Fs);
						
					case 2
						vihc = model_IHC_BEZ2018(Condition(ci).stimulus,CF,nrep,T,dur2,cohc,cihc,species);
						Condition(ci).VIHC_population(n,:) = resample(vihc,RsFs,Fs);
						
						[psth,neurogram_ft] = generate_neurogram_UREAR2(Condition(ci).stimulus,Fs,species,...
							ag_fs,ag_dbloss,CF_num,dur,n,fiber_num,CF_range,fiberType);
						
						an_sout = (100000*psth)/fiber_num;
						Condition(ci).an_sout_population(n,:) = resample(an_sout,RsFs,Fs);
						Condition(ci).an_sout_population_plot(n,:) = neurogram_ft;
						
				end
				switch Which_IC
					case 1 % Monaural SFIE
						[ic_sout_BE,ic_sout_BS,cn_sout_contra] = SFIE_BE_BS_BMF(an_sout,BMF,Fs);
						Condition(ci).BE_sout_population(n,:) = resample(ic_sout_BE,RsFs,Fs);
						Condition(ci).BS_sout_population(n,:) = resample(ic_sout_BS,RsFs,Fs);
						Condition(ci).cn_sout_contra(n,:) = cn_sout_contra;
						
					case 2 % Monaural Simple Filter
						% Now, call NEW unitgain BP filter to simulate bandpass IC cell with all BMFs.
						ic_sout_BE = unitgain_bpFilter(an_sout,BMF,Fs);
						Condition(ci).BE_sout_population(n,:) = resample(ic_sout_BE,RsFs,Fs);
						
				end
			end % end of CF loop
		end  % end of nconditions loop
		wb.Value = 0;
		wb.Visible = 'off';
		
		% Initialize position of selection lines in waveform plot and
		% corresponding axes limits on the AN Model and IC model plots.
		set(analysis_window_lines,'Visible','on')
		if ~analysis_window_hold
			span = 0.04; % 40 ms width.
			span = min(span,Condition(1).dur*0.9); % no more than 0.9*duration
			aw_t = Condition(1).dur/2 + [-0.5 0.5]*span;
			% Adjust in case stimulus is less than 40 ms in duration.
			aw_t = min(max(aw_t,0),Condition(1).dur);
			analysis_window_lines(1).XData = [1 1]*aw_t(1);
			analysis_window_lines(2).XData = [1 1]*aw_t(2);
			
			% Update the analysis window display.
			analysis_window_text.String = sprintf('{\\color{blue}Analysis Window:} %.3g to %.3g s',aw_t);
		end
		
		AN_axes_n.XLim = aw_t;
		IC_axes_n.XLim = aw_t;
		
		
		% Update all plots by running the ButtonDownFcn of each.
		handle_be_bs_radio([],[],1) % set BE/BS to show BE plot.
		next_wave()
		next_specgram()
		next_spec()
		next_AN_model()
		next_IC_model()
		next_AN_avg()
		next_CN_avg()
		next_IC_avg()
		
% 		next_wave_w()
% 		next_specgram_w()
% 		next_VIHC_w()
% 		next_AN_model_w()
% 		next_IC_model_w()
		next_wide_plots()

	end


	function select_AN_model(~,~)
		% Select the AN model to be used.
		
		% Set the value of Which_AN.
		Which_AN = AN_model_popup.Value;
		
		% Set visibility of additional controls.
		switch Which_AN
			case 1
				num_fibers_label.Visible = 'off';
				num_fibers_edit.Visible = 'off';
			case 2
				num_fibers_label.Visible = 'on';
				num_fibers_edit.Visible = 'on';
		end
	end

	function select_IC_model(~,~)
		% Allow user to select IC model from examples in Nelson & Carney 2004,
		% Fig. 8.  Flag that model type has changed allows past values to be
		% retained.
		
		previous_Which_IC = Which_IC;
		Which_IC = IC_model_popup.Value;
		IC_model_just_changed = Which_IC ~= previous_Which_IC;
		
		switch Which_IC
			case 1 % SFIE model
				[IC_data_edit{1}.Visible] = deal('on');
				[IC_data_labels{1}.Visible] = deal('on');
				[IC_data_edit{2}.Visible] = deal('off');
				[IC_data_labels{2}.Visible] = deal('off');
				[IC_data_edit{3}.Visible] = deal('off');
				[IC_data_labels{3}.Visible] = deal('off');
				
				% Use last value, unless model type has just been changed.
				if IC_model_just_changed
					% Initial default when switching to SFIE model.
					BMF = 100;
					IC_data_edit{1}.String = num2str(BMF);
				end
				BMF = str2double(IC_data_edit{1}.String);
				IC_model_popup.(Tooltip) = IC_model_credits{1};
				
			case 2 % AN_ModFilt model
				[IC_data_edit{2}.Visible] = deal('on');
				[IC_data_labels{2}.Visible] = deal('on');
				[IC_data_edit{1}.Visible] = deal('off');
				[IC_data_labels{1}.Visible] = deal('off');
				[IC_data_edit{3}.Visible] = deal('off');
				[IC_data_labels{3}.Visible] = deal('off');
				
				% Use last value, unless model type has just been changed.
				if IC_model_just_changed
					% Initial default when switching to AN_modfilt model.
					BMF = 100;
					IC_data_edit{2}.String = num2str(BMF);
				end
				BMF = str2double(IC_data_edit{2}.String);
				IC_model_popup.(Tooltip) = IC_model_credits{2};
				
		end
	end
	
	function size_changed(fig,~)
		% Adjust sizes and positions of most graphical objects when figure is
		% resized.
		
		% Get new size of figure.
		fig_wh = fig.Position(3:4);
		
		% Set new y-coordinate of stimulus type popup menu and its label.
		stim_type_text.Position(2) = fig_wh(2) - 35 + text_adj(2);
		stim_type_popup.Position(2) = fig_wh(2) - 35 + popup_adj(2);
		
		% Set position of info panel above graphs.
		info_panel_width = max(fig_wh(1) - param_width,0);
		info_panel.Position(2:3) = [fig_wh(2)-60,info_panel_width];
		
		% Set positions of preferences and hints buttons.
		updates_button.Position(1) = info_panel_width - updates_button.Position(3) - 10;
		tips_button.Position(1) = info_panel_width - tips_button.Position(3) - 10;
		
		% Set width and height of output panels.
		out_panel_wh = max([fig_wh(1)-param_width,fig_wh(2)-90],0);
		output_panel_n.Position(3:4) = out_panel_wh;
		output_panel_w.Position(3:4) = out_panel_wh;
		
		% Set position of documentation note.
		dnwid = doc_note.Extent(3);
		dnleft = param_width + (fig_wh(1) - param_width - dnwid)/2;
		doc_note.Position(1) = max(dnleft,sum(wide_display_cb.Position([1 3])));
		doc_note.Position(3) = doc_note.Extent(3);

		
		% Reposition narrow axes.
		nar_left_gap = 55;
		nar_right_gap = 20;
		nar_x_gaps = [0 60 110]; % gaps before each column of plots
		nar_top_gap = 20;
		nar_bottom_gap = 40;
		nar_y_gap = 60;
		
		nar_width = max((out_panel_wh(1) - nar_left_gap - nar_right_gap - sum(nar_x_gaps))/3,0);
		nar_x_col = nar_left_gap + (0:2)*nar_width + cumsum(nar_x_gaps);
		nar_height = max((out_panel_wh(2) - nar_top_gap - nar_bottom_gap - 2*nar_y_gap)/3,0);
		nar_y_row = nar_bottom_gap + (2:-1:0)*(nar_height + nar_y_gap);
		nar_x = nar_x_col([1 1 1 2 2 3 3 3]);
		nar_y = nar_y_row([1 2 3 1 2 1 2 3]);
		nar_y(4:5) = nar_y(4:5) - (out_panel_wh(2) - nar_top_gap - nar_bottom_gap)/6;
		for axi = 1:8
			narrow_axes(axi).Position = [nar_x(axi),nar_y(axi),nar_width,nar_height];
		end
		
		% Reposition analysis window display.
		wav_anno_ax.Position(1) = sum(wav_axes_n.Position([1 3])) + 4;
		wav_anno_ax.Position(2) = sum(wav_axes_n.Position([2 4])) - wav_anno_ax.Position(4);
		
		% Reposition wide axes.
		wide_left_gap = 60;
		wide_right_gap = 75;
		wide_top_gap = 20;
		wide_bottom_gap = 45;
		wide_y_gap = 50; % vertical space between plots
		wide_x = wide_left_gap;
		wide_width = max(out_panel_wh(1) - wide_left_gap - wide_right_gap,0);
		wide_height = max((out_panel_wh(2) - wide_top_gap - wide_bottom_gap - 4*wide_y_gap)/5,0);
		wide_y = wide_bottom_gap + (4:-1:0)*(wide_height + wide_y_gap);
		for axi = 1:5
			wide_axes(axi).Position = [wide_x,wide_y(axi),wide_width,wide_height];
		end
		
		% Reposition BE/BS radio buttons.
		IC_resp_pos = IC_avg_axes.Position(1:2);
		be_bs_radio(1).Position(1:2) = [IC_resp_pos(1)-80,IC_resp_pos(2)+25] + check_adj(1:2);
		be_bs_radio(2).Position(1:2) = [IC_resp_pos(1)-80,IC_resp_pos(2)+0] + check_adj(1:2);
		
		% Set height of current stimulus parameters panel.
		stimData(stimIdx).Panel.Position(4) = max(fig_wh(2)-25-20-392,0);
		
		% Set vertical position of each uicontrol in the current stimulus
		% parameters panel.  Each parameter will have a ValueH control (edit
		% box, checkbox, etc.) and some will also have a LabelH control (text).
		normal_spacing = 25;
		top = -41;
		spacing = min((stimData(stimIdx).Panel.Position(4) + top) / ...
			(stimData(stimIdx).Params(end).Row - 1),normal_spacing);
		for paramIdx = 1:stimData(stimIdx).NumParams
			y = stimData(stimIdx).Panel.Position(4) + top - (stimData(stimIdx).Params(paramIdx).Row - 1)*spacing;
			stimData(stimIdx).Params(paramIdx).ValueH.Position(2) = y + edit_adj(2);
			if ~isempty(stimData(stimIdx).Params(paramIdx).LabelH)
				stimData(stimIdx).Params(paramIdx).LabelH.Position(2) = y + text_adj(2);
			end
		end
	end

	function  play_cond1_stim(~,~)
		% Play condition 1 sound.
		sound(Condition(1).stimulus,Fs)
	end

	function  play_cond2_stim(~,~)
		% Play condition 2 sound, if present.
		if nconditions == 2
			sound(Condition(2).stimulus,Fs)
		end
	end

	function close_fig(~,~)
		% Set the figure size preference then delete main figure and help figure.
		try
			fig_pos = fig.Position;
			setpref(program,'figure_position',fig_pos)
			delete(findall(groot,'Tag','UR_EAR help window'))
			delete(findall(groot,'Tag','UR_EAR tips window'))
			delete(fig)
		catch err
			uiwait(errordlg(err.message,'','modal'))
			delete(fig)
		end
	end

	function select_stim_type(~,~)
		% Select which stimulus type to use and make that panel visible.
		
		% Get the stimulus index.
		stimIdx = stim_type_popup.Value;
		
		% Make all stimulus parameter panels invisible.
		all_stim_panels = [stimData.Panel];
		[all_stim_panels.Visible] = deal('off');
		
		% Make the chosen stimulus parameter panel visible.
		all_stim_panels(stimIdx).Visible = 'on';
		
		% Make sure controls are positioned correctly.
		size_changed(fig)
		
		% Enable Run button and set pointer back to 'arrow'.  This is done in
		% case there is an error in a model run and the Run button is left
		% disabled.
		run_button.Enable = 'on';
		fig.Pointer = 'arrow';
		wb.Visible = 'off';
	end

	function handle_be_bs_radio(~,~,k)
		% Handle BE/BS radio buttons on IC model graph.
		set(be_bs_radio,'Value',false)
		be_bs_radio(k).Value = true;
		be_bs_selection = k;
		next_IC_avg()
	end

	function sel_line_down(~,~,k)
		% User clicked on analysis window vertical line k (k = 1 or 2) on
		% stimulus waveform plot.  Set callback functions to track motion of
		% pointer and detect when mouse button is released.
		move_both = strcmp(fig.SelectionType,'alt');
		selected_line = k;
		fig.WindowButtonMotionFcn = @sel_line_move;
		fig.WindowButtonUpFcn = @sel_line_up;
		sel_line_move()
	end

	function sel_line_move(~,~)
		% Update location of analysis window vertical line(s) and call function
		% to update all affected graphs.
		
		% Get current location of mouse pointer.
		cpx = wav_axes_n.CurrentPoint(1,1);
		
		% Update analysis window line(s).
		if move_both
			d = diff(aw_t);
			aw_t(selected_line) = cpx;
			if selected_line == 1
				aw_t(2) = cpx + d;
			else
				aw_t(1) = cpx - d;
			end
		else
			if selected_line == 1 && cpx > aw_t(2) - 0.005 || selected_line == 2 && cpx < aw_t(1) + 0.005
				return
			end
			aw_t(selected_line) = cpx;
		end
		analysis_window_lines(1).XData = [1 1]*aw_t(1);
		analysis_window_lines(2).XData = [1 1]*aw_t(2);
		
		% Update plots to reflect new analysis window.
		update_plots_with_selection()
	end

	function sel_line_up(~,~)
		% Unset callback functions that track mouse pointer movement.
		fig.WindowButtonMotionFcn = '';
		fig.WindowButtonUpFcn = '';
	end

	function set_analysis_window(~,~)
		% Process clicks on analysis window value display text.
		
		switch fig.SelectionType
			case 'alt' % right-click
				% Toggle hold state of analysis window values and update plots.
				analysis_window_hold = ~analysis_window_hold;
				update_plots_with_selection()
				return
			case {'open','extend'} % anything except normal click
				return
		end
		% If we get here, fig.SelectionType must be 'normal', meaning a single
		% click.
		
		% Open input dialog to get values of analysis window.
		default = arrayfun(@(x){sprintf('%.3g',x)},aw_t);
		sel_x_c = inputdlg({'Analysis Window: (seconds)','to'},'',1,default);
		if isempty(sel_x_c)
			return
		end
		
		% Process typed entries and update positions of lines.
		old_aw_t = aw_t;
		aw_t(1) = str2double(sel_x_c{1});
		aw_t(2) = str2double(sel_x_c{2});
		if any(isnan(aw_t))
			uiwait(errordlg('Incorrect analysis window entry.','Error','modal'))
			aw_t = old_aw_t;
			return
		end
		analysis_window_lines(1).XData = [1 1]*aw_t(1);
		analysis_window_lines(2).XData = [1 1]*aw_t(2);
		
		% Update plots to reflect new analysis window.
		update_plots_with_selection()
	end

	function reset_selection(~,~)
		% User clicked on "Reset" to reset analysis window to default values.
		
		% Compute new analysis window and position lines.
		span = 0.04; % 40 ms width.
		span = min(span,Condition(1).dur*0.9); % no more than 0.9*duration
		aw_t = Condition(1).dur/2 + [-0.5 0.5]*span;
		% Adjust in case stimulus is less than 40 ms in duration.
		aw_t = min(max(aw_t,0),Condition(1).dur);
		analysis_window_lines(1).XData = [1 1]*aw_t(1);
		analysis_window_lines(2).XData = [1 1]*aw_t(2);
		
		% Update plots to reflect new analysis window.
		analysis_window_hold = false;
		update_plots_with_selection()
	end

	function update_plots_with_selection()
		% This nested function is not a callback, but is called from several
		% places where the plots affected by the analysis window must change.
		
		% Update the analysis window display.
		if analysis_window_hold
			aw_fmt = '{\\color{blue}Analysis Window:} %.3g to %.3g s  {\\color[rgb]{0.8,0,0}HELD }';
		else
			aw_fmt = '{\\color{blue}Analysis Window:} %.3g to %.3g s';
		end
		analysis_window_text.String = sprintf(aw_fmt,aw_t);
		
		% Adjust AN and IC model plot axes limits.
		AN_axes_n.XLim = aw_t;
		IC_axes_n.XLim = aw_t;
		
		% Recompute averages of AN, CN, and IC model results over analysis
		% window and update the plots.
		dur = min(arrayfun(@(x)x.dur,Condition(1:nconditions)));
		idx = round(min(max(aw_t,0),dur)*RsFs) + [1 0];
		for ci = 1:nconditions
			AN_avg_lines(ci).YData = mean(Condition(ci).an_sout_population(:,idx(1):idx(2)),2);
			AN_avg_axes.YLimMode = 'auto';
			AN_avg_axes.YLim(1) = 0;
			AN_avg_axes.UserData = sprintf('AN Ave. Rate (%.3g to %.3g s)',aw_t);
			
			if Which_IC == 1
				CN_avg_lines(ci).YData = mean(Condition(ci).cn_sout_contra(:,idx(1):idx(2)),2);
				CN_avg_axes.YLimMode = 'auto';
				CN_avg_axes.YLim(1) = 0;
				CN_avg_axes.UserData = sprintf('AN Ave. Rate (%.3g to %.3g s)',aw_t);
			end
			
			if Which_IC == 1 && be_bs_selection == 2
				IC_avg_lines(ci).YData = mean(Condition(ci).BS_sout_population(:,idx(1):idx(2)),2);
				IC_avg_axes.UserData = sprintf('IC BS Ave. Rate (BMF=%g Hz) (%.3g to %.3g s)',BMF,aw_t);
			else
				IC_avg_lines(ci).YData = mean(Condition(ci).BE_sout_population(:,idx(1):idx(2)),2);
				IC_avg_axes.UserData = sprintf('IC BE Ave. Rate (BMF=%g Hz) (%.3g to %.3g s)',BMF,aw_t);
			end
			IC_avg_axes.YLimMode = 'auto';
			IC_avg_axes.YLim(1) = 0;
		end
	end

	function next_wave(~,~)
		% User clicked on stimulus waveform plot.  Switch to next condition.
		if ~strcmp(fig.SelectionType,'normal')
			% Abort if not a normal (left) click.
			return
		end
		set(analysis_window_lines,'Visible','off')
		wav_axes_n.YLimMode = 'auto';
		clicks_wave_n = rem(clicks_wave_n,nconditions) + 1;
		time = (0:Condition(clicks_wave_n).N-1)/Fs;
		stim_wav_line.XData = time;
		stim_wav_line.YData = Condition(clicks_wave_n).stimulus;
		stim_wav_line.Color = colors{clicks_wave_n};
		wav_axes_n.XLim = [0,Condition(clicks_wave_n).dur];
		wav_axes_n.Visible = 'on';
		fmt = 'Waveform: {\\color[rgb]{%.2g,%.2g,%.2g}C%d}';
		title(wav_axes_n,sprintf(fmt,stim_wav_line.Color,clicks_wave_n))
		wav_axes_n.YLimMode = 'manual';
		set(analysis_window_lines,'YData',wav_axes_n.YLim)
		set(analysis_window_lines,'Visible','on')
		set(text_annotations,'Visible','on')
	end

	function next_specgram(~,~)
		% User clicked on spectrogram plot.  Switch to next condition.
		if ~strcmp(fig.SelectionType,'normal')
			% Abort if not a normal (left) click.
			return
		end
		clicks_specgram_n = rem(clicks_specgram_n,nconditions) + 1;
		specgram_surf.XData = Condition(clicks_specgram_n).tsg;
		specgram_surf.YData = Condition(clicks_specgram_n).fsg;
		specgram_surf.CData = abs(Condition(clicks_specgram_n).specgram);
		specgram_surf.ZData = zeros(size(specgram_surf.CData));
		specgram_axes_n.XLim = [0,Condition(clicks_specgram_n).dur];
		specgram_axes_n.YLim = [0.9 1.1].*CF_range;
		specgram_axes_n.Visible = 'on';
		fmt = 'Spectrogram: {\\color[rgb]{%.2g,%.2g,%.2g}C%d}';
		str = sprintf(fmt,colors{clicks_specgram_n},clicks_specgram_n);
		title(specgram_axes_n,str)
	end

	function next_spec(~,~)
		% User clicked on spectrum plot.  Switch to next condition.
		if ~strcmp(fig.SelectionType,'normal')
			% Abort if not a normal (left) click.
			return
		end
		clicks_spec_n = rem(clicks_spec_n,nconditions) + 1;
% 		m = length(Condition(clicks_spec_n).stimulus);
% 		nfft = pow2(nextpow2(m));
% 		spectrum_plot = db(abs(2*fft(Condition(clicks_spec_n).stimulus,...
% 			nfft)/m/Pref));
% 		spectrum = db(abs(2*fft(Condition(clicks_spec_n).stimulus)/m/Pref));
		% See:
		% http://12000.org/my_notes/on_scaling_factor_for_ftt_in_matlab/.
		%   spectrum_phase = angle(2*fft(Condition(stim_plot).stimulus,nfft));
		% This normalization was missing in v1.0.
		% Use overall max (across nconditions) value for upper limit of
		% ylim.
% 		spec_max = -inf; % initialize
% 		for icond = 1:nconditions
% 			spec = Condition(icond).spec;
% 			spec_max = max(spec_max, max(spec));
% 		end
		spec_max = max(arrayfun(@(x)max(x.spec(:)),Condition(1:nconditions)));
% 		fres = Fs/m; % freq resolution = 1/Dur
		spec_line.XData = Condition(clicks_spec_n).fspec; % fres*(0:m-1);
		spec_line.YData = Condition(clicks_spec_n).spec;
		
		spec_line.Color = colors{clicks_spec_n};
		spec_axes_n.XLim = CF_range;
		spec_axes_n.YLim = [-47 3] + spec_max; % 50 dB span
		spec_axes_n.XTick = [100 200 500 1000 2000 5000 10000];
		spec_axes_n.Visible = 'on';
		fmt = 'Spectrum CF range: {\\color[rgb]{%.2g,%.2g,%.2g}C%d}';
		title(spec_axes_n,sprintf(fmt,spec_line.Color,clicks_spec_n))
		% Set axes scaling to linear or log.
		if ~stimData(stimIdx).UseLogAxes
			spec_axes_n.XScale = 'linear';
		elseif stimData(stimIdx).UseLogAxes
			spec_axes_n.XScale = 'log';
		end
	end

	function next_AN_model(~,~)
		% User clicked on AN model plot.  Switch to next condition.
		if ~strcmp(fig.SelectionType,'normal')
			% Abort if not a normal (left) click.
			return
		end
		clicks_an_timefreq = rem(clicks_an_timefreq,nconditions) + 1;
		
		if Which_AN == 1
			data = Condition(clicks_an_timefreq).an_sout_population;
			AN_surf_n.XData = (0:length(data)-1)/RsFs;
		elseif Which_AN == 2
% 			dur = Condition(clicks_an_timefreq).dur;
% 			data = Condition(clicks_an_timefreq).an_sout_population_plot(:,floor(0.01*Fs/16):floor(dur*Fs/16));
% 			plotcolor.XData = (0:length(data)-1)*16/Fs;
			
			% an_sout_population_plot data has a sample rate = Fs/16, and is
			% delayed by 10 ms.
			Fs2 = Fs/16;
			data = Condition(clicks_an_timefreq).an_sout_population_plot;
			AN_surf_n.XData = (0:length(data)-1)/Fs2 - 10e-3; % shift by 10 ms
		end
		AN_surf_n.YData = CFs;
		AN_surf_n.ZData = zeros(size(data));
		AN_surf_n.CData = data;
		AN_axes_n.XLim = aw_t;
		AN_axes_n.YLim = CF_range;
		fmt = 'AN Model: {\\color[rgb]{%.2g,%.2g,%.2g}C%d}';
		title(AN_axes_n,sprintf(fmt,colors{clicks_an_timefreq},clicks_an_timefreq))
		AN_axes_n.Visible = 'on';
		AN_model_cb.Visible = 'on';
	end

	function next_IC_model(~,~)
		% User clicked on IC model plot.  Switch to next condition.
		if ~strcmp(fig.SelectionType,'normal')
			% Abort if not a normal (left) click.
			return
		end
		clicks_ic_timefreq = rem(clicks_ic_timefreq,nconditions) + 1;
		
		data = Condition(clicks_ic_timefreq).BE_sout_population;
		N = length(data);
		time = (0:N-1)/RsFs;
		% Update the surface and axes properties.
		IC_surf_n.XData = time;
		IC_surf_n.YData = CFs;
		IC_surf_n.ZData = zeros(size(data));
		IC_surf_n.CData = data;
		IC_axes_n.XLim = aw_t;
		IC_axes_n.YLim = CF_range;
		% Set the title.
		fmt = 'IC Model (BE Cell): {\\color[rgb]{%.2g,%.2g,%.2g}C%d}';
		title(IC_axes_n,sprintf(fmt,colors{clicks_ic_timefreq},clicks_ic_timefreq))
		% Make the axes and its colorbar visible.
		IC_axes_n.Visible = 'on';
		IC_model_cb.Visible = 'on';
	end

	function next_AN_avg(~,~)
		% User clicked on AN average plot.  Replot both conditions.
		if ~strcmp(fig.SelectionType,'normal')
			% Abort if not a normal (left) click.
			return
		end
		set(AN_avg_lines,'Visible','off')
		idx = round(min(max(aw_t,0),Condition(1).dur)*RsFs) + [1 0];
		for ci = 1:nconditions
			AN_avg_lines(ci).XData = CFs;
			AN_avg_lines(ci).YData = mean(Condition(ci).an_sout_population(:,idx(1):idx(2)),2);
			AN_avg_lines(ci).Visible = 'on';
		end
		AN_avg_axes.XLim = CF_range;
		AN_avg_axes.YLimMode = 'auto';
		AN_avg_axes.YLim(1) = 0;
		if stimData(stimIdx).UseLogAxes
			AN_avg_axes.XScale = 'log';
		else
			AN_avg_axes.XScale = 'linear';
		end
		AN_avg_axes.Visible = 'on';
		AN_avg_axes.UserData = sprintf('AN Ave. Rate (%.3g to %.3g s)',aw_t);
	end

	function next_CN_avg(~,~)
		% User clicked on CN average plot.  Replot both conditions.
		if ~strcmp(fig.SelectionType,'normal')
			% Abort if not a normal (left) click.
			return
		end
		set(CN_avg_lines,'Visible','off')
		if ~isfield(Condition(1),'cn_sout_contra')
			CN_avg_axes.Visible = 'off';
			return
		end
		idx = round(min(max(aw_t,0),Condition(1).dur)*RsFs) + [1 0];
		for ci = 1:nconditions
			CN_avg_lines(ci).XData = CFs;
			CN_avg_lines(ci).YData = mean(Condition(ci).cn_sout_contra(:,idx(1):idx(2)),2);
			CN_avg_lines(ci).Visible = 'on';
		end
		CN_avg_axes.XLim = CF_range;
		CN_avg_axes.YLimMode = 'auto';
		CN_avg_axes.YLim(1) = 0;
		if stimData(stimIdx).UseLogAxes
			CN_avg_axes.XScale = 'log';
		else
			CN_avg_axes.XScale = 'linear';
		end
		CN_avg_axes.Visible = 'on';
		CN_avg_axes.UserData = sprintf('AN Ave. Rate (%.3g to %.3g s)',aw_t);
	end

	function next_IC_avg(~,~)
		% User clicked on IC average plot.  Replot both conditions.
		if ~strcmp(fig.SelectionType,'normal')
			% Abort if not a normal (left) click.
			return
		end
% 		clicks_ic_avg_rate = rem(clicks_ic_avg_rate,2) + 1;
		clicks_ic_avg_rate = be_bs_selection;
		set(IC_avg_lines,'Visible','off')
		dur = Condition(1).dur;
		idx = round(min(max(aw_t,0),dur)*RsFs) + [1 0];
		if Which_IC == 1 % SFIE model; plot toggles between BE and BS model responses
			set(be_bs_radio,'Visible','on')
			if clicks_ic_avg_rate == 1
				for ci = 1:nconditions
					% set plot props for Condition(ci).average_ic_sout_BE
					IC_avg_lines(ci).XData = CFs;
					IC_avg_lines(ci).YData = mean(Condition(ci).BE_sout_population(:,idx(1):idx(2)),2);
					IC_avg_lines(ci).Visible = 'on';
				end
				% set title with BE
				title(IC_avg_axes,sprintf('IC BE Ave. Rate (BMF=%g Hz)',BMF))
				IC_avg_axes.UserData = sprintf('IC BE Ave. Rate (BMF=%g Hz) (%.3g to %.3g s)',BMF,aw_t);
			else
				for ci = 1:nconditions
					% set plot props for Condition(ci).average_ic_sout_BS
					IC_avg_lines(ci).XData = CFs;
					IC_avg_lines(ci).YData = mean(Condition(ci).BS_sout_population(:,idx(1):idx(2)),2);
					IC_avg_lines(ci).Visible = 'on';
				end
				% set title with BS
				title(IC_avg_axes,sprintf('IC BS Ave. Rate (BMF=%g Hz)',BMF))
				IC_avg_axes.UserData = sprintf('IC BS Ave. Rate (BMF=%g Hz) (%.3g to %.3g s)',BMF,aw_t);
			end
		elseif Which_IC == 2 % AN_ModFilt model (models only Band-Enhanced cells)
			set(be_bs_radio,'Visible','off')
			for ci = 1:nconditions
				% set plot props for Condition(ci).average_ic_sout_BE
				IC_avg_lines(ci).XData = CFs;
				IC_avg_lines(ci).YData = mean(Condition(ci).BE_sout_population(:,idx(1):idx(2)),2);
				IC_avg_lines(ci).Visible = 'on';
			end
			% set title with BE
			title(IC_avg_axes,sprintf('IC BE Ave. Rate (BMF=%g Hz)',BMF))
			IC_avg_axes.UserData = sprintf('IC BE Ave. Rate (BMF=%g Hz) (%.3g to %.3g s)',BMF,aw_t);
		end
		% Set other props.
		IC_avg_axes.XLim = CF_range;
		IC_avg_axes.YLimMode = 'auto';
		IC_avg_axes.YLim(1) = 0;
		if stimData(stimIdx).UseLogAxes
			IC_avg_axes.XScale = 'log';
		else
			IC_avg_axes.XScale = 'linear';
		end
		IC_avg_axes.Visible = 'on';
	end

	function next_wave_w(~,~)
		% User clicked on wide stimulus waveform plot.  Switch to next condition.
		if ~strcmp(fig.SelectionType,'normal')
			% Abort if not a normal (left) click.
			return
		end
% 		clicks_wave_w = rem(clicks_wave_w,nconditions) + 1;
		clicks_wave_w = clicks_wide;
		time = (0:Condition(clicks_wave_w).N-1)/Fs;
		stim_wav_line_w.XData = time;
		stim_wav_line_w.YData = Condition(clicks_wave_w).stimulus;
		stim_wav_line_w.Color = colors{clicks_wave_w};
		wav_axes_w.XLim = [0,Condition(clicks_wave_w).dur2];
		wav_axes_w.Visible = 'on';
		fmt = 'Waveform: {\\color[rgb]{%.2g,%.2g,%.2g}C%d}';
		title(wav_axes_w,sprintf(fmt,stim_wav_line_w.Color,clicks_wave_w))
	end

	function next_specgram_w(~,~)
		% User clicked on wide spectrogram plot.  Switch to next condition.
		if ~strcmp(fig.SelectionType,'normal')
			% Abort if not a normal (left) click.
			return
		end
% 		clicks_specgram_w = rem(clicks_specgram_w,nconditions) + 1;
		clicks_specgram_w = clicks_wide;
		specgram_surf_w.XData = Condition(clicks_specgram_w).tsg;
		specgram_surf_w.YData = Condition(clicks_specgram_w).fsg;
		specgram_surf_w.CData = abs(Condition(clicks_specgram_w).specgram);
		specgram_surf_w.ZData = zeros(size(specgram_surf_w.CData));
		specgram_axes_w.XLim = [0,Condition(clicks_specgram_w).dur2];
		specgram_axes_w.YLim = [0.9 1.1].*CF_range;
		specgram_axes_w.Visible = 'on';
		fmt = 'Spectrogram: {\\color[rgb]{%.2g,%.2g,%.2g}C%d}';
		str = sprintf(fmt,colors{clicks_specgram_w},clicks_specgram_w);
		title(specgram_axes_w,str)
	end

	function next_VIHC_w(~,~)
		% User clicked on wide VIHC plot.  Switch to next condition.
		if ~strcmp(fig.SelectionType,'normal')
			% Abort if not a normal (left) click.
			return
		end
% 		clicks_vihc_timefreq = rem(clicks_vihc_timefreq,nconditions) + 1;
		clicks_vihc_timefreq = clicks_wide;
		data = Condition(clicks_vihc_timefreq).VIHC_population;
		VIHC_surf_w.XData = (0:length(data)-1)/RsFs;
		VIHC_surf_w.YData = CFs;
		VIHC_surf_w.ZData = zeros(size(data));
		VIHC_surf_w.CData = 1000*data;
		VIHC_axes_w.XLim = [0,Condition(clicks_vihc_timefreq).dur2];
		VIHC_axes_w.YLim = CF_range;
		% Set the title.
		fmt = 'IHC Model: {\\color[rgb]{%.2g,%.2g,%.2g}C%d}';
		title(VIHC_axes_w,sprintf(fmt,colors{clicks_vihc_timefreq},clicks_vihc_timefreq))
		% Make the axes and its colorbar visible.
		VIHC_axes_w.Visible = 'on';
		VIHC_cb.Visible = 'on';
	end

	function next_AN_model_w(~,~)
		% User clicked on wide AN model plot.  Switch to next condition.
		if ~strcmp(fig.SelectionType,'normal')
			% Abort if not a normal (left) click.
			return
		end
% 		clicks_an_timefreq_w = rem(clicks_an_timefreq_w,nconditions) + 1;
		clicks_an_timefreq_w = clicks_wide;
		
		if Which_AN == 1
			data = Condition(clicks_an_timefreq_w).an_sout_population;
			AN_surf_w.XData = (0:length(data)-1)/RsFs;
		elseif Which_AN == 2
% 			dur = Condition(clicks_an_timefreq_w).dur;
% 			data = Condition(clicks_an_timefreq_w).an_sout_population_plot(:,floor(0.01*Fs/16):floor(dur*Fs/16));
% 			plotcolor_w.XData = (0:length(data)-1)*16/Fs;
			
			% an_sout_population_plot data has a sample rate = Fs/16, and is
			% delayed by 10 ms.
			Fs2 = Fs/16;
			data = Condition(clicks_an_timefreq_w).an_sout_population_plot;
			AN_surf_w.XData = (0:length(data)-1)/Fs2 - 0*10e-3; % shift by 10 ms
		end
		AN_surf_w.YData = CFs;
		AN_surf_w.ZData = zeros(size(data));
		AN_surf_w.CData = data;
		AN_axes_w.XLim = [0,Condition(clicks_an_timefreq_w).dur2];
		AN_axes_w.YLim = CF_range;
		
		fmt = 'AN Model: {\\color[rgb]{%.2g,%.2g,%.2g}C%d}';
		title(AN_axes_w,sprintf(fmt,colors{clicks_an_timefreq_w},clicks_an_timefreq_w))
		AN_axes_w.Visible = 'on';
		AN_model_cb_w.Visible = 'on';
	end

	function next_IC_model_w(~,~)
		% User clicked on wide IC model plot.  Switch to next condition.
		if ~strcmp(fig.SelectionType,'normal')
			% Abort if not a normal (left) click.
			return
		end
% 		clicks_ic_timefreq_wide = rem(clicks_ic_timefreq_wide,nconditions) + 1;
		clicks_ic_timefreq_w = clicks_wide;
		data = Condition(clicks_ic_timefreq_w).BE_sout_population;
		IC_surf_w.XData = (0:length(data)-1)/RsFs;
		IC_surf_w.YData = CFs;
		IC_surf_w.ZData = zeros(size(data));
		IC_surf_w.CData = data;
		IC_axes_w.XLim = [0,Condition(clicks_ic_timefreq_w).dur2];
		IC_axes_w.YLim = CF_range;
		max_val = max(arrayfun(@(x)max(x.BE_sout_population(:)),Condition(1:nconditions)));
		caxis(IC_axes_w,[0 max_val])
		% Set the title.
		fmt = 'IC Model (BE Cell): {\\color[rgb]{%.2g,%.2g,%.2g}C%d}';
		title(IC_axes_w,sprintf(fmt,colors{clicks_ic_timefreq_w},clicks_ic_timefreq_w))
		% Make the axes and its colorbar visible.
		IC_axes_w.Visible = 'on';
		IC_model_cb_w.Visible = 'on';
	end

	function next_wide_plots(~,~)
		% Switch to next condition for all wide plots.
		clicks_wide = rem(clicks_wide,nconditions) + 1;
		next_wave_w()
		next_specgram_w()
		next_VIHC_w()
		next_AN_model_w()
		next_IC_model_w()
	end

	function wide_display(h,~)
		% User clicked on "Wide display" checkbox.
		use_wide = logical(h.Value);
		if use_wide
			output_panel_n.Visible = 'off';
			output_panel_w.Visible = 'on';
		else
			output_panel_n.Visible = 'on';
			output_panel_w.Visible = 'off';
		end
	end

	% Save the data.
	function save_data(~,~)
		% Pick a file.
		[f,p] = uiputfile('*.mat','Save As:');
		if isequal(f,0)
			return
		end
		% Save to file.
		save(fullfile(p,f),'CFs','Condition');
	end

	function quickplot(~,~)
		% User clicked on "Quickplot" button.  Make a new figure with selected
		% plots.
		
		CF_plot = str2double(char(PSTH_CFedit.String)) ; % approximate CF to be plotted (Hz)
		[~,CFindex] = min(abs(CFs - CF_plot)); % find CF in population closest to desired CF
% 		[~,CFindex] = min(abs(log(CFs) - log(CF_plot))); % find CF in population closest to desired CF
		
		figure
		ax1 = subplot(3,1,1);
		N = size(Condition(1).an_sout_population,2);
		t = (0:N-1)/RsFs; % time vector for plots
		plot(t,Condition(1).an_sout_population(CFindex,:),'Color',[0 0.7 0])
		title(sprintf('Condition 1: AN fiber, CF = %.4g Hz',CFs(CFindex)))
		ylabel('Spikes/s')
		ax1.YLim(1) = 0;
		if nconditions > 1
			ax2 = subplot(3,1,2);
			N = size(Condition(2).an_sout_population,2);
			t = (0:N-1)/RsFs; % time vector for plots
			plot(t,Condition(2).an_sout_population(CFindex,:),'b')
			ylabel('Spikes/s')
			title(sprintf('Condition 2: AN fiber, CF = %.4g Hz',CFs(CFindex)))
			ax2.YLim(1) = 0;
		end
		
		ax3 = subplot(3,1,3);
		N = size(Condition(1).BE_sout_population,2);
		t = (0:N-1)/RsFs; % time vector for plots
		plot(t,Condition(1).BE_sout_population(CFindex,:),'Color',[0 0.7 0])
		if nconditions > 1
			hold on
			N = size(Condition(2).BE_sout_population,2);
			t = (0:N-1)/RsFs; % time vector for plots
			plot(t,Condition(2).BE_sout_population(CFindex,:),'b')
			title(sprintf('Conditions 1&2: IC BE model, CF = %.4g Hz',CFs(CFindex)))
		else
			title(sprintf('Condition 1: IC BE model, CF = %.4g Hz',CFs(CFindex)))
		end
		hold off
		xlabel('Time (s)')
		ylabel('Spikes/s')
		ax3.YLim(1) = 0;
	end

end


% -------------------
%  Utility functions
% -------------------

function detach_fcn = make_detachable(ax)
%make_detachable: Click on a context menu to copy the axes to a new figure.
%  Syntax:  make_detachable(AXES_HANDLE)
% Author: Doug Schwarz, douglas.schwarz@rochester.edu

parent_fig = ancestor(ax,'figure');
detach_cm = uicontextmenu('Parent',parent_fig);
uimenu(detach_cm,'Label','Detach Plot','Callback',{@detach_plot,ax});
if ~isdeployed
	uimenu(detach_cm,'Label','Export Data to Variable...','Callback',{@export_data,ax});
end
set(ax,'UIContextMenu',detach_cm)
if nargout > 0
	detach_fcn = @(~,~)detach_plot([],[],ax);
end

	function detach_plot(~,~,ax)
		% Copy axes into new figure.
		newfig = figure;
		newax = copyobj(ax,newfig);
		set(newax,'Units','default','Position','default')
		set(newax.Children,'ButtonDownFcn','','HitTest','on')
		txt = findobj(newax,'Type','text');
		set([newax;txt],'FontSize','default')
		set(newax.XLabel,'FontSize','default')
		set(newax.YLabel,'FontSize','default')
		set(newax.Title,'FontSize','default')
		if ~isempty(newax.UserData)
			newax.Title.String = newax.UserData;
		end
		try
			set([newax;txt],'FontSizeMode','default')
		catch
		end
		delete(findobj(newax,'Tag','delete when detached'))
	end

	function export_data(~,~,ax)
		% Export data from axes into a variable in the base workspace.
		children = flip(ax.Children);
		tags = arrayfun(@(x){x.Tag},children);
		vis = arrayfun(@(x){x.Visible},children);
		children(strcmp(tags,'delete when detached') | strcmp(vis,'off')) = [];
		num_children = length(children);
		if num_children == 1 && strcmp(children.Type,'surface')
			prompt = sprintf('%s\n%s\n%s\n%s\n',...
				'Export data for this graph to a structure in the base work-',...
				'space, overwriting any variable by the same name.',...
				'',...
				'Enter variable name:');
			result = inputdlg(prompt,'Export Data');
			if isempty(char(result))
				return
			end
			out = struct('X',children.XData,...
				'Y',children.YData,...
				'Z',children.CData);
			assignin('base',result{1},out)
		elseif all(strcmp({children.Type},'line'))
			prompt = sprintf('%s\n%s\n%s\n%s\n',...
				'Export data for this graph to a structure or structure array in the',...
				'base workspace, overwriting any variable by the same name.',...
				'',...
				'Enter variable name:');
			result = inputdlg(prompt,'Export Data');
			if isempty(char(result))
				return
			end
			out = struct('X',cell(1,num_children),'Y',[]);
			for i = 1:num_children
				out(i) = struct('X',children(i).XData,...
					'Y',children(i).YData);
			end
			assignin('base',result{1},out)
		end
	end
end



function tips_window(~,~,parent_fig)
% Make a tips figure with some useful info.

% Bring existing tips window forward.
tips_fig = findall(groot,'Tag','UR_EAR tips window');
if ~isempty(tips_fig)
	figure(tips_fig)
	movegui(tips_fig)
	return
end

% Set initial figure position.  If handle to parent figure is supplied, center
% the new figure on it, otherwise center it on the screen.
wh = [460 420];
if nargin > 2
	center = parent_fig.Position*[1 0;0 1;0.5 0;0 0.5];
	pos = [center - wh/2,wh];
	use_movegui = false;
else
	pos = [0,0,wh];
	use_movegui = true;
end

% Use standard UI fonts for each platform.
if ispc
	font = struct('FontName','Segoe UI','FontSize',9);
elseif ismac
	font = struct('FontName','Lucida Grande','FontSize',13);
else
	font = struct('FontName','Dialog','FontSize',9);
end

show_tips = getpref('UR_EAR','show_tips',true);

% Create a figure and set default uicontrol font.
% figure (id:001)
tips_fig = figure('Units','pixels',...
	'Position',pos,...
	'DefaultUIControlFontName',font.FontName,...
	'DefaultUIControlFontSize',font.FontSize,...
	'MenuBar','none',...
	'ToolBar','none',...
	'Name','UR_EAR Tips',...
	'NumberTitle','off',...
	'IntegerHandle','off',...
	'Resize','off',...
	'Visible','off',...
	'CloseRequestFcn',@cancel_tips,...
	'Tag','UR_EAR tips window');
if use_movegui
	movegui(tips_fig,'center')
end

if isdeployed
	tip1 = ['Right-click on plots to bring up a menu from which you can ',...
		'detach plots into a new figure.'];
else
	tip1 = ['Right-click on plots to bring up a menu from which you can detach ',...
		'plots into a new figure or export data to a base workspace variable.'];
end
tips = {tip1,...
	'',...
	'Underlined words operate like buttons and can be clicked on.',...
	'',...
	sprintf(['The waveform plot has two vertical gray lines that allow you ',...
	'adjust the analysis window. Click on H%ce%cl%cp (on the main figure) ',...
	'to learn more.'],...
	[863 863 863])};
% edit (id:002)
uicontrol('Style','edit',...
	'Units','pixels',...
	'Position',[40 150 380 230],...
	'String',tips,...
	'Max',2,...
	'HorizontalAlignment','left',...
	'BackgroundColor','w',...
	'Enable','inactive');

% checkbox (id:003)
uicontrol('Style','checkbox',...
	'Units','pixels',...
	'Position',[100 90 265 30],...
	'String','Do not open this window on startup',...
	'Value',~show_tips,...
	'Callback',@set_tips_pref);

% pushbutton (id:004)
uicontrol('Style','pushbutton',...
	'Units','pixels',...
	'Position',[100 35 100 40],...
	'String','OK',...
	'Callback',@ok_tips);

% pushbutton (id:005)
uicontrol('Style','pushbutton',...
	'Units','pixels',...
	'Position',[260 35 100 40],...
	'String','Cancel',...
	'Callback',@cancel_tips);

tips_fig.HandleVisibility = 'off';
tips_fig.Visible = 'on';

% Callbacks

	function set_tips_pref(h,~)
		show_tips = ~logical(h.Value);
	end

	function ok_tips(~,~)
		setpref('UR_EAR','show_tips',show_tips)
		delete(tips_fig)
	end

	function cancel_tips(~,~)
		delete(tips_fig)
	end

end



function help_window(~,~,parent_fig)
% User clicked on Help (underlined blue text).

% Bring existing help window forward.
help_fig = findall(groot,'Tag','UR_EAR help window');
if ~isempty(help_fig)
	figure(help_fig)
	movegui(help_fig)
	return
end

% Set initial figure position.  If handle to parent figure is supplied, center
% the new figure on it, otherwise center it on the screen.
wh = [460 420];
if nargin > 2
	center = parent_fig.Position*[1 0;0 1;0.5 0;0 0.5];
	pos = [center - wh/2,wh];
	use_movegui = false;
else
	pos = [0,0,wh];
	use_movegui = true;
end

% Use standard UI fonts for each platform.
if ispc
	font = struct('FontName','Segoe UI','FontSize',9);
elseif ismac
	font = struct('FontName','Lucida Grande','FontSize',13);
else
	font = struct('FontName','Dialog','FontSize',9);
end

% Create a figure and set default uicontrol font.
% figure (id:001)
help_fig = figure('Units','pixels',...
	'Position',pos,...
	'DefaultUIControlFontName',font.FontName,...
	'DefaultUIControlFontSize',font.FontSize,...
	'MenuBar','none',...
	'ToolBar','none',...
	'Name','UR_EAR Help',...
	'NumberTitle','off',...
	'IntegerHandle','off',...
	'Resize','off',...
	'Visible','off',...
	'CloseRequestFcn',@close_help,...
	'Tag','UR_EAR help window');
if use_movegui
	movegui(tips_fig,'center')
end

% pushbutton (id:004)
uicontrol('Style','pushbutton',...
	'Units','pixels',...
	'Position',[180 35 100 40],...
	'String','OK',...
	'Callback',@close_help);

bullet = @(str)sprintf('%c %s',8226,str);
indent = @(str)sprintf('%c %s',8194,str);
help_str = {['The two vertical gray lines allow you to change the ',...
	'Analysis Window which affects the display range of ',...
	'the AN Model and IC Model plots, and averaging span ',...
	'of the AN Ave. Rate, CN Ave. Rate, and IC Ave. Rate ',...
	'plots.'],...
	'',...
	bullet('Click and drag the lines to change the range.'),...
	bullet('Right-click and drag either line to move both lines'),...
	indent('at the same time, keeping the same span.'),...
	bullet('Click on the numeric display to enter values.'),...
	bullet('Right-click on the numeric display to hold/release'),...
	indent('the analysis window. Holding will preserve the'),...
	indent('values between Runs.'),...
	'',...
	['The default setting is 20 ms on either side ',...
	'of the center of the condition 1 stimulus. ',...
	'You can reset to the default by clicking on ',...
	'Reset, or the Run button.']};
% edit (id:002)
uicontrol('Style','edit',...
	'Units','pixels',...
	'Position',[40 100 380 280],...
	'String',help_str,...
	'Max',2,...
	'HorizontalAlignment','left',...
	'BackgroundColor','w',...
	'Enable','inactive');

help_fig.HandleVisibility = 'off';
help_fig.Visible = 'on';

% Put Callbacks here.

	function close_help(~,~)
		delete(help_fig)
	end

end



function updates_dialog(~,~,program,version,parent_fig)

% Use standard UI fonts for each platform.
if ispc
	font = struct('FontName','Segoe UI','FontSize',9);
elseif ismac
	font = struct('FontName','Lucida Grande','FontSize',13);
else
	font = struct('FontName','Dialog','FontSize',9);
end

check_for_new_version = getpref(program,'check_for_new_version',true);
last_version_check_success = getpref(program,'last_version_check_success',0);
version_check_interval = getpref(program,'version_check_interval',30);

% Set initial figure position.  If handle to parent figure is supplied, center
% the new figure on it, otherwise center it on the screen.
wh = [460 355];
if nargin > 2
	center = parent_fig.Position*[1 0;0 1;0.5 0;0 0.5];
	pos = [center - wh/2,wh];
	use_movegui = false;
else
	pos = [0,0,wh];
	use_movegui = true;
end

% Create a figure and set default uicontrol font.
% figure (id:001)
updates_fig = figure('Units','pixels',...
	'Position',pos,...
	'DefaultUIControlFontName',font.FontName,...
	'DefaultUIControlFontSize',font.FontSize,...
	'MenuBar','none',...
	'ToolBar','none',...
	'Name','UR_EAR Updates',...
	'IntegerHandle','off',...
	'NumberTitle','off',...
	'Resize','off',...
	'WindowStyle','modal',...
	'CloseRequestFcn',@updates_Cancel);
if use_movegui
	movegui(settings_fig,'center')
end

% text (id:002)
uicontrol('Style','text',...
	'Units','pixels',...
	'Position',[40 260 380 60],...
	'String',['This program can check for a newer version of itself on ',...
	'startup. If it finds one, the Carney Lab web site will be opened in ',...
	'your system browser.'],...
	'HorizontalAlignment','left',...
	'BackgroundColor',updates_fig.Color);

if last_version_check_success == 0
	check_date = '<Never checked>';
else
	check_date = datestr(last_version_check_success);
end
% text (id:003)
last_check_text = uicontrol('Style','text',...
	'Units','pixels',...
	'Position',[40 235 295 20],...
	'String',sprintf('Last successful check: %s',check_date),...
	'HorizontalAlignment','left',...
	'BackgroundColor',updates_fig.Color);

% checkbox (id:007)
uicontrol('Style','checkbox',...
	'Units','pixels',...
	'Position',[100 185 135 20],...
	'String','Auto check every',...
	'Value',check_for_new_version,...
	'Callback',@toggle_check);

% edit (id:005)
uicontrol('Style','edit',...
	'Units','pixels',...
	'Position',[240 180 60 30],...
	'String',sprintf('%d',version_check_interval),...
	'HorizontalAlignment','center',...
	'BackgroundColor','w',...
	'Callback',@set_check_interval);

% text (id:006)
uicontrol('Style','text',...
	'Units','pixels',...
	'Position',[305 185 35 20],...
	'String','days',...
	'HorizontalAlignment','left',...
	'BackgroundColor',updates_fig.Color);

% pushbutton (id:008)
uicontrol('Style','pushbutton',...
	'Units','pixels',...
	'Position',[160 115 140 40],...
	'String','Check Now',...
	'Callback',@check_updates_now);

% pushbutton (id:009)
uicontrol('Style','pushbutton',...
	'Units','pixels',...
	'Position',[90 45 100 40],...
	'String','OK',...
	'Callback',@updates_OK);

% pushbutton (id:010)
uicontrol('Style','pushbutton',...
	'Units','pixels',...
	'Position',[270 45 100 40],...
	'String','Cancel',...
	'Callback',@updates_Cancel);

% Callbacks:

	function set_check_interval(h,~)
		version_check_interval = str2double(h.String);
	end

	function toggle_check(h,~)
		check_for_new_version = logical(h.Value);
	end

	function check_updates_now(h,~)
		h.Enable = 'off';
		updates_fig.Pointer = 'watch';
		drawnow
		last_version_check_success = getpref(program,'last_version_check_success',0);
		version_check_interval = getpref(program,'version_check_interval',30);
		timeout = 5;
		today = floor(now);
		url = 'https://www.urmc.rochester.edu/labs/carney.aspx';
		try
			page = webread(url,weboptions('Timeout',timeout));
			online_version = regexp(page,'UR_EAR_(\d{4}[a-z])\.zip','tokens','once');
			if isempty(online_version)
				uiwait(errordlg('Link to UR_EAR not found. Check with author.'))
				updates_fig.Pointer = 'arrow';
				h.Enable = 'on';
				return
			end
			[~,order] = sort({char(online_version),version});
			if isequal(order,[2 1])
				web(url)
			end
			last_check_text.String = sprintf('Last successful check: %s',datestr(today));
			setpref(program,'last_version_check_success',today);
		catch
		end
		updates_fig.Pointer = 'arrow';
		h.Enable = 'on';
	end

	function updates_OK(~,~)
		setpref(program,'check_for_new_version',check_for_new_version)
		setpref(program,'version_check_interval',version_check_interval)
		delete(updates_fig)
	end

	function updates_Cancel(~,~)
		delete(updates_fig)
	end

end
