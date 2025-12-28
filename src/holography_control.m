% =========================================================================
% File: holography_control.m
% Author: Eden Banim – edan107@gmail.com 
% April 2025, Physics, Ben-Gurion University of the Negev
%
% Description:
% This script implements the control panel GUI for tuning key parameters
% in an off-axis digital holography reconstruction process. It allows the
% user to set object-to-camera distance, reference angle, wavelength,
% gamma correction, and optional image filters (Gaussian, Median, Fourier).
% It also monitors the input status and triggers the reconstruction when
% all required images are available.
% =========================================================================

function holography_control()
    global d_cm_input theta_input lambda_input gamma_input ...
           use_gaussian gaussian_sigma use_median median_window ...
           use_fourier fourier_radius unwrap_method;

    % Default values
    unwrap_method = '2D'; % ברירת מחדל: unwrap פשוט ב-2 צירים
    d_cm_input = -14;
    theta_input = [];
    lambda_input = 632.8e-9;
    gamma_input = 0.35;
    use_gaussian = false;    gaussian_sigma = 1.5;
    use_median   = false;    median_window  = 3;
    use_fourier  = false;    fourier_radius = 0.2;

    f2 = figure('Name','Holography – Control Panel','Position',[950 250 380 540]);
    f2.CloseRequestFcn = @(~,~) closeControlPanel(f2);

    %% Distance
    uicontrol(f2,'Style','text','String','Distance [cm]',...
        'Position',[30 470 120 20],'HorizontalAlignment','left');
    uicontrol(f2,'Style','edit','String','-14',...
        'Position',[160 470 100 25],...
        'Callback',@(src,~) setDistance(str2double(src.String)));

    %% Theta
    uicontrol(f2,'Style','text','String','Theta [deg] (optional)',...
        'Position',[30 430 150 20],'HorizontalAlignment','left');
    uicontrol(f2,'Style','edit','String','',...
        'Position',[160 430 100 25],...
        'Callback',@(src,~) setTheta(str2double(src.String)));

%% Lambda  --- slider + edit + colour indicator ---------------------------
    uicontrol(f2,'Style','text','String','Wavelength [nm]',...
        'Position',[30 390 120 20],'HorizontalAlignment','left');

    % תיבת‑טקסט לערך נומרי
    hLambdaEdit = uicontrol(f2,'Style','edit','String','632.8',...
        'Position',[160 390 60 25]);

    % סליידר רציף (380‑750 nm)
    hLambdaSlider = uicontrol(f2,'Style','slider',...
        'Min',380,'Max',750,'Value',632.8,...
        'SliderStep',[1 10]./370,...
        'Position',[30 365 190 20]);

    % “עיגול‑צבע” למתן פידבק חזותי
    ax = axes('Parent',f2,'Units','pixels','Position',[270 365 60 60],...
              'Visible','off');
    hCircle = rectangle(ax,'Position',[0 0 1 1],'Curvature',[1 1],...
                        'EdgeColor','none',...
                        'FaceColor', wavelength2rgb(632.8));
    axis(ax,'equal'); axis(ax,'off');

    % סנכרון דו‑כיווני בין הסליידר לתיבה
    hLambdaEdit.Callback   = @(src,~) onLambdaEdit(src,hLambdaSlider,hCircle);
    hLambdaSlider.Callback = @(src,~) onLambdaSlider(src,hLambdaEdit ,hCircle);

    %% Gamma
    uicontrol(f2,'Style','text','String','Gamma Correction (γ)',...
        'Position',[30 350 200 20],'HorizontalAlignment','left');
    gamma_val_text = uicontrol(f2,'Style','text',...
        'String',sprintf('%.2f', gamma_input),...
        'Position',[270 327 40 20],'HorizontalAlignment','left');
    uicontrol(f2,'Style','slider',...
        'Min', 0.1, 'Max', 1, 'Value', gamma_input,...
        'SliderStep', [0.01 0.1],...
        'Position',[30 330 230 20],...
        'Callback',@(src,~) setGamma(src.Value, gamma_val_text));

    %% Gaussian Filter
    uicontrol(f2,'Style','checkbox','String','Gaussian Filter',...
        'Position',[30 290 150 20],...
        'Callback',@(src,~) setGaussian(logical(src.Value)));
    uicontrol(f2,'Style','text','String','σ:',...
        'Position',[200 290 20 20],'HorizontalAlignment','left');
    uicontrol(f2,'Style','edit','String','1.5',...
        'Position',[220 290 60 20],...
        'Callback',@(src,~) setSigma(str2double(src.String)));

    %% Median Filter
    uicontrol(f2,'Style','checkbox','String','Median Filter',...
        'Position',[30 250 150 20],...
        'Callback',@(src,~) setMedian(logical(src.Value)));
    uicontrol(f2,'Style','text','String','Size:',...
        'Position',[200 250 40 20],'HorizontalAlignment','left');
    uicontrol(f2,'Style','edit','String','3',...
        'Position',[240 250 40 20],...
        'Callback',@(src,~) setMedianSize(str2double(src.String)));

    %% Fourier Filter
    uicontrol(f2,'Style','checkbox','String','Fourier Filter',...
        'Position',[30 210 150 20],...
        'Callback',@(src,~) setFourier(logical(src.Value)));
    uicontrol(f2,'Style','text','String','Radius [0–1]:',...
        'Position',[180 210 80 20],'HorizontalAlignment','left');
    uicontrol(f2,'Style','edit','String','0.2',...
        'Position',[260 210 50 20],...
        'Callback',@(src,~) setFourierRadius(str2double(src.String)));

    uicontrol(f2, 'Style', 'text', 'String', 'Unwrap Method:', ...
        'Position', [30 170 120 20], 'HorizontalAlignment', 'left');

    unwrap_popup = uicontrol(f2, 'Style', 'popupmenu', ...
        'String', {'X only', 'Y only', '2D (basic)', '2D LSQ'}, ...
        'Position', [160 170 140 25], ...
        'Callback', @(src,~) setUnwrapMethod(src.Value));

   
    %% Status & Start
    btn = uicontrol(f2,'Style','pushbutton','String','Start Reconstruction',...
        'FontWeight','bold','FontSize',10,...
        'BackgroundColor',[1 0.5 0.5],...
        'Position',[60 60 220 40],...
        'Enable','off',...
        'Callback',@(~,~) runReconstruction());

    statusBox = uicontrol(f2,'Style','text','String','Status: waiting for images...',...
        'Position',[20 110 320 40],'FontWeight','bold','ForegroundColor','blue',...
        'HorizontalAlignment','left');

    %% Timer for update
    t = timer('ExecutionMode','fixedRate','Period',1,...
        'TimerFcn', @(~,~) updateStatus(statusBox, btn));
    start(t);
    setappdata(f2, 'TimerHandle', t);
end
function setDistance(val)
    global d_cm_input;
    if ~isnan(val), d_cm_input = val; end
end

function setTheta(val)
    global theta_input;
    if ~isnan(val), theta_input = deg2rad(val);
    else, theta_input = []; end
end

function setLambda(val)
    global lambda_input;
    if ~isnan(val), lambda_input = val * 1e-9; end
end

function setGamma(val, hText)
    global gamma_input;
    gamma_input = val;
    hText.String = sprintf('%.2f', val);
end

function setGaussian(val)
    global use_gaussian;
    use_gaussian = val;
end

function setSigma(val)
    global gaussian_sigma;
    if ~isnan(val) && val > 0
        gaussian_sigma = val;
    end
end

function setMedian(val)
    global use_median;
    use_median = val;
end

function setMedianSize(val)
    global median_window;
    if ~isnan(val) && val >= 1
        median_window = round(val);
    end
end

function setFourier(val)
    global use_fourier;
    use_fourier = val;
end

function setFourierRadius(val)
    global fourier_radius;
    if ~isnan(val) && val > 0 && val <= 1
        fourier_radius = val;
    end
end

function setUnwrapMethod(idx)
    global unwrap_method;
    switch idx
        case 1
            unwrap_method = 'X';
        case 2
            unwrap_method = 'Y';
        case 3
            unwrap_method = '2D';
        case 4
            unwrap_method = 'LSQ';
    end
end


function runReconstruction()
    global O2 R2 I d_cm_input theta_input lambda_input unwrap_method;
    if isempty(R2) || isempty(I)
        errordlg('Need |R|² and |O+R|² to reconstruct.');
        return;
    end
    reconstructHologram(O2, R2, I, d_cm_input, theta_input, lambda_input, unwrap_method);
end

function updateStatus(statusBox, btn)
    global O2 R2 I;
    hasO = ~isempty(O2);
    hasR = ~isempty(R2);
    hasH = ~isempty(I);
    if hasR && hasH
        btn.Enable = 'on';
        btn.BackgroundColor = [0.7 1 0.7];
        msg = '✅ Minimal input loaded: |R|² + |O+R|²';
        if hasO, msg = '✅ All images loaded: |O|² + |R|² + |O+R|²'; end
        statusBox.String = ['Status: ' msg];
        statusBox.ForegroundColor = [0 0.6 0];
    else
        btn.Enable = 'off';
        btn.BackgroundColor = [1 0.5 0.5];
        statusBox.String = 'Status: ⛔ Need at least: |R|² and |O+R|²';
        statusBox.ForegroundColor = [0.7 0 0];
    end
end

function closeControlPanel(f2)
    t = getappdata(f2, 'TimerHandle');
    if isvalid(t), stop(t); delete(t); end
    delete(f2);
end

%% === wavelength GUI helpers ============================================

function onLambdaEdit(hEdit,hSlider,hCircle)
    val = str2double(hEdit.String);
    if isnan(val), return; end
    val = max(380,min(750,val));           % מגביל לטווח הנראה
    hSlider.Value = val;                   % סנכרון
    setLambda(val);                        % מעדכן את המשתנה הגלובלי
    updateColor(hCircle,val);
end

function onLambdaSlider(hSlider,hEdit,hCircle)
    val = hSlider.Value;
    hEdit.String = sprintf('%.1f',val);    % סנכרון
    setLambda(val);                        % מעדכן את המשתנה הגלובלי
    updateColor(hCircle,val);
end

function updateColor(hCircle,lam_nm)
    hCircle.FaceColor = wavelength2rgb(lam_nm);
end

function rgb = wavelength2rgb(lam_nm)
% המרה בסיסית מאורך‑גל (nm) ל‑RGB
    lam = lam_nm;
    if lam<380 || lam>750, rgb=[.3 .3 .3]; return; end
    if lam<440
        t=(lam-380)/(440-380); rgb=[-(t)+1,0,1];
    elseif lam<490
        t=(lam-440)/(490-440); rgb=[0,t,1];
    elseif lam<510
        t=(lam-490)/(510-490); rgb=[0,1,-(t)+1];
    elseif lam<580
        t=(lam-510)/(580-510); rgb=[t,1,0];
    elseif lam<645
        t=(lam-580)/(645-580); rgb=[1,-(t)+1,0];
    else
        t=(lam-645)/(750-645); rgb=[1,0,0];
    end
    rgb = rgb.^0.8;                        % תיקון בהירות קל
end
