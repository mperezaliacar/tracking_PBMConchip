clear; close all; clc;

% --- Parámetros del experimento ---
collagen_values = [2,4];
day_values = [0,1];
section_values = [1,2];

results = table();  % tabla final por video

real_dt = 2; % min
% --- Loop principal ---
for ind_col = 1:length(collagen_values)
    collagen = collagen_values(ind_col);
    for ind_day = 1:length(day_values)
        day = day_values(ind_day);
        for ind_section = 1:length(section_values)
            section = section_values(ind_section);

            % Ruta del CSV
            path = sprintf(['C:/users/mpaliacar/OneDrive - unizar.es (1)/I3A/' ...
                'MPA_JAJ/1_DATA/GBM_IMMUNE/PBMC_videos/may2025/202505_%i/D%i/s%i/' ...
                'processed_frames/trayectorias_trackpy.csv'], ...
                collagen, day, section);

            if ~isfile(path)
                fprintf('No se encuentra el archivo: %s\n', path);
                continue;
            end

            tray = readtable(path);

            % Columnas necesarias
            if ~all(ismember({'x','y','frame','particle'}, tray.Properties.VariableNames))
                warning('Faltan columnas en %s', path);
                continue;
            end

            particles = unique(tray.particle);
            
            %% === GUARDAR TODAS LAS TRAYECTORIAS COMO UN .mat (estructura M) ===
            
            % Carpeta para guardar trayectorias
            output_folder = sprintf('results/trajectories_collagen%i_day%i_section%i', collagen, day, section);
            if ~exist(output_folder, 'dir')
                mkdir(output_folder);
            end
            
            % Inicializar celda M
            M = cell(length(particles), 1);
            
            for p = 1:length(particles)
                data_p = tray(tray.particle == particles(p), :);
                data_p = sortrows(data_p, 'frame');
            
                if height(data_p) < 1
                    continue;
                end
            
                % Crear matriz [t, x, y, z]
                mat = [ ...
                    data_p.frame * real_dt, ...   % tiempo en minutos
                    data_p.x, ...
                    data_p.y, ...
                    zeros(height(data_p),1) ...   % Z = 0 siempre
                ];
            
                % Guardar matriz en celda
                M{p} = mat;
          
            end
            
            % También guardar la celda completa M
            save(fullfile(output_folder, 'all_trajectories.mat'), 'M');
            
            fprintf('Trayectorias guardadas en: %s\n', output_folder);


            % --- MÉTRICAS POR VIDEO ---
            n_traj = length(particles);      
            traj_lengths = zeros(n_traj,1);  
            dist_totals = zeros(n_traj,1);   
            disp_x = zeros(n_traj,1);        
            vel_x = zeros(n_traj,1);         
            vel_mod = zeros(n_traj,1);       
            tortuosity = zeros(n_traj,1);    

            for p = 1:n_traj
                data_p = tray(tray.particle == particles(p), :);
                data_p = sortrows(data_p, 'frame');

                if height(data_p) < 2
                    continue;
                end

                dx = diff(data_p.x);
                dy = diff(data_p.y);
                dt = diff(data_p.frame)*real_dt;

                vmod = sqrt(dx.^2 + dy.^2) ./ dt;

                traj_lengths(p) = height(data_p);
                dist_totals(p)   = sum(vmod .* dt);
                disp_x(p)        = data_p.x(end) - data_p.x(1);
                vel_x(p)         = mean(dx ./ dt);
                vel_mod(p)       = mean(vmod);

                if disp_x(p) ~= 0
                    tortuosity(p) = dist_totals(p) / abs(disp_x(p));
                else
                    tortuosity(p) = NaN;
                end
            end

            % --- Guardar resumen por video (media y std) ---
            newrow = table(...
                collagen, day, section, ...
                n_traj, ...
                mean(traj_lengths), std(traj_lengths), ...
                mean(dist_totals), std(dist_totals), ...
                mean(disp_x), std(disp_x), ...
                mean(vel_x), std(vel_x), ...
                mean(vel_mod), std(vel_mod), ...
                nanmean(tortuosity), nanstd(tortuosity), ...
                'VariableNames', {'collagen','day','section', ...
                    'n_trajectories', ...
                    'mean_length','std_length', ...
                    'mean_dist_total','std_dist_total', ...
                    'mean_disp_x','std_disp_x', ...
                    'mean_vel_x','std_vel_x', ...
                    'mean_vel_mod','std_vel_mod', ...
                    'mean_tortuosity','std_tortuosity'} ...
            );

            results = [results; newrow];
        end
    end
end

disp(results);

% --- Exportar CSV ---
writetable(results, 'results/metrics_summary.csv');
fprintf('\nArchivo guardado: metrics_summary.csv\n');

% --- FIGURES con media ± std ---
fs = 11;
posX = 10; % posición de la esquina inferior izquierda de la imagen en X
posY = 10; % posición de la esquina inferior izquierda de la imagen en Y
width = 8; % ancho de la imagen
height = 8; % alto de la imagen
metrics = {'mean_length','mean_dist_total','mean_disp_x','mean_vel_x','mean_vel_mod','mean_tortuosity'};
std_metrics = {'std_length','std_dist_total','std_disp_x','std_vel_x','std_vel_mod','std_tortuosity'};
titles = {'Trajectory length (frames)','Total distance','Displacement $|x|$','Velocity $x$','Total velocity $v$','Tortuosity'};

colors = [0 0 1; 1 0.5 0]; % azul y naranja para dos colágenos
markers = {'o','s'};       % sección 1 = círculo, sección 2 = cuadrado

for m = 1:length(metrics)
    figure; hold on;
    set(gcf,'units','centimeters','outerposition',[posX,posY,width,height],'color','white');
    for c = 1:length(collagen_values)
        for s = 1:length(section_values)
            for d = day_values
                idx = results.collagen == collagen_values(c) & results.section == section_values(s) & results.day == d;
                if sum(idx)==0
                    continue
                end
                x = d;
                y = results.(metrics{m})(idx);
                e = results.(std_metrics{m})(idx);

                % plot con errorbar
                errorbar(x+(collagen_values(c)-3)/4+(section_values(s)-1.5)/4, y, e, 'LineStyle','none', ...
                    'Marker', markers{s}, 'MarkerSize',8, 'MarkerFaceColor', colors(c,:), ...
                    'MarkerEdgeColor','k', 'LineWidth',1, 'Color', 'black')
            end
        end
    end
    xline(0.5,'--r','LineWidth',1)
    xlim([-0.5 1.5])
    xticks([0 1])
    xticklabels({'Day 0','Day 1'})
    ax = gca;
    ax.FontSize = floor(fs);
    ax.TickLabelInterpreter = 'latex';
    %xlabel('Day','fontsize',fs,'interpreter','latex')
    ylabel(titles{m},'fontsize',fs,'interpreter','latex')
    % title(titles{m},'fontsize',fs,'interpreter','latex')
    grid on
    print(gcf,strcat('figures/',metrics{m}),'-dpng','-r300')
end

tit = 'Number of trajectories';
met = 'n_trajectories';

figure; hold on;
set(gcf,'units','centimeters','outerposition',[posX,posY,width,height],'color','white');
for c = 1:length(unique(results.collagen))
    for s = 1:length(unique(results.section))
        idx_0 = results.collagen == collagen_values(c) & results.section == section_values(s) & results.day == 0;
        x_0 = 0;
        y_0 = results.(met)(idx_0);

        idx_1 = results.collagen == collagen_values(c) & results.section == section_values(s) & results.day == 1;
        x_1 = 1;
        y_1 = results.(met)(idx_1);


        % dibujar punto
        plot(x_0, y_0, ...
            'Marker', markers{s}, 'MarkerSize',8, 'MarkerFaceColor', colors(c,:), ...
            'MarkerEdgeColor','k');
        plot(x_1, y_1, ...
            'Marker', markers{s}, 'MarkerSize',8, 'MarkerFaceColor', colors(c,:), ...
            'MarkerEdgeColor','k');
    end
end
xlim([-0.5 1.5])
xticks([0 1])
xticklabels({'Day 0','Day 1'})
ax = gca;
ax.FontSize = floor(fs);
ax.TickLabelInterpreter = 'latex';
%xlabel('Day','fontsize',fs,'interpreter','latex')
ylabel(tit,'fontsize',fs,'interpreter','latex')
% title(tit,'fontsize',fs,'interpreter','latex')
print(gcf,strcat('figures/',met),'-dpng','-r300')
