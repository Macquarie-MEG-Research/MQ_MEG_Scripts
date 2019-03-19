    function [headshape_downsampled] = downsample_headshape_child(path_to_headshape,...
            varargin)
        
        % If not specified include the facial points
        if isempty(varargin)
            include_facial_points = 'yes';
            
        else
            include_facial_points = varargin{1};
        end
        
        
        % Get headshape
        headshape = ft_read_headshape(path_to_headshape);
        % Convert to cm
        headshape = ft_convert_units(headshape,'cm');
        % Save a version for later
        headshape_orig = headshape;
        
        % Get indices of facial points (up to 3cm above nasion)
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Is 3cm the correct distance?
        % Possibly different for child system?
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        count_facialpoints = find(headshape.pos(:,3)<3 & headshape.pos(:,1)>1);
        if isempty(count_facialpoints)
            disp('CANNOT FIND ANY FACIAL POINTS - COREG BY ICP MAY BE INACCURATE');
        else
            facialpoints = headshape.pos(count_facialpoints,:,:);
            rrr = 1:4:length(facialpoints);
            facialpoints = facialpoints(rrr,:); clear rrr;
        end
        
        % Remove facial points for now
        headshape.pos(count_facialpoints,:) = [];
        
        % Plot the facial and head points in separate colours
        figure;
        if isempty(count_facialpoints)
            disp('Not plotting any facial points')
        else
            ft_plot_mesh(facialpoints,'vertexcolor','r','vertexsize',10); hold on;
        end
        ft_plot_mesh(headshape.pos,'vertexcolor','k','vertexsize',10); hold on;
        view([90 0]);
        
        % Create mesh out of headshape downsampled to x points specified in the
        % function call
        cfg = [];
        %cfg.numvertices = 1000;
        cfg.method = 'headshape';
        cfg.headshape = headshape.pos;
        mesh = ft_prepare_mesh(cfg, headshape);
        
        %
        [decimated_headshape] = decimate_headshape(headshape, 'gridaverage');
        %[decimated_headshape] = decimate_headshape(headshape, 'nonuniform');
        
        
        % Create figure for quality checking
        figure; subplot(2,2,1);ft_plot_mesh(mesh,'facecolor','k',...
            'facealpha',0.1,'edgealpha',0); hold on;
        ft_plot_mesh(headshape_orig.pos,'vertexcolor','r','vertexsize',2); hold on;
        ft_plot_mesh(decimated_headshape,'vertexcolor','b','vertexsize',10); hold on;
        view(-180,0);
        subplot(2,2,2);ft_plot_mesh(mesh,'facecolor','k',...
            'facealpha',0.1,'edgealpha',0); hold on;
        ft_plot_mesh(headshape_orig.pos,'vertexcolor','r','vertexsize',2); hold on;
        ft_plot_mesh(decimated_headshape,'vertexcolor','b','vertexsize',10); hold on;
        view(0,0);
        subplot(2,2,3);ft_plot_mesh(mesh,'facecolor','k',...
            'facealpha',0.1,'edgealpha',0); hold on;
        ft_plot_mesh(headshape_orig.pos,'vertexcolor','r','vertexsize',2); hold on;
        ft_plot_mesh(decimated_headshape,'vertexcolor','b','vertexsize',10); hold on;
        view(90,0);
        subplot(2,2,4);ft_plot_mesh(mesh,'facecolor','k',...
            'facealpha',0.1,'edgealpha',0); hold on;
        ft_plot_mesh(headshape_orig.pos,'vertexcolor','r','vertexsize',2); hold on;
        ft_plot_mesh(decimated_headshape,'vertexcolor','b','vertexsize',10); hold on;
        view(-90,0);
        
        print('headshape_quality','-dpng');
        
        % Replace headshape.pos with decimated pos
        headshape.pos = decimated_headshape;
        
        % Only include points facial points 2cm below nasion
        %rrr  = find(facialpoints(:,3) > -2);
        
        
        % Add the facial points back in (default) or leave out if user specified
        % 'no' in function call
        if strcmp(include_facial_points,'yes')
            try
                % Add the facial info back in
                % Only include points facial points 2cm below nasion
                headshape.pos = vertcat(headshape.pos,...
                    facialpoints(find(facialpoints(:,3) > -2),:));
            catch
                disp('Cannot add facial info back into headshape');
            end
        else
            headshape.pos = headshape.pos;
            disp('Not adding facial points back into headshape');
        end
        
        %Add in names of the fiducials from the sensor
        headshape.fid.label = {'NASION','LPA','RPA'};
        
        % Plot for quality checking
        
        view_angle = [-180, 0]
        figure;
        
        for angle = 1:length(view_angle)
            
            subplot(1,2,angle)
            ft_plot_headshape(headshape,'vertexcolor','k','vertexsize',12) %plot headshape
            hold on;
            ft_plot_headshape(headshape_orig,'vertexcolor','r','vertexsize',2) %plot headshape
            view(view_angle(angle),10);
        end
        
        print('headshape_quality2','-dpng');
        
        
        % Export filename
        headshape_downsampled = headshape;
        
        function [decimated_headshape] = decimate_headshape(headshape, method)
            
            % Convert to a pointcloud in MATLAB
            headshape_pc = pointCloud(headshape.pos);
            
            switch method
                case 'gridaverage'
                    decimated_headshape = pcdownsample(headshape_pc,'gridAverage',3);
                    
                case 'nonuniform'
                    decimated_headshape = pcdownsample(headshape_pc,...
                        'nonuniformGridSample',20);
            end
            
            decimated_headshape = decimated_headshape.Location;
            
        end
        
        
    end