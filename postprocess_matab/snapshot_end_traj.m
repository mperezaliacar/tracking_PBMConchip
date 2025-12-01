clear; close all; clc;

% --- Parámetros del experimento ---
collagen_values = [2,4];
day_values = [0,1];
section_values = [1,2];

output_folder = 'figures';
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

% --- Loop principal ---
for ind_col = 1:length(collagen_values)
    collagen = collagen_values(ind_col);
    for ind_day = 1:length(day_values)
        day = day_values(ind_day);
        if day==0
                num_frames = 60;
            elseif day==1
                num_frames = 44;
            end
 for ind_section = 1:length(section_values)
            section = section_values(ind_section);

            % Ruta del CSV
            csv_path = sprintf(['C:/users/mpaliacar/OneDrive - unizar.es (1)/I3A/' ...
                'MPA_JAJ/1_DATA/GBM_IMMUNE/PBMC_videos/may2025/202505_%i/D%i/s%i/' ...
                'processed_frames/trayectorias_trackpy.csv'], ...
                collagen, day, section);

            if ~isfile(csv_path)
                fprintf('No se encuentra el archivo: %s\n', csv_path);
                continue;
            end

            img_path = sprintf('C:/users/mpaliacar/OneDrive - unizar.es (1)/I3A/MPA_JAJ/1_DATA/GBM_IMMUNE/PBMC_videos/may2025/202505_%i/D%i/s%i/processed_frames/recortada_frame%i.png', ...
                                        collagen, day, section, num_frames-1);

            if ~isfile(img_path)
                fprintf('No se encuentra la imagen final: %s\n', img_path);
                continue;
            end

            % Cargar datos
            tray = readtable(csv_path);
            particles = unique(tray.particle);

            % Cargar imagen
            I = imread(img_path);

            % Mostrar imagen
            figure('Position',[300 300 600 600]); 
            imshow(I, []); hold on;

            cmap = lines(length(particles)); % un color por trayectoria

            % --- Dibujar trayectorias encima de la imagen ---
            for p = 1:length(particles)
                data_p = tray(tray.particle == particles(p), :);
                data_p = sortrows(data_p, 'frame');

                xx = data_p.x;
                yy = data_p.y;

                if length(xx) < 2
                    continue;
                end

                % trayectoria
                plot(xx, yy, '-', 'Color', cmap(p,:), 'LineWidth', 1);

                % punto inicial
                plot(xx(1), yy(1), 'o', 'MarkerSize', 3, ...
                     'MarkerFaceColor', cmap(p,:), 'MarkerEdgeColor','k');

                % punto final
                plot(xx(end), yy(end), '^', 'MarkerSize', 4, ...
                     'MarkerFaceColor', cmap(p,:), 'MarkerEdgeColor','k');
            end

            % --- Guardar snapshot ---
            filename = sprintf('%s/traj_with_img_C%i_D%i_S%i.png', ...
                output_folder, collagen, day, section);
            saveas(gcf, filename);

            fprintf('Snapshot guardado: %s\n', filename);

            close;
        end
    end
end


