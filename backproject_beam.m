function current_image = backproject_beam(current_image, theta_deg, t, p_val)
    %% 0. If projection value is negligible, do nothing
    if abs(p_val) < 1e-10
        return;
    end
    [N, M] = size(current_image);
    theta_rad = deg2rad(theta_deg);
    %% 1. 
    % x * cos(theta) + y * sin(theta) = t
    A = cos(theta_rad);B = sin(theta_rad);
    %% 2. Edges
    x_edges = linspace(-M/2, M/2, M+1); 
    y_edges = linspace(-N/2, N/2, N+1); 
    all_points = [];
    %% 3. Intersections 
    % Case A: Intersections with vertical grid lines (x = const)
    % y = (t - A*x) / B
    if abs(B) > 1e-6
        y_vals = (t - A * x_edges) / B;
        all_points = [x_edges', y_vals'];
    end
    % Case B: Intersections with horizontal grid lines (y = const)
    % x = (t - B*y) / A
    if abs(A) > 1e-6
        x_vals = (t - B * y_edges) / A;
        all_points = [all_points; [x_vals', y_edges']];
    end
    %% 4. Filter Points
    if ~isempty(all_points)
        valid_mask = all_points(:,1) >= -M/2 & all_points(:,1) <= M/2 & ...
                     all_points(:,2) >= -N/2 & all_points(:,2) <= N/2;
        all_points = all_points(valid_mask, :);
    end
    %% 5. Process Segments
    % 2 points to form a segment
    if size(all_points, 1) >= 2
        % Sort points
        sorted_points = unique(round(all_points, 8), 'rows');
        % Iterate 
        for k = 1:size(sorted_points, 1) - 1
            p1 = sorted_points(k, :);
            p2 = sorted_points(k+1, :);
            
            % A. Calculate Segment Length (Weight)
            dist = norm(p2 - p1); %euclidian distance
            
            % B. Calculate Midpoint 
            mid_x = (p1(1) + p2(1)) / 2;
            mid_y = (p1(2) + p2(2)) / 2;
            
            % C. Map Spatial Coordinates to Matrix Indices
            col = floor((M/2) + mid_x) + 1;
            row = floor((N/2) - mid_y) + 1;
            
            % D. Update Pixel
            if row >= 1 && row <= N && col >= 1 && col <= M
                % Projection Value * Length in Pixel
                current_image(row, col) = current_image(row, col) + (p_val * dist);
            end
        end
    end
end