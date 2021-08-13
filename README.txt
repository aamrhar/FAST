To docuemt figures.
% ------------------ Report content --------------------------%
            obj.set_report_content(fig,figure_title,figure_description,repport_section_priority,
			Section_tag,parametre_type,parametre)
			
			ex.
            obj.set_report_content(fig, 'MM-SDAR modes total run times', ...
                fileread('data/fig_table_modes_time.txt'), 1, 'SDAR General', ...
                'table', tab);
% ------------------------------------------------------------%