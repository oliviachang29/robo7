function [fitline_coefs, bestInlierSet, bestOutlierSet, bestEndPoints] = robustLineFit(r, theta, d, n, visualize)
    % n is number of candidate lines to try
    % d is threshold distance for inliers vs. outliers
    
    if ~exist('visualize', 'var')
        % visualize param doesn't exist, default to 1
        visualize = 1
    end
    
    % eliminate zeros
    index = find(r~=0 & r<3);
    r_clean = r(index);
    theta_clean = theta(index);
    
    % conver to cartesian and plot
    [x, y] = pol2cart(deg2rad(theta_clean),r_clean);
    points = [x, y];
    
    % implement RANSAC
    bestCandidates = [];
    bestInlierSet = zeros(0,2);
    bestOutlierSet = zeros(0,2);
    bestEndPoints = zeros(0,2);
    
    for k=1:n
        % select two endpoints at random
        candidates = datasample(points, 2, 'Replace', false)
        
        % vector pointing from point 2 to point 1
        v = (candidates(1,:) - candidates(2,:))';
        
        % if length of vector is 0 then it chose the same two points
        % so skip this cycle
        if norm(v) == 0
            continue;
        end
        
        % get vector orthogonal to point2-point1 by rotating 90 degrees
        orthov = [-v(2); v(1)];
        orthov_unit = orthv/norm(orthov); % make unit vector
        
        % get distance of each scan point to one of the endpoints
        % of candidate line
        % creates vector for each point
        diffs = points - candidates(2,:);
        
        % project difference vectors onto perpendicular direction
        % using orthv_unit, giving orthogonal distance from candidate fit
        % line
        orthdists = diffs*orthv_unit;
        
        % for inliers, check if absolute distance is less than d
        inliers = abs(orthdists) < d;
        
        % check that there are no big gaps in our walls
        % first take diffs (distance of each inlier away from endpoint)
        % project onto best fit direction
        % sort from smallest to largest and take the difference to get
        % spacing (gap) between adjacent points
        % then get the maximum gap
        biggestGap = max(diff(sort(diffs(inliers,:)*v/norm(v))))
        
        % check if the number of inliers is greater than the previous best
        % candidates and if the gap isn't too big
        gapThreshold = 0.2;
        if biggestGap < gapThreshold && sum(inliers) > size(bestInlierSet,1)
            bestInlierSet = points(inliers,:); % set inliers
            bestOutlierSet = points(~inliers,:); % set outliers by doing opposite of inliers;
            bestCandidates = candidates;
            
            % find endpoints for plotting the best fit line
            projectedCoordinate = (diffs(inliers,:)*v) / norm(v);
            bestEndPoints = [min(projectedCoordinate); max(projectedCoordinate)] * v'/norm(v) + repmat(candidates(2,:),[2,1]); 
        end 
    end
    
    % if we haven't found end points, set all to NaN and stop function
    if isempty(bestEndPoints)
        m = NaN
        b = Nan;
        bestEndPoints = [NaN; NaN; NaN; NaN];
        fitline_coefs = [m b];
        return;
    end
    
    % find coefficients for best line
    % get slope
    m = diff(bestEndPoints(:,2)) / diff(bestEndPoints(:,1));
    % 
    b = bestEndPoints(1,2) - m*bestEndPoints(1,1);
    fitline_coefs = [m b];
    
    if visualize == 1
        % plot polar data as verification
        figure(1)
        polarplot(deg2rad(theta_clean),r_clean,'ks','MarkerSize',6,'MarkerFaceColor','m')
        title('Visualization of Polar Data')
        
        figure(2)
        plot(x,y,'ks')
        title('Scan Data - Clean')
        xlabel('[m]')
        ylabel('[m]')
        
        % plot our results
        figure(3)
        plot(bestInlierSet(:,1), bestInlierSet(:,2), 'ks')
        plot(bestInlierSet(:,1), bestInlierSet(:,2), 'bs')
        plot(bestEndPoints(:,1), bestEndPoints(:,2), 'r')
        
        legend('Inliers','Outliers','Best Fit','location','northwest')
        title(['RANSAC with d=' num2str(d) ' and n=' num2str(n)])
        xlabel('[m]')
        ylabel('[m]')
        % Create textbox
        annotation(figure(3),'textbox',...
            [0.167071428571429 0.152380952380952 0.25 0.1],...
            'String',{'Number of Inliers:' num2str(size(bestInlierSet,1))},...
            'FitBoxToText','off');
    end
end