function [figh, Mess]=StimGUI(StimName, EXP, varargin);
% StimGUI - open stimulus GUI
%    StimGUI('Foo') opens stimulus GUI for stimulus paradigm Foo and
%    returns a handle to it. By convention, the stimulus-specific work is 
%    delegated to the function stimdefFoo in the path returned by the 
%    function StimDefPath. The Uhr example is stimdefFS. The name of te
%    stimulus paradigm (Foo in the above example) must be a valid Matlab
%    identifier, as tested by VARNAME. 
%
%    StimGUI('Foo', EXP) applies experiment definition EXP instead of the 
%    current experiment.
%
%    [h, Mess]=StimGUI(..) suppresses error message due to non-existing
%    stimulus paradigms and returns the error in char Mess instead. 
%
%    See also StimDefPath, stimdefFS, Experiment/edit.

% callbacks
if isempty(StimName) || isSingleHandle(StimName), % action call, e.g., okay = StimGUI(figh, 'Check')
    figh = StimName; if isempty(figh), figh=gcbf; end; % default is parent fig of clicked button; may be overruled by explicit arg
    if ~isa(figh,'double')
        figh = figh.Number;
    end;
    kw = lower(EXP); % keyword
    if nargin>2 && isequal('Right', varargin{1}), return; end; % ignore right-click
    Mess = feval(['local_' kw], figh, varargin{:});
    return;
end
% launch a stim menu
if ~isvarname(StimName),
    error(['Invalid stimulus name ''' StimName '''. Names must be valid Matlab identifiers (see VARNAME).']);
end
StimName = upper(StimName);
if nargin<2,
    EXP = current(experiment);
    if isvoid(EXP),
        EXP = find(experiment,'StimOnly');
    end
end
if isvoid(EXP),
    error('No valid experiment defined; no default (StimOnly) experiment found, either.');
end

%GUIcolor = stimGUIcolor(StimName);

% check whether stimdefFoo.m (stimulus definition mfile) exists and has correct location
% check whether makestimFoo.m (stimulus generation mfile) exists and has correct location
figh = [];
StimDef = ['stimdef' StimName];
StimMake = ['makestim' StimName];
Mess=local_CheckStimfile(StimDef, StimName, 'Stimulus definition'); 
if nargout>1 && ~isempty(Mess), return; else, error(Mess); end
% Mess=local_CheckStimfile(StimMake, StimName, 'Stimulus generator'); 
% if nargout>1 && ~isempty(Mess), return; else, error(Mess); end

% create param part of GUI. Delegate to stimdefXXX
Params = feval(fhandle(['stimdef' StimName]), EXP); % Params = stimdefXXX(EXP);

Pfile = StimGuiFilePulldown;
Pedit = StimGuiEditPulldown;
Pview = StimGuiViewPulldown;



%-----------the whole GUI-----------------
SG=GUIpiece([StimName 'Menu'],[],[0 0],[10 4]);
SG = add(SG, Pfile);
SG = add(SG, Pedit);
SG = add(SG, Pview);
SG = add(SG, Params);
SG = add(SG, local_Action(StimName), 'below', [20 10]);
SG = add(SG, local_Dataview(StimName), 'nextto', [10 0]);
SG=marginalize(SG,[0 20]);


% code to create new menu item with sub items
%             SG2=GUIpiece([StimName 'dashMenu'],[],[0 0],[10 4]);
%             Ptest=pulldownmenu('Stim','&Stim');
%             Ptest=additem(Ptest,Pfile);
%             Ptest=additem(Ptest,Pedit);
%             Ptest=additem(Ptest,Pview);
%             Ptest=additem(Ptest,Pview);
%             Ptest=additem(Ptest,Pview);
%             SG2 = add(SG2, Ptest);
%             dashboard_panels = getGUIdata(varargin{1},'Panels');
%             Exp_Panel = dashboard_panels(4);
%             pos = Exp_Panel.LowRightMargins + Exp_Panel.Extent;
%             SG2 = add(SG2, Params,'below', pos);
%             Act = local_Action();
%             SG2 = add(SG2, Act, 'below Params', [20 10]);
%             SG2 = add(SG2, local_Dataview, 'below Act', [10 0]);
%             SG2=marginalize(SG2,[0 20]);


% open figure and draw GUI in it
figh = newGUI([StimName 'menu'], [StimName ' menu     Experiment: ' name(EXP)], {fhandle(mfilename), StimName, EXP});
setGUIdata(figh, 'StimMaker', fhandle(StimMake));
setGUIdata(figh, 'StimulusType', StimName);
CreateQueryContextMenu(figh,ParamQuery);
draw(figh, SG); 
% next line commented out to avoid annoying overlap w dashboard. pprevious GUI positition is restored. MH July 2019
% movegui(figh,'center'); % center the stim gui on the screen, added by Jan 2018


%             setGUIdata(varargin{1}, 'StimMaker', fhandle(StimMake));
%             setGUIdata(varargin{1}, 'StimulusType', StimName);
%             CreateQueryContextMenu(varargin{1},ParamQuery);
%             % Check if the dashboard already has the stimulus menu
%             menus = getGUIdata(varargin{1},'PulldownMenu'); 
%             hasStimMenu = 0;
%             for i=1:length(menus)
%                 if strcmp(menus(i).Name,'Stim')
%                    hasStimMenu = 1; 
%                 end
%             end    
% 
%             if hasStimMenu == 0
%                 draw(varargin{1}, SG2); 
%             end
setGUIdata(figh, 'Experiment', EXP);
% empty all edit fields & message field
Q = getGUIdata(figh, 'Query');
clearedit(Q);
% Main message empty
GUImessage(figh, ' ','neutral');
% RMS message empty
M = find(messenger(), figh, 'RMSDisp1');
report(M,'');
% reload any previous pameters
GUIfill(figh,0,0);
% open figure and draw GUI in it

%===================================
function Act = local_Action(StimName)
% Check/Play/PlayRec dashboard
Act = GUIpanel('Act', '', 'backgroundcolor', 0.75+[0 0.1 0.05]);
MessBox = messenger('@MessBox', 'The problem is what you think the problem is         ',7, ... % the '@' in the name indicates that ...
    'fontsize', 12, 'fontweight', 'bold'); % MessBox will be the Main Messenger of he GUI
FsamDisp = messenger('FsamDisp', 'Fsam = ***.* kHz', 1, 'FontWeight', 'bold', 'ForegroundColor', [0.25 0.15 0.1]);
RMSDisp1 = messenger('RMSDisp1', 'C rms = **.* mV', 1, 'FontWeight', 'bold', 'ForegroundColor', [0.25 0.15 0.1]);
RMSDisp2 = messenger('RMSDisp2', 'C rms = **.* mV', 1, 'FontWeight', 'bold', 'ForegroundColor', [0.25 0.15 0.1]);
Check = ActionButton('Check', 'CHECK', 'XXXXXXXXXX', 'Check stimulus parameters and update information.', fhandle('StimCheck'));
Check = accelerator(Check,'&Action', 'K');

% Gowtham 7/9/20: If THR is used, REC and Play buttons will not be added to the GUI
if ~strcmp(StimName,'THR')
    [EE, dashboard_handle] = existGUI('dashboard'); StartRec = @(Src,Ev, LR)dashboard('PlayRecord', 'Left', dashboard_handle);
    Rec = ActionButton('PlayRec', 'REC', 'XXX', 'Start recording.', StartRec, 'BackgroundColor', [1 0 0]);
    StartPlay = @(Src,Ev, LR)dashboard('Play', 'Left', dashboard_handle);
    PlayBut = ActionButton('Play', 'Play', 'XXX', 'Start playing.', StartPlay);
end

Act = add(Act,MessBox);
Act = add(Act,FsamDisp, 'nextto', [32 3]);
Act = add(Act,RMSDisp1, 'below', [0 3]);
Act = add(Act,RMSDisp2, 'below', [0 3]);
Act = add(Act,Check, 'below', [0 35]);

% Gowtham 7/9/20: If THR is used, REC and Play buttons will not be added to the GUI
if ~strcmp(StimName,'THR')
    Act = add(Act,Rec, 'nextto', [0 0]); % added option to launch recording from stim menu
    Act = add(Act,PlayBut, 'nextto', [0 0]);
end
Act = marginalize(Act,[3 5]);

% function D = local_Dataview;
% % Dataview panel
% D = GUIpanel('Dataview', 'data view');
% DVlist = listdataviewer(dataset()); % list of dataviewers plus '-' entry == none
% Viewer = paramquery('Dataviewer', 'viewer:', '', [DVlist '-'], ...
%     '', 'Select or deselect viewer for online data analysis by clicking the toggle.');
% Pfile = paramquery('DataviewerParamfile', 'file:', 'XXXXXXXXXX', '', ...
%     'varname', 'Provide filename for online dataviewer parameters. "Def" means: use default parameters.', 128);
% EditPV = actionButton('EditDVparams', 'Edit', '----', 'Edit dataviewer parameter values.', ...
%     @(Src,Ev,LR)local_edit(Src, name(Pfile), name(Viewer)));
% % Check = accelerator(Check,'&Action', 'K');
% D = add(D,Viewer);
% D = add(D,Pfile,'below');
% D = add(D,EditPV,'nextto',[-5 0]);
% D = marginalize(D,[0 5]);

function D = local_Dataview(StimType);
% Dataview panel
D = GUIpanel('Dataview', 'data view');
DVlist = listdataviewerfor(dataset(),StimType);
Viewer = ParamQuery('Dataviewer', 'viewer:', '', [{'-', 'active'}, DVlist], ...
    '', 'Activate dataviewer(s) for online data analysis by clicking the toggle.');
Dataviewers = ActionButton('Dataviewers', 'dataviewers', 'dataviewers',...
    'Select dataviewer(s) for online data analysis.',@(Src,Ev,LR)local_dataviewers(Src, name(Viewer)));
% No editable value for this thing
Pfile = ParamQuery('DataviewerParamfile', 'file:', 'def', '', ...
    'string', 'Provide filename(s) for online dataviewer(s) parameters. "def" means: use default parameters.', 1024);
% This should now offer a parameter filename for every dataviewer
EditPV = ActionButton('EditDVparams', 'edit', 'edit', 'Edit dataviewer(s) parameter values.', ...
    @(Src,Ev,LR)local_edit(Src, name(Pfile), name(Viewer)));
datagraze_analog = ParamQuery('Analog_visualization', 'analog viewer:', '', {'-', 'active'}, ...
    '', 'Activate analog sampled dataviewer(s) for online data analysis by clicking the toggle.');
D = add(D,Viewer);
D = add(D,Dataviewers,'nextto');
D = add(D,Pfile,'below Dataviewer');
D = add(D,EditPV,'nextto');
D = add(D,datagraze_analog,'below DataviewerParamfile');
D = marginalize(D,[0 5]);

function local_dataviewers(Src, nameQ_Viewer); 
% Select (multiple) dataviewers for online analysis.
figh = parentfigh(Src);
figh = figh.Number;
GUImessage(figh, ' ');
Q = getGUIdata(figh, 'Query');
[Viewer, ~, Mess, hViewerEdit] = read(Q(nameQ_Viewer));
if isequal('-', Viewer),
    GUImessage(figh, {'Viewer(s) are not in use;', 'toggle the viewer button.'}, 'error');
    return;
end
StimType = getGUIdata(figh, 'StimulusType');
DVlist = [{'-'}, listdataviewerfor(dataset(),StimType)]; % list of applicable dataviewers
[S,okay] = listdlg('ListString', DVlist,...
                'SelectionMode','multiple',...
                'Name','dataviewers',...
                'ListSize', [200 300],...
                'PromptString',...
                {'Select viewer(s) for online data analysis:','(Use Ctrl for multiple viewers)'});
if ~okay
    GUImessage(figh, 'No viewer specified.', 'error');
    set(hViewerEdit, 'string', '-');
    return;
end
ViewerEditStr = '';
for i=1:numel(S)
    ViewerEditStr = [ViewerEditStr ' ' DVlist{S(i)}];
end
set(hViewerEdit, 'string', ViewerEditStr(2:end)); % get rid of first whitespace

function Mess=local_CheckStimfile(fn, StimName, Descr);
% check whether mfile exists, is unique, and has correct location
Mess = '';
FN = searchInPath([fn '.m'], stimdefPath, 'file');
if isempty(FN),
    Mess = [Descr ' of ''' StimName ''' stimulus not found. See StimGUI for naming conventions.'];
end


function  local_edit(Src, nameQ_Pfile, nameQ_Viewer);
% dataviewer param edit button: edit the parameters. Clicking the edit
% button does not depend on the "Check status" of the GUI, so the stimulus
% params are not considered here. Instead, this fcn only uses the 
% Dataviewer and DataviewerParamfile queries and the identity of the
% stimulus GUI.
figh = parentfigh(Src);
figh = figh.Number;
GUImessage(figh, ' ');
Q = getGUIdata(figh, 'Query');
Viewer = read(Q(nameQ_Viewer));
if isequal('-', Viewer) || isequal('active', Viewer), % No dataviewers specified yet.
    GUImessage(figh, {'No dataviewer specified;', ...
        'cannot edit its parameters.'}, 'error');
    return;
end
DVlist = regexp(Viewer,' ','split');
[Pfile, ~, Mess, hFileEdit] = read(Q(nameQ_Pfile), 'coloredit');
if ~isempty(Mess),
    GUImessage(figh, Mess, 'error');
    return;
end
if isempty(Pfile), Pfile = 'def'; end;
if isequal('def', Pfile),
    Pfile = cell(size(DVlist));
    Pfile(:) = {'def'};
else
    Pfile = regexp(Pfile,' ','split');
end
FileEditStr = '';
for iviewer=1:numel(DVlist)
    viewer = DVlist{iviewer};
    DVP = load(dataviewparam(), viewer, '?', Pfile{iviewer}); % Pfile is default
    if isvoid(DVP),
        GUImessage(figh, ['Editing ' viewer ' parameters cancelled.'], 'warning');
        continue;
    end
    DVP = edit(DVP);
    if isvoid(DVP),
        GUImessage(figh, ['Editing ' viewer ' parameters cancelled.'], 'warning');
        continue;
    end
    [saved, FN] = save(DVP, '?', Pfile{iviewer}); % prompt user to save ; use fn as default
    if saved,
        [dum,fn] = fileparts(FN); % no dir ...
        fn = strtok(fn,'.'); % ... no extension
        GUImessage(figh, [viewer ' parameters saved to file ''' fn '''.']);
        FileEditStr = [FileEditStr ' ' fn];
    else,
        GUImessage(figh, ['Saving ' viewer ' parameters cancelled.'], 'warning');
    end
end
set(hFileEdit, 'string', FileEditStr(2:end));




