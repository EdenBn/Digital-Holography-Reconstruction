% =========================================================================
% File: reconstructHologram.m
% Author: Eden Banim – edan107@gmail.com 
% April 2025, Physics, Ben-Gurion University of the Negev
%
% Description:
% This function performs amplitude reconstruction from digital holograms
% based on Fresnel back-propagation. It uses the loaded input images to
% compute the reconstructed wavefront, applies optional filtering, and
% displays the resulting image. The function supports control over
% wavelength, propagation distance, gamma correction, and reference angle,
% and is designed to be called from the control panel GUI.
% =========================================================================

function reconstructHologram(O2, R2, I, d_cm, theta, lambda, unwrap_method)
    global gamma_input use_gaussian gaussian_sigma ...
           use_median median_window use_fourier fourier_radius;

    dx = 1.85e-6; dy = 1.85e-6;
    d = d_cm * 1e-2;
    gamma = gamma_input;

    [nx, ny] = size(I);
    x = (0:ny-1)*dx*1e3;
    y = (0:nx-1)*dy*1e3;

    %% Image sources
    hasO2 = ~isempty(O2);
    usedText = '|R|² + |O+R|²';
    if hasO2, usedText = '|O|² + |R|² + |O+R|²'; end

    %% DC removal
    I_dc = I - mean(I(:));
    if ~isempty(R2), I_dc = I_dc - mean(R2(:)); end
    if hasO2, I_dc = I_dc - mean(O2(:)); end

    %% Reference wave
    if isempty(R2)
        Er_amp = ones(size(I));
    else
        Er_amp = sqrt(R2);
    end

    if isempty(theta)
        Er = Er_amp;
        phaseStr = 'Flat phase (θ = 0)';
    else
        [xg, ~] = meshgrid(0:ny-1, 0:nx-1);
        Er = Er_amp .* exp(1i * 2 * pi * dx * xg * sin(theta) / lambda);
        phaseStr = sprintf('θ = %.2f°', rad2deg(theta));
    end

    %% Carrier & constants
    [kx, ky] = meshgrid(0:ny-1, 0:nx-1);
    k1 = (kx.^2)/ny^2 * dy^2;
    k2 = (ky.^2)/nx^2 * dx^2;
    const = (1i / (lambda*d)) * exp(-1i*pi*lambda*d .* (k1 + k2));
    carrier = exp((-1i*pi)/(lambda*d) .* (kx.^2 * dx^2 + ky.^2 * dy.^2));

    %% Reconstruction
    window2D = hann(nx) * hann(ny)';
    modulated = Er .* I_dc .* window2D;
    reconFn = modulated .* carrier;
    Gamma = const .* ifftshift(ifft2(fftshift(reconFn)));
    
    %% Fourier filter
    if use_fourier
        F = fftshift(fft2(Gamma));
        [m,n] = size(F);
        [xg, yg] = meshgrid(1:n, 1:m);
        cx = n/2; cy = m/2;
        radius = sqrt((xg - cx).^2 + (yg - cy).^2);
        mask = radius < fourier_radius * min(m,n);
        Gamma = ifft2(ifftshift(F .* mask));
    end

    %% Amplitude and filters
    amp = abs(Gamma);


    if use_gaussian
        amp = imgaussfilt(amp, gaussian_sigma);
    end

    if use_median
        amp = medfilt2(amp, [median_window median_window]);
    end

%% Gamma correction
amp_gamma = amp.^gamma;

%% --- Display reconstructed amplitude image ---
f_amp = figure('Name','Reconstructed Amplitude','WindowState','maximized');
amp_axes = axes('Parent', f_amp);
imagesc(amp_axes, x, y, amp_gamma, [0, prctile(amp(:),99.5).^gamma]);
colormap(amp_axes, 'gray'); axis(amp_axes, 'image');
xlabel(amp_axes, 'x [mm]', 'FontSize', 12);
ylabel(amp_axes, 'y [mm]', 'FontSize', 12);
titleStr = sprintf(['\\lambda = %.1f nm | Distance = %.2f cm\n' ...
                    'Gamma = %.2f   |   %s\nUsed: %s'], ...
                    lambda*1e9, d_cm, gamma, phaseStr, usedText);
title(amp_axes, titleStr, 'FontWeight','bold', 'FontSize', 11);
colorbar(amp_axes);

%% --- Full wrapped and unwrapped phase (entire image) ---
phase_wrapped = angle(Gamma);
%% --- Unwrapping Strategy Selection ---
switch unwrap_method
    case 'X'
        phase_unwrapped = unwrap(phase_wrapped, [], 2);

    case 'Y'
        phase_unwrapped = unwrap(phase_wrapped, [], 1);

    case '2D'
        tmp = unwrap(phase_wrapped, [], 2);
        phase_unwrapped = unwrap(tmp, [], 1);

    case 'LSQ'
        try
            phase_unwrapped = phase_unwrap(phase_wrapped);
        catch ME
            warning('LSQ unwrap failed: %s. Falling back to basic 2D unwrap.', ME.message);
            tmp = unwrap(phase_wrapped, [], 2);
            phase_unwrapped = unwrap(tmp, [], 1);
        end

    otherwise
        warning('Unknown unwrap method "%s". Using basic 2D unwrap.', unwrap_method);
        tmp = unwrap(phase_wrapped, [], 2);
        phase_unwrapped = unwrap(tmp, [], 1);
end

%% --- Ask user for ROI selection ---
disp('Please select a rectangular ROI on the amplitude image...');
figure(f_amp);
roi_rect = imrect(amp_axes);
position = wait(roi_rect);
if isempty(position) || any(position(3:4) <= 0)
    disp('ROI selection was cancelled or invalid. Aborting reconstruction...');
    if exist('f_amp', 'var') && isvalid(f_amp)
        close(f_amp);
    end
    return;
end


% Convert ROI to pixel indices
[~, xi] = min(abs(x - position(1)));
[~, xf] = min(abs(x - (position(1) + position(3))));
[~, yi] = min(abs(y - position(2)));
[~, yf] = min(abs(y - (position(2) + position(4))));

% Overlay ROI on amplitude image
rectangle(amp_axes, 'Position', position, 'EdgeColor', 'r', 'LineWidth', 2);
% --- Crop the phase and coordinates ---
phase_crop = phase_unwrapped(yi:yf, xi:xf);
x_crop = x(xi:xf);
y_crop = y(yi:yf);

% === הגדרת רדיוס ממוצע פאזות (לפני הצגת מפת הפאזה) ===
global averaging_radius;
averaging_radius = 3;
%% --- Display cropped phase map ---
% --- 3D Surface Plot of Unwrapped Phase (ROI) ---
f_phase3D = figure('Name','3D Surface – Unwrapped Phase','WindowState','maximized');
surf_axes = axes('Parent', f_phase3D);

[Xm, Ym] = meshgrid(x_crop, y_crop);
surf(surf_axes, Xm, Ym, phase_crop, 'EdgeColor', 'none');
colormap(surf_axes, 'parula');
xlabel(surf_axes, 'x [mm]', 'FontSize', 12);
ylabel(surf_axes, 'y [mm]', 'FontSize', 12);
zlabel(surf_axes, 'Phase [rad]', 'FontSize', 12);
title(surf_axes, '3D Surface Plot – Unwrapped Phase (ROI)', ...
      'FontSize', 13, 'FontWeight', 'bold');
colorbar(surf_axes);
view(surf_axes, 45, 30);  % Adjust viewing angle
grid(surf_axes, 'on');

f_phase = figure('Name','Unwrapped Phase Map (ROI)','WindowState','maximized');
phase_axes = axes('Parent', f_phase);
imagesc(phase_axes, x_crop, y_crop, phase_crop);

colormap(phase_axes, 'parula'); axis(phase_axes, 'image');
xlabel(phase_axes, 'x [mm]', 'FontSize', 12);
ylabel(phase_axes, 'y [mm]', 'FontSize', 12);
title(phase_axes, ['Unwrapped Phase Map (ROI) | ', phaseStr], ...
    'FontWeight','bold', 'FontSize', 11);
cb2 = colorbar(phase_axes);
cb2.Label.String = 'Phase [rad]';
cb2.Label.FontSize = 12;

uicontrol(f_phase,'Style','text','String','Averaging Radius [px]:',...
    'Position',[160 60 120 20],'HorizontalAlignment','left');
uicontrol(f_phase,'Style','edit','String',num2str(averaging_radius),...
    'Position',[280 60 40 25],...
    'Callback',@(src,~) setRadius(str2double(src.String)));

% --- Plot unwrapped and wrapped phase vs x for the middle row of the ROI (scatter version) ---
mid_row_idx = round(size(phase_crop, 1) / 2);
wrapped_mid_row = phase_wrapped(yi + mid_row_idx - 1, xi:xf);  % Extract from full image
unwrapped_mid_row = phase_crop(mid_row_idx, :);

figure('Name','Phase Profile – Middle Row (Scatter)','Color','w');
scatter(x_crop, wrapped_mid_row, 25, 'r', 'filled', 'DisplayName', 'Wrapped Phase'); hold on;
scatter(x_crop, unwrapped_mid_row, 25, 'b', 'filled', 'DisplayName', 'Unwrapped Phase');
xlabel('x [mm]', 'FontSize', 12);
ylabel('Phase [rad]', 'FontSize', 12);
title('Wrapped vs Unwrapped Phase – Middle Row (Scatter)', 'FontSize', 12, 'FontWeight', 'bold');
legend('Location','best');
grid on;

%% --- Depth Button ---
uicontrol(f_phase,'Style','pushbutton','String','Measure Depth',...
    'Position',[20 60 120 30],...
    'BackgroundColor',[0.9 0.9 0.9],...
    'Callback',@(~,~) measureDepth());

%% --- Integral Depth Button ---
uicontrol(f_phase,'Style','pushbutton','String','Measure Depth (Integral)',...
    'Position',[20 100 120 30],...
    'BackgroundColor',[0.9 0.9 0.9],...
    'Callback',@(~,~) measureDepthIntegral());

%% --- Roughness Button ---
uicontrol(f_phase,'Style','pushbutton','String','Measure Roughness',...
    'Position',[20 20 120 30],...
    'BackgroundColor',[0.9 0.9 0.9],...
    'Callback',@(~,~) measureRoughness());

%% --- Save Button ---
uicontrol(f_phase,'Style','pushbutton','String','Save Phase Map',...
    'Position',[160 20 120 30],...
    'BackgroundColor',[0.9 0.9 0.9],...
    'Callback',@(~,~) saveReconstructedFigure(f_phase));

%% --- Depth Measurement Function ---
function measureDepth()
    disp('Select TWO points to measure phase and depth difference...');
    disp('Click two points to measure depth. Move the mouse to see crosshairs.');

    num_points = 0;
    x_pts = zeros(1,2);
    y_pts = zeros(1,2);

    set(f_phase, 'WindowButtonMotionFcn', @crosshairMove);
    set(f_phase, 'WindowButtonDownFcn', @clickCallback);

    function crosshairMove(~,~)
        cp = get(phase_axes, 'CurrentPoint');
        x = cp(1,1); y = cp(1,2);
        if x < min(x_crop) || x > max(x_crop) || y < min(y_crop) || y > max(y_crop)
            return
        end

        delete(findall(phase_axes, 'Tag', 'crosshair'));
        delete(findall(amp_axes, 'Tag', 'crosshair'));

        line(phase_axes, [x x], ylim(phase_axes), 'Color','g', 'LineStyle','--', 'Tag','crosshair');
        line(phase_axes, xlim(phase_axes), [y y], 'Color','g', 'LineStyle','--', 'Tag','crosshair');

        line(amp_axes, [x x], ylim(amp_axes), 'Color','g', 'LineStyle','--', 'Tag','crosshair');
        line(amp_axes, xlim(amp_axes), [y y], 'Color','g', 'LineStyle','--', 'Tag','crosshair');
        drawnow;
    end

    function clickCallback(~,~)
        cp = get(phase_axes, 'CurrentPoint');
        x = cp(1,1); y = cp(1,2);
        if x < min(x_crop) || x > max(x_crop) || y < min(y_crop) || y > max(y_crop)
            return
        end
        num_points = num_points + 1;
        x_pts(num_points) = x;
        y_pts(num_points) = y;

        if num_points == 2
            set(f_phase, 'WindowButtonMotionFcn', '');
            set(f_phase, 'WindowButtonDownFcn', '');
            measureNow(x_pts, y_pts);
        end
    end

    function measureNow(x_pts, y_pts)
        [~, x1_idx] = min(abs(x_crop - x_pts(1)));
        [~, x2_idx] = min(abs(x_crop - x_pts(2)));
        [~, y1_idx] = min(abs(y_crop - y_pts(1)));
        [~, y2_idx] = min(abs(y_crop - y_pts(2)));

        phi1 = mean(getNeighborhoodPhase(phase_crop, y1_idx, x1_idx, averaging_radius), 'all');
        phi2 = mean(getNeighborhoodPhase(phase_crop, y2_idx, x2_idx, averaging_radius), 'all');
        delta_phi = phi2 - phi1;
        theta_y = deg2rad(3);           % נניח 3° אנכית
        theta_eff = sqrt(theta.^2 + theta_y.^2);
        delta_z = (lambda / (2*pi * sin(theta_eff))) * delta_phi;


        fprintf('\n--- Depth Measurement ---\n');
        fprintf('Phase 1: %.2f rad\n', phi1);
        fprintf('Phase 2: %.2f rad\n', phi2);
        fprintf('Δφ = %.2f rad | Δz = %.2f µm\n', delta_phi, delta_z*1e7);

        hold(phase_axes, 'on');
        plot(phase_axes, x_pts, y_pts, 'rx', 'MarkerSize', 10, 'LineWidth', 2);
        line(phase_axes, x_pts, y_pts, 'Color', 'r', 'LineStyle', '--', 'LineWidth', 1.5);
        text(phase_axes, x_pts(1), y_pts(1), 'P1', 'Color','w');
        text(phase_axes, x_pts(2), y_pts(2), 'P2', 'Color','w');

        hold(amp_axes, 'on');
        plot(amp_axes, x_pts, y_pts, 'ro', 'MarkerSize', 10, 'LineWidth', 2);
        line(amp_axes, x_pts, y_pts, 'Color', 'r', 'LineStyle', '--', 'LineWidth', 1.5);

        for i = 1:2
            x_val = x_pts(i);
            y_val = y_pts(i);
            plot(amp_axes, [x_val x_val], ylim(amp_axes), 'r--', 'LineWidth', 1);
            plot(amp_axes, xlim(amp_axes), [y_val y_val], 'r--', 'LineWidth', 1);
        end

        text(amp_axes, x_pts(1), y_pts(1)-0.1, ...
             sprintf('P1: (%.2f mm, %.2f mm) | (%d, %d)', ...
                     x_pts(1), y_pts(1), x1_idx, y1_idx), ...
             'Color','green','FontSize',9, 'HorizontalAlignment','center');

        text(amp_axes, x_pts(2), y_pts(2)-0.1, ...
             sprintf('P2: (%.2f mm, %.2f mm) | (%d, %d)', ...
                     x_pts(2), y_pts(2), x2_idx, y2_idx), ...
             'Color','green','FontSize',9, 'HorizontalAlignment','center');
    end

    function values = getNeighborhoodPhase(mat, yc, xc, r)
        [h, w] = size(mat);
        yi = max(1, yc - r); yf = min(h, yc + r);
        xi = max(1, xc - r); xf = min(w, xc + r);
        values = mat(yi:yf, xi:xf);
    end
end


%% --- Integral Depth Measurement Function ---
function measureDepthIntegral()
    disp('Select TWO points to measure INTEGRAL depth...');
    disp('Click two points. Move the mouse to see crosshairs.');

    num_points = 0;
    x_pts = zeros(1,2);
    y_pts = zeros(1,2);

    set(f_phase, 'WindowButtonMotionFcn', @crosshairMove);
    set(f_phase, 'WindowButtonDownFcn', @clickCallback);

    function crosshairMove(~,~)
        cp = get(phase_axes, 'CurrentPoint');
        x = cp(1,1); y = cp(1,2);
        if x < min(x_crop) || x > max(x_crop) || y < min(y_crop) || y > max(y_crop)
            return
        end

        delete(findall(phase_axes, 'Tag', 'crosshair'));
        delete(findall(amp_axes, 'Tag', 'crosshair'));

        line(phase_axes, [x x], ylim(phase_axes), 'Color','m', 'LineStyle','--', 'Tag','crosshair');
        line(phase_axes, xlim(phase_axes), [y y], 'Color','m', 'LineStyle','--', 'Tag','crosshair');

        line(amp_axes, [x x], ylim(amp_axes), 'Color','m', 'LineStyle','--', 'Tag','crosshair');
        line(amp_axes, xlim(amp_axes), [y y], 'Color','m', 'LineStyle','--', 'Tag','crosshair');
        drawnow;
    end

    function clickCallback(~,~)
        cp = get(phase_axes, 'CurrentPoint');
        x = cp(1,1); y = cp(1,2);
        if x < min(x_crop) || x > max(x_crop) || y < min(y_crop) || y > max(y_crop)
            return
        end
        num_points = num_points + 1;
        x_pts(num_points) = x;
        y_pts(num_points) = y;

        if num_points == 2
            set(f_phase, 'WindowButtonMotionFcn', '');
            set(f_phase, 'WindowButtonDownFcn', '');
            measureNowIntegral(x_pts, y_pts);
        end
    end

    function measureNowIntegral(x_pts, y_pts)
        N = 200;
        x_line = linspace(x_pts(1), x_pts(2), N);
        y_line = linspace(y_pts(1), y_pts(2), N);
        phase_vals = zeros(1,N);

        for i = 1:N
            [~, xi] = min(abs(x_crop - x_line(i)));
            [~, yi] = min(abs(y_crop - y_line(i)));
            ph = getNeighborhoodPhase(phase_crop, yi, xi, averaging_radius);
            phase_vals(i) = mean(ph(:));
        end

        dx_mm = sqrt((x_line(2)-x_line(1))^2 + (y_line(2)-y_line(1))^2);
        integral_phi = trapz(phase_vals) * dx_mm * 1e-3;  % m·rad
        avg_phi = integral_phi / (N * dx_mm * 1e-3);      % rad
        delta_z = (lambda / (2*pi * cos(theta))) * avg_phi;

        fprintf('\n--- Integral Depth Measurement ---\n');
        fprintf('⟨φ⟩ = %.2f rad | Δz = %.2f µm\n', avg_phi, delta_z*1e6);

        hold(phase_axes, 'on');
        plot(phase_axes, x_pts, y_pts, 'mx', 'MarkerSize', 10, 'LineWidth', 2);
        line(phase_axes, x_pts, y_pts, 'Color', 'm', 'LineStyle', '--', 'LineWidth', 1.5);

        hold(amp_axes, 'on');
        plot(amp_axes, x_pts, y_pts, 'mo', 'MarkerSize', 10, 'LineWidth', 2);
        line(amp_axes, x_pts, y_pts, 'Color', 'm', 'LineStyle', '--', 'LineWidth', 1.5);
    end

    function values = getNeighborhoodPhase(mat, yc, xc, r)
        [h, w] = size(mat);
        yi = max(1, yc - r); yf = min(h, yc + r);
        xi = max(1, xc - r); xf = min(w, xc + r);
        values = mat(yi:yf, xi:xf);
    end
end


%% --- Roughness Measurement Function ---
function measureRoughness()
    % הגדר פרמטרים קבועים
    lambda = 632.8e-9;      % אורך גל [m]
    theta_deg = 3;        % זווית אנכית בין הקרניים [degrees]
    theta_rad = deg2rad(theta_deg);  % המרה לרדיאנים

    disp('Select rectangular area to compute RMS roughness...');
    rect = getrect(phase_axes);
    [~, xi_r] = min(abs(x_crop - rect(1)));
    [~, xf_r] = min(abs(x_crop - (rect(1)+rect(3))));
    [~, yi_r] = min(abs(y_crop - rect(2)));
    [~, yf_r] = min(abs(y_crop - (rect(2)+rect(4))));
    roi_phase = phase_crop(yi_r:yf_r, xi_r:xf_r);

    % חשב סטיית תקן של הפאזה והמר למיקרונים
    sigma_phi = std(roi_phase(:));
    rms_roughness = sigma_phi * lambda / (2*pi * sin(theta_rad));
    
    fprintf('--- Roughness Measurement ---\n');
    fprintf('RMS Phase: %.2f rad\n', sigma_phi);
    fprintf('RMS Roughness: %.3f µm (θ = %.1f°)\n', rms_roughness * 1e7, theta_deg);

    hold(phase_axes, 'on');
    rectangle(phase_axes, 'Position', rect, ...
              'EdgeColor','m', 'LineWidth',1.5, 'LineStyle','--');
end
end

function setRadius(val)
    global averaging_radius;
    if ~isnan(val) && val >= 1
        averaging_radius = round(val);
    end
end

function saveReconstructedFigure(figHandle)
    [file,path,~] = uiputfile({'*.tif','TIFF Image (*.tif)'; '*.png','PNG Image (*.png)'}, ...
                                'Save Reconstructed Image');
    if isequal(file,0), return; end
    exportgraphics(figHandle, fullfile(path,file), ...
        'ContentType','image', 'BackgroundColor','white', 'Resolution',300);
end

