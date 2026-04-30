classdef (CaseInsensitiveProperties, TruncatedProperties, ConstructOnLoad) ...
		uibar < matlab.mixin.SetGet
	%uibar: A colored bar (waitbar) that can be embedded in a GUI.
	%   b = uibar(...) will create a colored bar in the current figure,
	%   much like adding a uicontrol to a figure.  Change the length of the
	%   colored region by setting the 'Value' property.
	%
	%   The resulting object is a subclass of the handle class.
	%
	%   uibar(PARENT,...) creates a uibar in the specified figure or
	%   uipanel.
	%
	%   uibar property/value pairs can be specified as arguments when the
	%   object is created or by using the set function, very much like
	%   Handle Graphics objects.  You can also use the dot notation, e.g.,
	%   b.Value = 0.5;  Use get() or dot notation to get uibar properties.
	%
	%   The following properties (and their default values) are available:
	%
	%       BackgroundColor = [1 1 1]
	%       BorderColor = [0 0 0]
	%       CurrentMouseValue (Read-only)
	%       Direction = 'east' or 'north' depending on Position and DirectionMode
	%       DirectionMode = 'auto'
	%       ForegroundColor = [1 0 0]
	%       LineWidth = 0.5
	%       Max = 1
	%       Min = 0
	%       Position = [20 20 200 15]
	%       Units = 'pixels'
	%       Value = 0
	%
	%       ButtonDownFcn
	%       DeleteFcn
	%       HitTest = 'on'
	%       Parent
	%       Selected = 'off'
	%       SelectionHighlight = 'on'
	%       Type = 'uibar' (Read-only)
	%       UIContextMenu
	%       UserData
	%       Visible = 'on'
	%
	%   See also SET, GET.
	
	
	% Version: 2.0, 10 July 2017
	% Author:  Douglas M. Schwarz
	% Email:   dmschwarz=ieee*org, dmschwarz=urgrad*rochester*edu
	% Real_email = regexprep(Email,{'=','*'},{'@','.'})
	
	% Note: The class attributes CaseInsensitiveProperties and
	% TruncatedProperties are undocumented.  Should this class ever fail to
	% work because those attributes have been removed or changed, simply
	% delete them from the classdef line:
	% classdef (ConstructOnLoad) uibar < matlab.mixin.SetGet
	% You will no longer be able to abbreviate or use all lower-case
	% property names, but everything will work.
	
	properties
		% Color of unfilled region, ColorSpec or 'none', default = 'w'
		BackgroundColor = [1 1 1];
		
		% Color of border, ColorSpec or 'none', default = 'k'
		BorderColor = [0 0 0];
	end
	
	properties (SetAccess = protected, Transient)
		% Location in Value units where mouse clicked (read only)
		CurrentMouseValue = 0;
	end
	
	properties (Dependent)
		% Filling direction, 'east' if bar lengthens to the right, etc.
		Direction
	end
	
	properties
		% Set Direction automatically ('auto') or manually ('manual')
		DirectionMode = 'auto';
		
		% Color of filled region, ColorSpec or 'none', default = 'r'
		ForegroundColor = [1 0 0];
		
		% Width of the border in points, default = 0.5 points
		LineWidth = 0.5;
		
		% Value for which uibar is completely filled in, default = 1
		Max = 1;
		
		% Value for which uibar is completely open, default = 0
		Min = 0;
		
		% Size and location of uibar, default = [20 20 200 15]
		Position = [20 20 200 15];
		
		% Position units, default = 'pixels'
		Units = 'pixels';
	end
	
	properties (SetObservable)
		% Length of uibar relative to Min and Max, default = 0
		Value = 0;
	end
	
	properties
		% Button-press callback function
		ButtonDownFcn = [];
		
		% Function executed upon object deletion
		% Must be a function handle, string, or cell array containing a
		% function handle.  If a function handle, the function must be
		% written to accept two inputs, the handle to the uibar object and
		% an unused argument.  Additional arguments can be supplied by
		% using a cell array, e.g., {@fcn,'argument 3'}.
		DeleteFcn = [];
		
		% Whether selectable by mouse click
		HitTest = 'on';
	end
	
	properties (Transient)
		% uibar parent, must be figure or uipanel object
		Parent
	end
	
	properties
		% Whether uibar is selected
		Selected = 'off';
		
		% Whether object is highlighted when selected
		SelectionHighlight = 'on';
	end
	
	properties (Constant)
		% Class of object, always 'uibar'
		Type = mfilename;
	end
	
	properties
		% Context menu associated with uibar
		UIContextMenu = [];
		
		% User-specified data
		UserData = [];
		
		% Visibility of uibar
		Visible = 'on';
	end
	
	properties (Hidden, Access = private, Transient)
		DirectionPrivate = 'east';
		AxesHandle = [];
		PatchBackground = [];
		PatchForeground = [];
		PatchBorder = [];
		Patches = [];
	end
	
	properties (Hidden, Access = private)
		isHorizontal = true;
		dynamic = 'XData';
	end
	
	
	methods
		
		% Constructor.
		function obj = uibar(varargin)
			%Create a uibar object.
			% A uibar is a simple colored bar whose length can be set with
			% the Value property.  Other properties control the location
			% and appearance.  It can be used as a waitbar that is embedded
			% in a figure rather than appearing on a separate figure, but
			% is also suitable for other purposes.
			%
			% Syntax:
			%   uibar('Property1',value1,'Property2',value2,...) creates a
			%   colored bar in the current figure with the specified
			%   property values and returns a uibar object.
			%
			%   uibar(parent,...) creates a uibar as above with the
			%   specified parent (must be a figure or uipanel).
			%
			%   uibar properties can be set at object creation and/or by
			%   using the set function and/or by assigning values to
			%   properties:
			%     uibar_obj = uibar('ForegroundColor','b');
			%     set(uibar_obj,'Value',0.5)
			%     uibar_obj.Max = 100;
			
			% Enclose everything in a try-catch construct so graphic
			% objects can be deleted if an error occurs.
			try
				
				% If first argument is a figure or uipanel handle, use it
				% as the parent of the uibar, then delete it from the
				% argument list.  Otherwise use the current figure as the
				% parent.
				if nargin == 0
					obj.Parent = gcf;
				else
					arg1 = varargin{1};
					if ischar(arg1)
						obj.Parent = gcf;
					elseif isscalar(arg1) && ishandle(arg1) && ...
							ismember(arg1.Type,{'figure','uipanel'})
						obj.Parent = arg1;
						varargin(1) = [];
					else
						error('Invalid figure or uipanel handle')
					end
				end
				
				% A uibar consists of a small axes that contains three
				% patches for the background, foreground and border and the
				% length of the foreground patch is adjusted according to
				% the Value property of the uibar object.  The four graphic
				% objects are created here with suitable property values.
				
				% Set the DeleteFcn of the axes so that the uibar object
				% will be deleted if the axes is deleted (for example, if
				% the parent figure or uipanel is deleted).
				obj.AxesHandle = axes( ...
					'Parent',obj.Parent,...
					'Units',obj.Units,...
					'Position',obj.Position,...
					'XDir','normal',...
					'XLim',[obj.Min obj.Max],'YLim',[0 1],...
					'XTick',[],'YTick',[],...
					'Color','none',...
					'XColor','none',...
					'YColor','none',...
					'ButtonDownFcn',obj.ButtonDownFcn,...
					'DeleteFcn',@(~,~)delete(obj),...
					'HitTest','on',...
					'HandleVisibility','off',...
					'UIContextMenu',[],...
					'UserData',[],...
					'Visible','on');
				
				obj.PatchBackground = patch( ...
					'Parent',obj.AxesHandle,...
					'XData',[obj.Min([1 1]),obj.Max([1 1])],...
					'YData',[0 1 1 0],...
					'FaceColor',obj.BackgroundColor,...
					'EdgeColor','none',...
					'HitTest','off',...
					'ButtonDownFcn',[],...
					'HandleVisibility','off',...
					'UserData',[],...
					'Visible',obj.Visible);
				
				obj.PatchForeground = patch( ...
					'Parent',obj.AxesHandle,...
					'XData',[obj.Min([1 1]),obj.Value([1 1])],...
					'YData',[0 1 1 0],...
					'FaceColor',obj.ForegroundColor,...
					'EdgeColor','none',...
					'HitTest','off',...
					'Clipping','on',...
					'ButtonDownFcn',[],...
					'HandleVisibility','off',...
					'UserData',[],...
					'Visible',obj.Visible);
				
				obj.PatchBorder = patch( ...
					'Parent',obj.AxesHandle,...
					'XData',[obj.Min([1 1]),obj.Max([1 1])],...
					'YData',[0 1 1 0],...
					'FaceColor','none',...
					'EdgeColor',obj.BorderColor,...
					'HitTest','off',...
					'ButtonDownFcn',[],...
					'Selected',obj.Selected,...
					'SelectionHighlight',obj.SelectionHighlight,...
					'HandleVisibility','off',...
					'UserData',[],...
					'Visible',obj.Visible);
				
				obj.Patches = [obj.PatchBackground,...
					obj.PatchForeground,obj.PatchBorder];
				
				% Set the property values.
				if ~isempty(varargin)
					set(obj,varargin{:})
				end
				
			catch err
				% Cancel the DeleteFcn and delete the axes if there are any
				% errors.
				obj.DeleteFcn = [];
				if ishandle(obj.AxesHandle)
					delete(obj.AxesHandle)
				end
				rethrow(err)
			end
			
		end % constructor
		
		%-----------------------------------------------------------
		
		function delete(obj)
			% Run the object DeleteFcn.
			if ~isempty(obj.DeleteFcn)
				if isa(obj.DeleteFcn,'function_handle')
					feval(obj.DeleteFcn,obj,[])
				elseif iscell(obj.DeleteFcn)
					feval(obj.DeleteFcn{1},obj,[],obj.DeleteFcn{2:end})
				elseif ischar(obj.DeleteFcn)
					eval(obj.DeleteFcn)
				end
			end
			% If the axes still exists and isn't already in the process of
			% being deleted, cancel its DeleteFcn (which is set to run this
			% function) and then delete it.
			if ~isempty(obj.AxesHandle) && ishandle(obj.AxesHandle) && ...
					strcmp(obj.AxesHandle.BeingDeleted,'off')
				obj.AxesHandle.DeleteFcn = [];
				delete(obj.AxesHandle)
			end
		end
		
		%-----------------------------------------------------------
		
		function set.BackgroundColor(obj,value)
			obj.PatchBackground.FaceColor = value; %#ok<*MCSUP>
			obj.BackgroundColor = obj.PatchBackground.FaceColor;
		end
		
		%-----------------------------------------------------------
		
		function set.BorderColor(obj,value)
			obj.PatchBorder.EdgeColor = value;
			obj.BorderColor = obj.PatchBorder.EdgeColor;
		end
		
		%-----------------------------------------------------------
		
		function value = get.CurrentMouseValue(obj)
			if obj.isHorizontal
				value = obj.AxesHandle.CurrentPoint(1,1);
			else
				value = obj.AxesHandle.CurrentPoint(1,2);
			end
		end
		
		%-----------------------------------------------------------
		
		function value = get.Direction(obj)
			value = obj.DirectionPrivate;
		end
		
		%-----------------------------------------------------------
		
		function set.Direction(obj,value)
			switch value
				case 'east'
					obj.isHorizontal = true;
					obj.AxesHandle.XDir = 'normal';
					obj.AxesHandle.YDir = 'normal';
				case 'west'
					obj.isHorizontal = true;
					obj.AxesHandle.XDir = 'reverse';
					obj.AxesHandle.YDir = 'normal';
				case 'north'
					obj.isHorizontal = false;
					obj.AxesHandle.XDir = 'normal';
					obj.AxesHandle.YDir = 'normal';
				case 'south'
					obj.isHorizontal = false;
					obj.AxesHandle.XDir = 'normal';
					obj.AxesHandle.YDir = 'reverse';
				otherwise
					fmt = ['Error setting property ''Direction'' ',...
						'of class ''uibar'':\n''%s'' is not a valid ',...
						'value. Use one of these values: ',...
						'''east'' | ''west'' | ''north'' | ''south''.'];
					error(fmt,value)
			end
			obj.DirectionPrivate = value;
			obj.DirectionMode = 'manual';
			
			% Run the set.Position() method to set the direction properly.
			obj.Position = obj.Position;
		end
		
		%-----------------------------------------------------------
		
		function set.DirectionMode(obj,value)
			obj.DirectionMode = value;
			switch value
				case 'auto'
					% Run the set.Position() method to set the direction
					% properly.
					obj.Position = obj.Position;
				case 'manual'
				otherwise
					fmt = ['Error setting property ''DirectionMode'' ',...
						'of class ''uibar'':\n''%s'' is not a valid ',...
						'value. Use one of these values: ',...
						'''auto'' | ''manual''.'];
					error(fmt,value)
			end
		end
		
		%-----------------------------------------------------------
		
		function set.ForegroundColor(obj,value)
			obj.PatchForeground.FaceColor = value;
			obj.ForegroundColor = obj.PatchForeground.FaceColor;
		end
		
		%-----------------------------------------------------------
		
		function set.LineWidth(obj,value)
			obj.LineWidth = value;
			obj.PatchBorder.LineWidth = value;
		end
		
		%-----------------------------------------------------------
		
		function set.Max(obj,value)
			obj.Max = value;
			if obj.isHorizontal
				obj.AxesHandle.XLim(2) = value;
				obj.PatchBorder.XData(3:4) = value;
				obj.PatchBackground.XData(3:4) = value;
			else
				obj.AxesHandle.YLim(2) = value;
				obj.PatchBorder.YData(3:4) = value;
				obj.PatchBackground.YData(3:4) = value;
			end
		end
		
		%-----------------------------------------------------------
		
		function set.Min(obj,value)
			obj.Min = value;
			if obj.isHorizontal
				obj.AxesHandle.XLim(1) = value;
				obj.PatchBorder.XData(1:2) = value;
				obj.PatchBackground.XData(1:2) = value;
				obj.PatchForeground.XData(1:2) = value;
			else
				obj.AxesHandle.YLim(1) = value;
				obj.PatchBorder.YData(1:2) = value;
				obj.PatchBackground.YData(1:2) = value;
				obj.PatchForeground.YData(1:2) = value;
			end
		end
		
		%-----------------------------------------------------------
		
		function set.Position(obj,value)
			obj.Position = value;
			obj.AxesHandle.Position = value;
			
			% Get Position in pixel units to determine if uibar should
			% be horizontal or vertical.  If it is taller than it is wide,
			% make it vertical, otherwise make it horizontal.
			if strcmp(obj.DirectionMode,'auto')
				units = obj.AxesHandle.Units;
				obj.AxesHandle.Units = 'pixels';
				obj.AxesHandle.Units = units;
				obj.isHorizontal = diff(obj.AxesHandle.Position(3:4)) < 0;
			end
			
			if obj.isHorizontal
				obj.dynamic = 'XData';
				set(obj.AxesHandle,'XLim',[obj.Min obj.Max],...
					'YLim',[0 1])
				set([obj.PatchBorder obj.PatchBackground],...
					'XData',[obj.Min([1 1]),obj.Max([1 1])],...
					'YData',[0 1 1 0])
				set(obj.PatchForeground,...
					'XData',[obj.Min([1 1]),obj.Value([1 1])],...
					'YData',[0 1 1 0])
				obj.DirectionPrivate = 'east';
			else
				obj.dynamic = 'YData';
				set(obj.AxesHandle,'YLim',[obj.Min obj.Max],...
					'XLim',[0 1])
				set([obj.PatchBorder obj.PatchBackground],...
					'YData',[obj.Min([1 1]),obj.Max([1 1])],...
					'XData',[0 1 1 0])
				set(obj.PatchForeground,...
					'YData',[obj.Min([1 1]),obj.Value([1 1])],...
					'XData',[0 1 1 0])
				obj.DirectionPrivate = 'north';
			end
		end
		
		%-----------------------------------------------------------
		
		function set.Units(obj,value)
			obj.AxesHandle.Units = value;
			obj.Units = value;
			obj.Position = obj.AxesHandle.Position;
		end
		
		%-----------------------------------------------------------
		
		function set.Value(obj,value)
			obj.Value = min(max(value,obj.Min),obj.Max);
			obj.PatchForeground.(obj.dynamic)(3:4) = value;
			drawnow('expose')
		end
		
		%-----------------------------------------------------------
		
		function set.ButtonDownFcn(obj,value)
			switch class(value)
				case 'function_handle'
					obj.ButtonDownFcn = @(h,evt)value(obj,[]);
				case 'cell'
					obj.ButtonDownFcn = ...
						@(h,evt,varargout)value{1}(obj,[],value{2:end});
				case 'char'
					obj.ButtonDownFcn = value;
				case 'double'
					if isempty(value)
						obj.ButtonDownFcn = value;
					else
						error(['ButtonDownFcn must be a string, a ',...
							'function handle, or a cell array ',...
							'containing a function handle'])
					end
				otherwise
					error(['ButtonDownFcn must be a string, a ',...
						'function handle, or a cell array ',...
						'containing a function handle'])
			end
			obj.AxesHandle.ButtonDownFcn = obj.ButtonDownFcn;
		end
		
		%-----------------------------------------------------------
		
		function set.DeleteFcn(obj,value)
			switch class(value)
				case 'function_handle'
					obj.DeleteFcn = @(h,evt)value(obj,[]);
				case 'cell'
					obj.DeleteFcn = ...
						@(h,evt,varargout)value{1}(obj,[],value{2:end});
				case 'char'
					obj.DeleteFcn = value;
				case 'double'
					if isempty(value)
						obj.DeleteFcn = value;
					else
						error(['DeleteFcn must be a string, a ',...
							'function handle, or a cell array ',...
							'containing a function handle'])
					end
				otherwise
					error(['DeleteFcn must be a string, a ',...
						'function handle, or a cell array ',...
						'containing a function handle'])
			end
		end
		
		%-----------------------------------------------------------
		
		function set.HitTest(obj,value)
			obj.AxesHandle.HitTest = value;
			obj.HitTest = obj.AxesHandle.HitTest;
		end
		
		%-----------------------------------------------------------
		
		function set.Parent(obj,value)
			obj.Parent = value;
			obj.AxesHandle.Parent = value;
		end
		
		%-----------------------------------------------------------
		
		function set.Selected(obj,value)
			obj.AxesHandle.Selected = value;
			obj.Selected = obj.AxesHandle.Selected;
		end
		
		%-----------------------------------------------------------
		
		function set.SelectionHighlight(obj,value)
			obj.AxesHandle.SelectionHighlight = value;
			obj.SelectionHighlight = obj.AxesHandle.SelectionHighlight;
		end
		
		%-----------------------------------------------------------
		
		function set.UIContextMenu(obj,value)
			obj.UIContextMenu = value;
			obj.AxesHandle.UIContextMenu = value;
		end
		
		%-----------------------------------------------------------
		
		function set.Visible(obj,value)
			set(obj.Patches,'Visible',value)
			obj.AxesHandle.Visible = value;
			obj.Visible = obj.AxesHandle.Visible;
		end
		
	end % methods
	
end % classdef
