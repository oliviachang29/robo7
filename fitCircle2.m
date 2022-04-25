function [center, r] = fitCircle2(seedPoints, known_radius)
    chord = seedPoints(1,:) - seedPoints(2,:);
    chord_length = norm(chord);

    if (known_radius^2 - (chord_length/2) ^ 2) > 0
        midpoint_chord_to_center = sqrt(known_radius^2 - (chord_length/2)^2);
        midpoint_chord = (chord / 2) + seedPoints(2,:);
        orthov = [-chord(2); chord(1)];

        orthov_unit = orthov/norm(orthov); % make unit vector
        orthov_radius = orthov_unit * midpoint_chord_to_center;

        % you will end up with two centers...
        center = [];
        center(1) = midpoint_chord(1)+orthov_radius(1);
        center(2) = midpoint_chord(2)+orthov_radius(2);
        r = known_radius;
    else
        center = NaN;
        r = NaN;
    end
end