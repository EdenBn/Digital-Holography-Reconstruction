% =========================================================================
% File: holography_loader.m
% Author: Eden Banim – edan107@gmail.com 
% April 2025, Physics, Ben-Gurion University of the Negev
%
% Description:
% This script creates a graphical interface to load the required input
% images for an off-axis digital holography experiment. The loaded images
% include the squared amplitudes of the object wave (|O|²), reference wave
% (|R|²), and their interference (|O+R|²). This GUI serves as the entry
% point for the reconstruction workflow and links to the control panel.
% =========================================================================

function holography_loader()
    clc; close all;
    clearGlobalImages();  % <-- איפוס התמונות בעת פתיחה מחדש

    global O2 R2 I;

    % Loader GUI
    f1 = figure('Name','Holography – Image Loader','Position',[200 200 700 500]);

    % Load buttons
    uicontrol('Style','pushbutton','String','Load |O|²',...
        'FontSize',11,'Position',[50 430 100 35],...
        'Callback',@(~,~) loadImage('object', 1, f1));
    uicontrol('Style','pushbutton','String','Load |R|²',...
        'FontSize',11,'Position',[180 430 100 35],...
        'Callback',@(~,~) loadImage('reference', 2, f1));
    uicontrol('Style','pushbutton','String','Load |O+R|²',...
        'FontSize',11,'Position',[310 430 100 35],...
        'Callback',@(~,~) loadImage('hologram', 3, f1));

    % RESET button
    uicontrol('Style','pushbutton','String','RESET',...
        'FontWeight','bold','FontSize',11,...
        'BackgroundColor',[1 0.6 0.6],...
        'Position',[440 430 100 35],...
        'Callback',@(~,~) clearImages(f1));

    % Previews
    figure(f1);
    for i = 1:3
        subplot(2,3,i+3);
        cla; axis off;
        title('Not loaded');
    end

    % Launch control panel
    holography_control();
end

function loadImage(type, idx, figHandle)
    global O2 R2 I;
    [f,p] = uigetfile({'*.tif;*.tiff;*.png;*.jpg;*.bmp','Image files'});
    if isequal(f,0), return; end
    img = im2double(imread(fullfile(p,f)));
    switch type
        case 'object', O2 = img;
        case 'reference', R2 = img;
        case 'hologram', I = img;
    end
    figure(figHandle);
    subplot(2,3,idx+3); imshow(img,[]); title([type ' loaded'],'FontWeight','bold');
end

function clearImages(figHandle)
    global O2 R2 I;
    O2 = []; R2 = []; I = [];
    figure(figHandle);
    for i = 1:3
        subplot(2,3,i+3); cla; axis off;
        title('Not loaded');
    end
    disp('[RESET] Images cleared.');
end

function clearGlobalImages()
    global O2 R2 I;
    O2 = []; R2 = []; I = [];
    disp('[AUTO RESET] Cleared images on loader open.');
end
