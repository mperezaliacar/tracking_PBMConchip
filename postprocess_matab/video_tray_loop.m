clear;
close all;
clc;

collagen_values = [2,4];
day_values = [0,1];
section_values = [1,2];

for ind_col=1:length(collagen_values)
    for ind_day=1:length(day_values)
        for ind_section=1:length(section_values)

            collagen = collagen_values(ind_col);
            day = day_values(ind_day);
            section = section_values(ind_section);
            path = sprintf('C:/users/mpaliacar/OneDrive - unizar.es (1)/I3A/MPA_JAJ/1_DATA/GBM_IMMUNE/PBMC_videos/may2025/202505_%i/D%i/s%i/processed_frames/trayectorias_trackpy.csv',collagen,day,section);
            
            trayectorias_matlab = readtable(path);
            
            if day==0
                num_frames = 60;
            elseif day==1
                num_frames = 44;
            end
            
            %% video 
            writerObj=VideoWriter(sprintf('figures/video_tray_collagen%i_day%i_s%i.mp4',collagen,day,section),'MPEG-4'); %cambiar nombre
            writerObj.FrameRate=5; % modificar para que vaya mas rapido o despacio
            open(writerObj);
            
            
            for kk=1:num_frames
                frame_idx = kk-1;
            
                t_current = trayectorias_matlab(trayectorias_matlab.frame <= frame_idx, :);
            
                fig = figure(1); 
                clf(fig);  % limpia la figura completamente
                set(fig, 'Color', 'white', 'Visible', 'off');  % evitar parpadeos y errores de render
                
                framefig_name = sprintf('C:/users/mpaliacar/OneDrive - unizar.es (1)/I3A/MPA_JAJ/1_DATA/GBM_IMMUNE/PBMC_videos/may2025/202505_%i/D%i/s%i/processed_frames/recortada_frame%i.png', ...
                                        collagen, day, section, frame_idx);
                
                IMG = imread(framefig_name);
                
                % Mostrar la imagen sin usar las funciones internas problemáticas
                image(IMG);
                axis image off;
                hold on;
            
                % Iterar sobre las partículas únicas presentes hasta este frame
                particulas_unicas = unique(t_current.particle);
                
                for p_id = 1:length(particulas_unicas)
                    particle_id = particulas_unicas(p_id);
                    
                    % Filtra los datos para la partícula específica
                    traj_particula = t_current(t_current.particle == particle_id, :);
                    
                    % Dibuja la línea de la trayectoria (path)
                    % 'x' e 'y' son las coordenadas de trackpy
                    plot(traj_particula.x, traj_particula.y, 'Color', [0 0.447 0.741], 'LineWidth', 1.5); % Línea azul
                    
                    % Dibuja el punto de la célula en el frame actual (la "cabeza" de la trayectoria)
                    % Obtenemos las últimas coordenadas (el punto en el frame actual)
                    if ~isempty(traj_particula)
                        last_x = traj_particula.x(end);
                        last_y = traj_particula.y(end);
                        
                        % Dibuja un círculo amarillo en la posición actual de la célula
                        plot(last_x, last_y, 'o', 'MarkerFaceColor', 'y', 'MarkerEdgeColor', 'k', 'MarkerSize', 5); 
                    end
                end
                
                hold off;
                
                title(sprintf('Trayectorias de Células - Frame %i', frame_idx));
            
                print(gcf,'-djpeg',sprintf('imagenita time=%i .jpeg',kk));
                tete=imread(sprintf('imagenita time=%i .jpeg',kk));
                Mov(kk)=im2frame(tete);
                writeVideo(writerObj,Mov(kk));
                delete(sprintf('imagenita time=%i .jpeg',kk));
                close(gcf);
            end
            close(writerObj);

        end
    end
end