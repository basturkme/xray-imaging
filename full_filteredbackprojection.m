% EE415 Term Project - Full Inverse Problem (Filtered Backprojection)
% Step 2: Reconstruction and Comparison

%% 1. Setup
clear; clc; close all;

data = load('square.mat');
fn = fieldnames(data);
original_image = double(data.(fn{1}));

[N, M] = size(original_image);

%% 2. Generate Projection Data (The Forward Problem)

% inputs are projection data from Step 1.

angle_step = 1; 

% Determine number of beams (sensors)
% Rule of thumb: Roughly equal to the image diagonal length for good resolution
img_diagonal = ceil(sqrt(N^2 + M^2));
num_beams = img_diagonal + 10; % Adding a small buffer

% --- CALL CUSTOM FUNCTION ---
% P: Sinogram (Projections)
% theta: Angles used
% t_sensor: Sensor positions on the detector array
[P, theta, t_sensor] = forwardProjection_2574762(original_image, angle_step, num_beams);

[num_sensors, num_angles] = size(P);

% Display Check
disp(['Forward Projection Complete using Custom Function.']);
disp(['Sinogram Size: ', num2str(num_sensors), ' x ', num2str(num_angles)]);

%% 3. Design Filter (Ram-Lak / Ramp)

N_filt = 2^nextpow2(num_sensors); 
f = linspace(-0.5, 0.5, N_filt);

% Ram-Lak Filtresi: Sadece mutlak deger |f|
% Ekstra bir pencere (Hamming/Bartlett) ile carpilmaz.
H_filter = abs(f); 

% Sifir frekansini (DC bileseni) FFT'ye uygun hale getirmek icin kaydiriyoruz
H_filter = ifftshift(H_filter);

%% 4. Apply Filter in Frequency Domain
filtered_sinogram = zeros(num_sensors, num_angles);

for i = 1:num_angles
    % FFT of the projection at current angle
    proj_fft = fft(P(:, i), N_filt);
    
    % Apply filter
    filtered_fft = proj_fft .* H_filter';
    
    % IFFT to get back to spatial domain
    filtered_profile = real(ifft(filtered_fft));
    
    % Crop zero-padding to match original sensor count
    filtered_sinogram(:, i) = filtered_profile(1:num_sensors);
end

%% 5. Full Backprojection (All Angles)
%  blank images
bp_unfiltered = zeros(N, M);
bp_filtered = zeros(N, M);

disp('Starting Full Backprojection...');
disp('Note: Ray-driven intersection is accurate but slow. Please wait.');

% Create a waitbar to track progress (essential for slow loops)
h_wait = waitbar(0, 'Reconstructing Image...');

for k = 1:num_angles
    current_angle = theta(k);
    
    % Update waitbar every 5 degrees to reduce overhead
    if mod(k, 5) == 0
        waitbar(k/num_angles, h_wait, sprintf('Processing Angle %d / %d', k, num_angles));
    end
    
    for j = 1:num_sensors
        current_t = t_sensor(j);
        
        % --- Unfiltered Reconstruction ---
        val_unfiltered = P(j, k);
        % OPTIMIZATION: Only backproject if value is non-zero
        if abs(val_unfiltered) > 1e-5
            bp_unfiltered = backproject_beam(bp_unfiltered, current_angle, current_t, val_unfiltered);
        end
        
        % --- Filtered Reconstruction ---
        val_filtered = filtered_sinogram(j, k);
        if abs(val_filtered) > 1e-5
            bp_filtered = backproject_beam(bp_filtered, current_angle, current_t, val_filtered);
        end
    end
end
close(h_wait);

%% 6. Normalization
% Backprojection is a summation. We must normalize to match the original range.
% Simple Min-Max normalization is effective for visual comparison.
bp_filtered = bp_filtered / max(bp_filtered(:)) * max(original_image(:));
bp_unfiltered = bp_unfiltered / max(bp_unfiltered(:)) * max(original_image(:));

%% 7. Quantitative Comparison
% The rubric requires quantitative metrics like MSE and PSNR.

% 1. Mean Squared Error (MSE)
mse_unfiltered = immse(bp_unfiltered, original_image);
mse_filtered = immse(bp_filtered, original_image);

% 2. Peak Signal-to-Noise Ratio (PSNR)
psnr_unfiltered = psnr(bp_unfiltered, original_image);
psnr_filtered = psnr(bp_filtered, original_image);

fprintf('------------------------------------------------\n');
fprintf('Reconstruction Results:\n');
fprintf('Unfiltered MSE: %.4f | PSNR: %.4f dB\n', mse_unfiltered, psnr_unfiltered);
fprintf('Filtered   MSE: %.4f | PSNR: %.4f dB\n', mse_filtered, psnr_filtered);
fprintf('------------------------------------------------\n');

%% 8. Visualization
figure('Name', 'Step 2: Full Reconstruction Comparison', 'Color', 'w', 'Position', [50, 100, 1600, 500]);

% Original
subplot(1, 3, 1);
imagesc(original_image); colormap(gray); colorbar; axis image;
title('Original Image', 'FontSize', 12);

% Unfiltered
subplot(1, 3, 2);
imagesc(bp_unfiltered); colormap(gray); colorbar; axis image;
title({['Unfiltered BP'], ['PSNR: ' num2str(psnr_unfiltered, '%.2f') ' dB']}, 'FontSize', 12);

% Filtered
subplot(1, 3, 3);
imagesc(bp_filtered); colormap(gray); colorbar; axis image;
title({['Filtered BP (Triangular)'], ['PSNR: ' num2str(psnr_filtered, '%.2f') ' dB']}, 'FontSize', 12);

sgtitle('Comparison of Reconstructions', 'FontSize', 14, 'FontWeight', 'bold');