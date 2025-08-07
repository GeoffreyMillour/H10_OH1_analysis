clear all;
close all;

% Charger le fichier Excel
file_path = '';

% Noms des onglets (RMSSD, SDNN, FC)
sheets = ["RMSSD", "SDNN", "FC"];

% Comparaisons pour les analyses
comparisons = {...
    ["H10supine", "OH1supine"], ...
    ["H10seated", "OH1seated"], ...
    ["H10supine", "H10seated"], ...
    ["OH1supine", "OH1seated"]
};

% Initialiser le tableau résumé
summary_table_blandaltman = table('Size', [0 9], ...
    'VariableTypes', {'string', 'string', 'string', 'double', 'double', 'double', 'double', 'double', 'double'}, ...
    'VariableNames', {'Sheet', 'Variable1', 'Variable2', 'p', 'MeanDiff', 'LoA_Lower', 'LoA_Upper', 'MAE', 'RMSE'});

% Parcourir les feuilles
for i = 1:length(sheets)
    sheet = sheets{i};
    fprintf('Analyse pour l''onglet : %s\n', sheet);

    % Charger les données de l'onglet
    data = readtable(file_path, 'Sheet', sheet);

    % Créer une figure pour Bland-Altman
    figure('Name', ['Bland-Altman: ', sheet], 'NumberTitle', 'off');
    set(gcf, 'Position', [100, 100, 1000, 800]);

    % Grille 2x2
    for j = 1:length(comparisons)
        var1 = comparisons{j}{1};
        var2 = comparisons{j}{2};

        if ismember(var1, data.Properties.VariableNames) && ismember(var2, data.Properties.VariableNames)
            % Extraire les données
            d1 = data.(var1);
            d2 = data.(var2);

            % T-test apparié
            [~, pval] = ttest(d1, d2); % test bilatéral apparié

            % Bland-Altman
            subplot(2, 2, j);
            [mean_diff, loa_lower, loa_upper, mae, rmse] = bland_altman_plot(d1, d2, [var1, ' vs ', var2]);

            % Mise à jour du tableau
            new_row = {sheet, var1, var2, pval, mean_diff, loa_lower, loa_upper, mae, rmse};
            summary_table_blandaltman = [summary_table_blandaltman; new_row]; %#ok<AGROW>
        else
            fprintf('Variables %s et/ou %s non trouvées dans %s\n', var1, var2, sheet);
        end
    end
end

% Affichage du tableau final
disp(summary_table_blandaltman);

% Fonction Bland-Altman avec MAE et RMSE
function [mean_diff, loa_lower, loa_upper, mae, rmse] = bland_altman_plot(data1, data2, variable_name)
    diff = data1 - data2;
    mean_vals = mean([data1, data2], 2);

    mean_diff = mean(diff);
    std_diff = std(diff);
    loa_upper = mean_diff + 1.96 * std_diff;
    loa_lower = mean_diff - 1.96 * std_diff;

    mae = mean(abs(diff));
    rmse = sqrt(mean((diff).^2));

    scatter(mean_vals, diff, 'b', 'filled');
    hold on;
    yline(mean_diff, 'r', 'LineWidth', 1.5, 'DisplayName', 'Mean');
    yline(loa_upper, '--r', 'LineWidth', 1, 'DisplayName', '+1.96 SD');
    yline(loa_lower, '--r', 'LineWidth', 1, 'DisplayName', '-1.96 SD');
    xlabel('Mean of the two measures (ms)', 'FontSize', 14);
    ylabel('Difference between the two measures (ms)', 'FontSize', 14);
    title(variable_name, 'FontSize', 15, 'FontWeight', 'bold');
    grid on;
    hold off;
end
