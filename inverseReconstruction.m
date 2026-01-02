function [UBP, FBP] = inverseReconstruction(projections, imageSize)
    %% 1. Setup 
    [num_sensors, num_angles] = size(projections);%sinogram sizes
    N = imageSize(1);
    M = imageSize(2); % image sizes
    theta = linspace(0, 179, num_angles);
    
    img_diagonal = sqrt(N^2 + M^2);
    t_max = ceil(img_diagonal / 2); %max projection dist, diagonal
    t_sensor = linspace(-t_max, t_max, num_sensors);
    %% 2. Design Filter (Ram-Lak)
    % Filter Setup
    %increased fft efficiency, faster circular conv
    N_filt = 2^nextpow2(num_sensors);
    f = linspace(-0.5, 0.5, N_filt);
    
    % Ram-Lak (Ramp) Filter: |f|
    H_filter = abs(f); 
    H_filter = ifftshift(H_filter); % shift dc
    %% 3. Filter
    filtered_sinogram = zeros(num_sensors, num_angles);
    
    for i = 1:num_angles
        % FFT
        proj_fft = fft(projections(:, i), N_filt);
        
        % Filter it
        filtered_fft = proj_fft .* H_filter';
        
        % IFFT
        filtered_profile = real(ifft(filtered_fft));
        
        % Crop the zero padding
        filtered_sinogram(:, i) = filtered_profile(1:num_sensors);
    end
    
    %% 4. Backprojection Loop
    UBP = zeros(N, M);
    FBP = zeros(N, M);
    fprintf('Starting Reconstruction for %dx%d Image...\n', N, M);
    for k = 1:num_angles
        current_angle = theta(k);
        
        for j = 1:num_sensors
            current_t = t_sensor(j);
            
            % --- Unfiltered ---
            val_unfiltered = projections(j, k);
            if abs(val_unfiltered) > 1e-5
                UBP = backproject_beam(UBP, current_angle, current_t, val_unfiltered);
            end
            
            % --- Filtered ---
            val_filtered = filtered_sinogram(j, k);
            if abs(val_filtered) > 1e-5
                FBP = backproject_beam(FBP, current_angle, current_t, val_filtered);
            end
        end
    end 
end