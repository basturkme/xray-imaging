function [projections, theta_values, t_values] = forwardProjection(imageMatrix, angleStep, numBeams)
    %% 1. Setup 
    img = double(imageMatrix); % e.g sqr_matrix
    [N, M] = size(img);
   
    %basic_angles = 0:angleStep:180;%angleStep based on input
    %mandatory_angles = [30, 60, 90, 135];
    theta_values= 0:angleStep:179;
    
   % theta_values = unique([basic_angles, mandatory_angles]);%combine and remove duplicates
    numAngles = length(theta_values);
    
    % Define t (beam) range
    img_diagonal = sqrt(N^2 + M^2);
    t_max = ceil(img_diagonal / 2);     % (diagonal of image)
    
    t_values = linspace(-t_max, t_max, numBeams);%origin centered t
    
    fprintf('--- Forward Projection ---\n');
    fprintf('Image Size: %dx%d\n', N, M);
    fprintf('Angles: %d (Step: %.1f)\n', numAngles, angleStep);
    fprintf('Beams (t): %d\n', numBeams);
    %% 2. Calculate Projections
    projections = zeros(numBeams, numAngles);
    
    % Loop for all angle values
    for i = 1:numAngles
        theta_deg = theta_values(i);
        % Loop for all t vlaues
        for j = 1:numBeams
            t = t_values(j);
            projections(j, i) = calculate_line_integral(img, theta_deg, t);
        end
    end
    %% 3. Save to .mat File
    filename = 'projections_2574762.mat';
    save(filename, 'projections', 'theta_values', 't_values', 'imageMatrix');
    %% 4. Plotting Specific Angles 
    target_angles = [30, 60, 90, 135];
    
    figure('Name', 'Projection Profiles', 'Color', 'w');
    
    for k = 1:length(target_angles)
        target = target_angles(k);
        
        % Find the index in theta_values closest to the target angle
        [min_diff, idx] = min(abs(theta_values - target));
        
        % tolerance check
        if min_diff > angleStep/2
            warning('Target angle %d not found exactly in theta range. Using %.1f instead.', target, theta_values(idx));
            %this wont happen theoretically since i ad unique() function
            %before
        end
        
        % Extract the projection
        p_t = projections(:, idx);
        
        subplot(2, 2, k);
        plot(t_values, p_t, 'r-o', 'LineWidth', 1.5, 'MarkerSize', 4, 'MarkerFaceColor', 'r');
        grid on;
        title(sprintf('\\theta = %d^\\circ', target));
        xlabel('t');
        ylabel('p(t)');
        axis tight;
    end
    
    sgtitle('Projection for Specific Angles');
end