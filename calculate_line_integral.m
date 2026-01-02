function p_theta_t = calculate_line_integral(image_matrix, theta_deg, t)
    [N, M] = size(image_matrix);
    theta_rad = deg2rad(theta_deg);
    
    x_edges = linspace(-M/2, M/2, M+1); % -25, -24, ..., 24, 25
    y_edges = linspace(-N/2, N/2, N+1); % -25, -24, ..., 24, 25
    
    %  Ax + By = C eqn
    A = cos(theta_rad);
    B = sin(theta_rad);
    C = t;
    all_points = [];
    % 1. 
    if abs(B) > 1e-6
        y_vals = (C - A * x_edges) / B;
        all_points = [x_edges', y_vals'];
    end
    
    % 2. 
    if abs(A) > 1e-6
        x_vals = (C - B * y_edges) / A;
        all_points = [all_points; [x_vals', y_edges']];
    end
    
    % 3. filter the parts that are not in data 
    all_points = all_points(all_points(:,1) >= -M/2 & all_points(:,1) <= M/2 & ...
                            all_points(:,2) >= -N/2 & all_points(:,2) <= N/2, :);
                            
    sorted_points = unique(round(all_points, 8), 'rows');
    % if there is less than 2 dots, integral 0
    if size(sorted_points, 1) < 2
        p_theta_t = 0;
        return;
    end
    total_integral = 0;
    % 5. for every line segment (p1 -> p2) 
    for k = 1:size(sorted_points, 1) - 1
        p1 = sorted_points(k, :);   % Segment start (x,y)
        p2 = sorted_points(k+1, :); % Segment end (x,y)
        
        % 8: Segment length
        dist = norm(p2 - p1);
        
        % 8: Segment middle point
        mid_x = (p1(1) + p2(1)) / 2;
        mid_y = (p1(2) + p2(2)) / 2;
        
        %  9: middle point matrix index (row, col) 
        % rowdata = (M/2) - floor(middleYpoints)
        % columndata = (M/2) + ceil(middleXpoints)
        col = round((M/2) + mid_x + 0.5); 
        row = round((N/2) - mid_y + 0.5); 
    
        if row >= 1 && row <= N && col >= 1 && col <= M
            % 10: take pixel values add to integral
            pixel_value = image_matrix(row, col);
            total_integral = total_integral + (pixel_value * dist);
        end
    end
    
    p_theta_t = total_integral;
end