clear all;
close all;

% Charger le fichier Excel
file_path = '';

% Noms des onglets (RMSSD et SDNN)
sheets = ["RMSSD", "SDNN","FC"];

% Comparaisons pour les analyses
comparisons = {...
    ["H10supine", "OH1supine"], ...
    ["H10seated", "OH1seated"], ...
    ["H10supine", "H10seated"], ...
    ["OH1supine", "OH1seated"]
};

% Initialiser un tableau pour stocker les résultats
global summary_table_correlations;
summary_table_correlations = table('Size', [0 8], ...
    'VariableTypes', {'string', 'string', 'string', 'double', 'double', 'double', 'double', 'double'}, ...
    'VariableNames', {'Sheet', 'Variable1', 'Variable2', 'r', 'p', 'MeanDiff', 'LoA_Lower', 'LoA_Upper'});

% Parcourir chaque onglet
for i = 1:length(sheets)
    sheet = sheets{i};
    fprintf('Analysis for sheet: %s\n', sheet);

    % Charger les données de l'onglet
    data = readtable(file_path, 'Sheet', sheet);

    % Créer une figure pour les corrélations et Bland-Altman
    figure('Name', ['Analysis: ', sheet], 'NumberTitle', 'off');
    set(gcf, 'Position', [100, 100, 1200, 800]);  % Taille de la figure plus grande

    % Créer une grille de 2 lignes et 4 colonnes pour les sous-figures
    for j = 1:length(comparisons)
        var1 = comparisons{j}{1};
        var2 = comparisons{j}{2};

        if ismember(var1, data.Properties.VariableNames) && ismember(var2, data.Properties.VariableNames)
            % Calculer la corrélation de Pearson
            [r, p] = corr(data.(var1), data.(var2), 'Type', 'Pearson');
            
            % Calcul des IC 95% pour r
            N = length(data.(var1));  % Nombre de paires de données
            zr = 0.5 * log((1 + r) / (1 - r));  % Transformation de Fisher Z
            SEz = 1 / sqrt(N - 3);  % Erreur standard de z
            zlower = zr - 1.96 * SEz;  % Limite inférieure de l'IC
            zupper = zr + 1.96 * SEz;  % Limite supérieure de l'IC
            rlower = (exp(2 * zlower) - 1) / (exp(2 * zlower) + 1);  % Transformation inverse pour r
            rupper = (exp(2 * zupper) - 1) / (exp(2 * zupper) + 1);  % Limite supérieure pour r

            % Ajouter le résultat au tableau résumé
            new_row = {sheet, var1, var2, r, p, NaN, NaN, NaN}; % Placeholder pour Bland-Altman
            summary_table_correlations = [summary_table_correlations; new_row]; %#ok<AGROW>
            
            % Afficher la corrélation (subplot 1-4)
            subplot(2, 4, j); % Utilisation d'une grille 2x4 pour mieux espacer les sous-figures
            scatter(data.(var1), data.(var2), 'b', 'filled');
            hold on;
            lsline;
            
            % Ajouter un titre avec espacement accru
            titleText = [var1, ' vs. ', var2];
            titleHandle = title(titleText, 'FontSize', 14, 'FontWeight', 'bold');

            % Ajuster l'espacement du titre pour éviter qu'il sorte de la figure
            ax = gca; % Récupérer l'axe actuel
            titlePos = ax.Title.Position; % Position actuelle du titre
            ax.Title.Position(2) = titlePos(2) + 0.05 * abs(diff(ylim)); % Espacement ajusté (plus modéré)

            
            xlabel([var1, ' (ms)'], 'FontSize', 13);
            ylabel([var2, ' (ms)'], 'FontSize', 13);
            grid on;
            
%             % Placer le texte dans le coin supérieur gauche
%             xLimits = xlim;
%             yLimits = ylim;
%             text(xLimits(1) + 0.05 * diff(xLimits), yLimits(2) - 0.1 * diff(yLimits), ...
%                 sprintf('r = %.2f\np = %.3f\n95%% CI: [%.2f, %.2f]', r, p, rlower, rupper), ...
%                 'VerticalAlignment', 'top', 'HorizontalAlignment', 'left', ...
%                 'BackgroundColor', 'w', 'EdgeColor', 'k', 'FontSize', 10);
%         else
%             fprintf('Variables %s and/or %s not found in %s\n', var1, var2, sheet);
        end
    end
    
    % Créer une grille de 2 lignes et 4 colonnes pour les Bland-Altman
    for j = 1:length(comparisons)
        var1 = comparisons{j}{1};
        var2 = comparisons{j}{2};

        if ismember(var1, data.Properties.VariableNames) && ismember(var2, data.Properties.VariableNames)
            % Afficher le Bland-Altman (subplot 5-8)
            subplot(2, 4, j+4); % Placer les Bland-Altman plots dans les sous-figures 5 à 8
            [mean_diff, loa_lower, loa_upper] = bland_altman_plot(data.(var1), data.(var2), [var1, ' vs ', var2]);

            % Mettre à jour le tableau avec les résultats du Bland-Altman
            new_row = {sheet, var1, var2, NaN, NaN, mean_diff, loa_lower, loa_upper};
            summary_table_correlations = [summary_table_correlations; new_row]; %#ok<AGROW>
        else
            fprintf('Variables %s and/or %s not found in %s\n', var1, var2, sheet);
        end
    end
end

% Afficher le tableau résumé
disp(summary_table_correlations);

% Fonction pour le test de Bland-Altman
function [mean_diff, loa_lower, loa_upper] = bland_altman_plot(data1, data2, variable_name)
    % Calcul des différences et moyennes
    diff = data1 - data2;
    mean_vals = mean([data1, data2], 2);
    mean_diff = mean(diff);
    std_diff = std(diff);
    loa_upper = mean_diff + 1.96 * std_diff;
    loa_lower = mean_diff - 1.96 * std_diff;

    % Tracer le Bland-Altman
    scatter(mean_vals, diff, 'b', 'filled', 'HandleVisibility', 'off');
    hold on;
    yline(mean_diff, 'r', 'LineWidth', 1.5, 'DisplayName', 'Mean');
    yline(loa_upper, '--r', 'LineWidth', 1, 'DisplayName', 'Mean +1.96 SD');
    yline(loa_lower, '--r', 'LineWidth', 1, 'DisplayName', 'Mean -1.96 SD');
    xlabel('Mean of the two measures (ms)', 'FontSize', 13);
    ylabel('Difference between the two measures (ms)', 'FontSize', 13);
    legend('off');
    grid("on")
    hold off;
end
