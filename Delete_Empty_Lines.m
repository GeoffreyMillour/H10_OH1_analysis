% Spécifiez le chemin du dossier contenant vos fichiers
dossier = 'C:\Users\geoff\OneDrive\Bescored\Capsix\Data_VFC\TH-LE-15';

% Obtenez la liste des fichiers dans le dossier
Files = dir(fullfile(dossier, '*.txt'));

% Parcourez tous les fichiers dans le dossier
for i = 1:numel(Files)
    % Construisez le chemin complet du fichier
    fichier = fullfile(dossier, Files(i).name);

    % Lisez les données du fichier en ignorant les lignes vides
    fid = fopen(fichier, 'r');
    data = textscan(fid, '%s', 'Delimiter', '\n', 'Whitespace', '');
    fclose(fid);

    % Réécrivez le fichier avec les lignes vides supprimées
    fid = fopen(fichier, 'w');
    fprintf(fid, '%s\n', data{1}{~cellfun('isempty', data{1})});
    fclose(fid);
end