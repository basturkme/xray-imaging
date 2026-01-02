% EE415 Term Project - Test Script
clear; clc; close all;

%% 1.Image List

fileList = {
    
    'img_RandomCircles.mat', ...
    'img_SheppLogan.mat', ...
    'img_Strips.mat'
};

resultsSummary = struct('Name', {}, 'MSE_UBP', {}, 'PSNR_UBP', {}, 'MSE_FBP', {}, 'PSNR_FBP', {});

%% 2. Main Processing Loop
for k = 1:length(fileList)
    filePath = fileList{k};
    [~, name, ~] = fileparts(filePath); % Extract filename for title
    
    fprintf('Processing Image %d/%d: %s\n', k, length(fileList), name);   
    %% 2.1 Load Data
    data = load(filePath);
    fn = fieldnames(data);
    original_image = double(data.(fn{1})); 
    
    [N, M] = size(original_image);
    fprintf('Image Size: %dx%d\n', N, M);
    %% 2.2 Forward Projection (Generate Sinogram)
    angle_step = 1;
    img_diagonal = ceil(sqrt(N^2 + M^2));
    num_beams = img_diagonal + 10; 
    
    [P, ~, ~] = forwardProjection_2574762(original_image, angle_step, num_beams); %% uses my forward
    %% 2.3 Inverse Reconstruction 
    tic;
    [UBP_raw, FBP_raw] = inverseReconstruction_2574762(P, [200, 200]); %% uses my backproj

    %% 2.4 Normalization
    max_val = max(original_image(:));
    if max_val == 0, max_val = 1; end

    % Normalize FBP
    fbp_max = max(FBP_raw(:));
    if fbp_max == 0, fbp_max = 1; end
    FBP = FBP_raw * (max_val / fbp_max);
     
     % Normalize UBP
     ubp_max = max(UBP_raw(:));
     if ubp_max == 0, ubp_max = 1; end
     UBP = UBP_raw * (max_val / ubp_max);

    % %% 2.5 Quantitative Metrics
    % % MSE
    % mse_ubp = immse(UBP, original_image);
    % mse_fbp = immse(FBP, original_image);
    % 
    % % PSNR
    % psnr_ubp = psnr(UBP, original_image);
    % psnr_fbp = psnr(FBP, original_image);
    % 
    % % Store in summary structure
    % resultsSummary(end+1).Name = name;
    % resultsSummary(end).MSE_UBP = mse_ubp;
    % resultsSummary(end).PSNR_UBP = psnr_ubp;
    % resultsSummary(end).MSE_FBP = mse_fbp;
    % resultsSummary(end).PSNR_FBP = psnr_fbp;

    %% 2.6 Visualization
    f = figure('Name', ['Results: ' name], 'Color', 'w', 'Position', [50, 50, 1200, 400]);
    
    % Plot Original
    subplot(1, 3, 1);
    imagesc(original_image); colormap(gray); axis image; colorbar;
    title(['Ground Truth: ' name], 'Interpreter', 'none');
    xlabel('x'); ylabel('y');
    
    % Plot Unfiltered BP
    subplot(1, 3, 2);
    imagesc(UBP); colormap(gray); axis image; colorbar;
    title({['Unfiltered BP'], ['PSNR: ' num2str(psnr_ubp, '%.2f') ' dB']}, 'Interpreter', 'none');
    xlabel('x'); ylabel('y');
    
    % Plot  Filtered BP
    subplot(1, 3, 3);
    imagesc(FBP); colormap(gray); axis image; colorbar;
    title({['Filtered BP (Ram-Lak)'], ['PSNR: ' num2str(psnr_fbp, '%.2f') ' dB']}, 'Interpreter', 'none');
    xlabel('x'); ylabel('y');
    
    drawnow; 
end

%% 3. Final Summary Table
fprintf('\n\n');
fprintf('==================================================================================\n');
fprintf('| %-20s | %-12s | %-12s | %-12s | %-12s |\n', 'Image Name', 'UBP MSE', 'UBP PSNR', 'FBP MSE', 'FBP PSNR');
fprintf('==================================================================================\n');
for i = 1:length(resultsSummary)
    fprintf('| %-20s | %-12.4f | %-12.2f | %-12.4f | %-12.2f |\n', ...
        resultsSummary(i).Name, ...
        resultsSummary(i).MSE_UBP, resultsSummary(i).PSNR_UBP, ...
        resultsSummary(i).MSE_FBP, resultsSummary(i).PSNR_FBP);
end
fprintf('==================================================================================\n');